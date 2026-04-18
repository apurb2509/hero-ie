from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from core.supabase_client import get_supabase_client
from datetime import datetime, timedelta

router = APIRouter(prefix="/heatmap", tags=["Heatmap"])

class VitalsReport(BaseModel):
    user_id: str
    location: str
    heart_rate: int
    status: str # "Ok", "Distress"

class HeatmapResponse(BaseModel):
    zones: List[Dict[str, Any]]

@router.post("/vitals")
async def report_vitals(report: VitalsReport):
    """
    Log a vital sign report from the mesh network.
    """
    try:
        supabase = get_supabase_client()
        supabase.table("vitals").insert({
            "user_id": report.user_id,
            "location": report.location,
            "heart_rate": report.heart_rate,
            "status": report.status,
            "reported_at": datetime.now().isoformat()
        }).execute()
        return {"message": "Vitals logged successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=HeatmapResponse)
async def get_heatmap():
    """
    Retrieves the clustered heatmap of users based on recent vitals reports.
    """
    try:
        supabase = get_supabase_client()
        # Query distinct vitals from last 10 minutes to form real live zones.
        time_threshold = (datetime.now() - timedelta(minutes=10)).isoformat()
        response = supabase.table("vitals").select("location, user_id").gt("reported_at", time_threshold).execute()
        
        # Deduplicate to get the latest per user if possible, or just raw count.
        # Simple count per location
        location_counts = {}
        for record in response.data:
            loc = record["location"]
            location_counts[loc] = location_counts.get(loc, 0) + 1
            
        zones = [{"name": loc, "count": count} for loc, count in location_counts.items()]
        
        # If no data, return a default empty state rather than simulated
        if not zones:
            zones = [{"name": "No active zones", "count": 0}]
            
        return HeatmapResponse(zones=zones)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
