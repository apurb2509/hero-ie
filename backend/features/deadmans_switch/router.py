from fastapi import APIRouter, HTTPException, Body
from .service import DeadMansSwitchService

router = APIRouter(prefix="/switch", tags=["Dead-Man's Switch"])

@router.post("/{frame_id}/acknowledge")
async def acknowledge_alert(frame_id: str, moderator_id: str = Body(..., embed=True)):
    """
    Called by the web dashboard when a moderator clicks 'Verify' or 'Acknowledge'.
    """
    from .service import DeadMansSwitchService
    switch_service = DeadMansSwitchService()
    try:
        await switch_service.acknowledge_switch(frame_id, moderator_id)
        return {"status": "success", "message": "Alert acknowledged"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{frame_id}")
async def get_switch_status(frame_id: str):
    """
    Check the status of a specific switch in Supabase.
    """
    from .service import DeadMansSwitchService
    switch_service = DeadMansSwitchService()
    try:
        response = switch_service.supabase.table("switches") \
            .select("*") \
            .eq("frame_id", frame_id) \
            .execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Switch record not found")
        
        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
