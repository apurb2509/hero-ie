from fastapi import APIRouter, Form, UploadFile, File, HTTPException
from core.supabase_client import get_supabase_client
from features.risk_detection.storage import StorageService

router = APIRouter(prefix="/admin", tags=["Admin Configuration"])

@router.post("/layout")
async def upload_facility_layout(
    name: str = Form(...),
    description: str = Form(...),
    file: UploadFile = File(...)
):
    """
    Endpoint for admins to upload the current floor plan or layout description.
    """
    from features.risk_detection.storage import StorageService
    storage = StorageService()
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Layout file must be an image.")

    try:
        supabase = get_supabase_client()
        image_bytes = await file.read()
        
        # Upload using the same storage service as risk frames
        file_path = storage.upload_frame(image_bytes, "LAYOUT", {"type": "facility_map"})
        
        db_res = supabase.table("facility_layouts").insert({
            "name": name,
            "description": description,
            "image_url": file_path
        }).execute()
        
        return {"status": "success", "message": "Layout uploaded successfully.", "data": db_res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
