import random
import time
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Optional
from twilio.rest import Client
from core.config import settings
from core.supabase_client import get_supabase_client

import smtplib
from email.message import EmailMessage

router = APIRouter(prefix="/auth", tags=["Authentication"])

# In-memory storage for OTPs
# Format: {identifier: {"otp": str, "expiry": float}}
otp_store: Dict[str, Dict] = {}

class OTPRequest(BaseModel):
    phone_number: Optional[str] = None
    email: Optional[str] = None

class OTPVerify(BaseModel):
    phone_number: Optional[str] = None
    email: Optional[str] = None
    otp: str
    user_id: Optional[str] = None # Optional for Phone-only auth
    role: Optional[str] = "guest"
    full_name: Optional[str] = None # Optional name for profile creation
    password: Optional[str] = None # Optional password

class LoginRequest(BaseModel):
    identifier: str # Email or Phone
    password: str

@router.post("/send-otp")
async def send_otp(request: OTPRequest):
    identifier = request.phone_number or request.email
    if not identifier:
        raise HTTPException(status_code=400, detail="Phone number or email required")

    otp = str(random.randint(100000, 999999))
    otp_store[identifier] = {
        "otp": otp,
        "expiry": time.time() + 600 # 10 mins
    }

    # --- SMS PATH ---
    if request.phone_number:
        if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
            return {
                "message": "Development Mode: SMS OTP 123456 generated.", 
                "dev_mode": True,
                "otp": "123456" # Hardcoded for dev convenience
            }

        try:
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            message = client.messages.create(
                body=f"Hello, your HERO-IE verification code is: {otp}",
                from_=settings.TWILIO_PHONE_NUMBER,
                to=request.phone_number
            )
            return {"message": "SMS OTP sent successfully", "sid": message.sid}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to send SMS OTP: {str(e)}")

    # --- EMAIL PATH ---
    elif request.email:
        if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
             return {
                "message": "Development Mode: Email OTP 123456 generated.", 
                "dev_mode": True,
                "otp": "123456"
            }

        try:
            msg = EmailMessage()
            msg.set_content(f"Hello, your HERO-IE verification code is: {otp}")
            msg["Subject"] = "HERO-IE Verification Code"
            msg["From"] = settings.SMTP_USER
            msg["To"] = request.email

            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                server.starttls()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.send_message(msg)
            
            return {"message": "Email OTP sent successfully"}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to send Email OTP: {str(e)}")

@router.post("/verify-otp")
async def verify_otp(request: OTPVerify):
    identifier = request.phone_number or request.email
    stored_data = otp_store.get(identifier)
    
    if not stored_data:
        raise HTTPException(status_code=400, detail="No OTP found for this user")
    
    if time.time() > stored_data["expiry"]:
        if identifier in otp_store:
            del otp_store[identifier]
        raise HTTPException(status_code=400, detail="OTP has expired")
    
    if stored_data["otp"] != request.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    
    # OTP is valid, sync with Supabase
    try:
        supabase = get_supabase_client()
        
        # Check if user already exists
        existing = []
        if request.user_id:
            existing = supabase.table("users").select("*").eq("user_id", request.user_id).execute().data
        elif request.phone_number:
            existing = supabase.table("users").select("*").eq("phone_number", request.phone_number).execute().data
        elif request.email:
             existing = supabase.table("users").select("*").eq("email", request.email).execute().data

        user_data = {
            "role": request.role,
        }
        if request.phone_number:
            user_data["phone_number"] = request.phone_number
            user_data["is_phone_verified"] = True
        if request.email:
            user_data["email"] = request.email
            user_data["is_email_verified"] = True
        if request.user_id:
            user_data["user_id"] = request.user_id
        if request.full_name:
            user_data["full_name"] = request.full_name
        if request.password:
            # Note: Implement proper hashing for production!
            user_data["password_hash"] = request.password

        if existing:
            response = supabase.table("users").update(user_data).eq("id", existing[0]["id"]).execute()
        else:
            response = supabase.table("users").insert(user_data).execute()
        
        if identifier in otp_store:
            del otp_store[identifier]
        
        return {"message": "Verification successful", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database sync failed: {str(e)}")

@router.post("/login")
async def login(request: LoginRequest):
    try:
        supabase = get_supabase_client()
        
        # Search by email or phone
        query = supabase.table("users").select("*").or_(f"email.eq.{request.identifier},phone_number.eq.{request.identifier}")
        result = query.execute().data
        
        if not result:
            raise HTTPException(status_code=404, detail="User not found")
        
        user = result[0]
        
        # Verify Password (Note: Use hashing in production)
        if user.get("password_hash") != request.password:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        return {
            "message": "Login successful",
            "user_id": user.get("user_id"),
            "full_name": user.get("full_name"),
            "role": user.get("role")
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")
