from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from deep_translator import GoogleTranslator
from core.supabase_client import get_supabase_client
from datetime import datetime
import logging

router = APIRouter(prefix="/broadcast", tags=["Broadcast"])

class BroadcastRequest(BaseModel):
    message: str
    target_languages: list[str] # e.g., ['es', 'fr', 'de']
    sender_id: str

@router.post("/")
async def send_broadcast(request: BroadcastRequest):
    """
    Sends an emergency broadcast and translates it into desired languages using deep-translator.
    """
    try:
        supabase = get_supabase_client()
        translations = {}
        
        # Translate the message safely
        for lang in request.target_languages:
            try:
                translated = GoogleTranslator(source='auto', target=lang).translate(request.message)
                translations[lang] = translated
            except Exception as tr_err:
                logging.error(f"Translation failed for {lang} - {tr_err}")
                translations[lang] = request.message # Fallback to original
            
        # Log to Supabase
        supabase.table("broadcasts").insert({
            "sender_id": request.sender_id,
            "original_message": request.message,
            "translations": translations,
            "created_at": datetime.now().isoformat()
        }).execute()
        
        return {
            "status": "success",
            "message": "Broadcast sent and translated.",
            "original": request.message,
            "translations": translations
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
