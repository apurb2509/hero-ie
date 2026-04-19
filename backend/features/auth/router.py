import random
import time
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Optional
from twilio.rest import Client
from core.config import settings
from core.supabase_client import get_supabase_client

router = APIRouter(prefix="/auth", tags=["Authentication"])

# In-memory storage for OTPs
# Format: {phone_number: {"otp": str, "expiry": float}}
otp_store: Dict[str, Dict] = {}

class OTPRequest(BaseModel):
    phone_number: str

class OTPVerify(BaseModel):
    phone_number: str
    otp: str
    user_id: Optional[str] = None # Optional for Phone-only auth
    role: Optional[str] = "guest"
    full_name: Optional[str] = None # Optional name for profile creation
    password: Optional[str] = None # Optional password

@router.post("/send-otp")
async def send_otp(request: OTPRequest):
    # Safety Check: If Twilio is not configured, use a fixed OTP for dev
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        otp = "123456"
        otp_store[request.phone_number] = {
            "otp": otp,
            "expiry": time.time() + 600 # 10 mins
        }
        return {
            "message": "Development Mode: OTP 123456 generated.", 
            "phone": request.phone_number,
            "dev_mode": True
        }

    try:
        otp = str(random.randint(100000, 999999))
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        
        message = client.messages.create(
            body=f"Hello, your HERO-IE verification code is: {otp}",
            from_=settings.TWILIO_PHONE_NUMBER,
            to=request.phone_number
        )
        
        otp_store[request.phone_number] = {
            "otp": otp,
            "expiry": time.time() + 600 # 10 mins
        }
        
        return {"message": "OTP sent successfully", "sid": message.sid}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send OTP: {str(e)}")

@router.post("/verify-otp")
async def verify_otp(request: OTPVerify):
    stored_data = otp_store.get(request.phone_number)
    
    if not stored_data:
        raise HTTPException(status_code=400, detail="No OTP found for this phone number")
    
    if time.time() > stored_data["expiry"]:
        if request.phone_number in otp_store:
            del otp_store[request.phone_number]
        raise HTTPException(status_code=400, detail="OTP has expired")
    
    if stored_data["otp"] != request.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    
    # OTP is valid, update Supabase user record
    try:
        supabase = get_supabase_client()
        
        # Check if user already exists in public.users to avoid duplicates
        existing = []
        if request.user_id:
            existing = supabase.table("users").select("*").eq("user_id", request.user_id).execute().data
        elif request.phone_number:
            existing = supabase.table("users").select("*").eq("phone_number", request.phone_number).execute().data

        user_data = {
            "phone_number": request.phone_number,
            "is_phone_verified": True,
            "role": request.role,
        }
        
        if request.user_id:
            user_data["user_id"] = request.user_id
        if request.full_name:
            user_data["full_name"] = request.full_name
        if request.password:
            # Note: In a real production app, Hash this password!
            user_data["password_hash"] = request.password

        if existing:
            # Update
            response = supabase.table("users").update(user_data).eq("id", existing[0]["id"]).execute()
        else:
            # Create new
            response = supabase.table("users").insert(user_data).execute()
        
        # Clean up OTP
        if request.phone_number in otp_store:
            del otp_store[request.phone_number]
        
        return {"message": "Verification successful", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database sync failed: {str(e)}")
