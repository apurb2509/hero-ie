from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from collections import deque
from core.supabase_client import get_supabase_client

router = APIRouter(prefix="/evacuation", tags=["Evacuation"])

class EvacuationRouteRequest(BaseModel):
    user_location: str
    destination: str

class EvacuationRouteResponse(BaseModel):
    path: List[str]
    status: str

# Simple map of the facility (Node adjacency list)
BUILDING_GRAPH = {
    "Room 204": ["Corridor A"],
    "Corridor A": ["Room 204", "Stairs 1", "Lobby"],
    "Stairs 1": ["Corridor A", "Ground Floor"],
    "Ground Floor": ["Stairs 1", "Main Exit"],
    "Lobby": ["Corridor A", "Main Exit"],
    "Main Exit": ["Ground Floor", "Lobby"]
}

def bfs_shortest_path(graph, start, goal):
    if start not in graph or goal not in graph:
        return []
    explored = set()
    queue = deque([[start]])
    
    if start == goal:
        return [start]
        
    while queue:
        path = queue.popleft()
        node = path[-1]
        
        if node not in explored:
            neighbours = graph[node]
            for neighbour in neighbours:
                new_path = list(path)
                new_path.append(neighbour)
                queue.append(new_path)
                
                if neighbour == goal:
                    return new_path
            explored.add(node)
    return []

@router.post("/route", response_model=EvacuationRouteResponse)
async def get_safe_path(request: EvacuationRouteRequest):
    """
    Calculates a dynamic "Safe-Path" based on the user's current location to a destination.
    Uses AI routing first, falls back to static BFS.
    """
    try:
        supabase = get_supabase_client()
        
        # 1. Fetch Active Layout Description from DB
        layout_res = supabase.table("facility_layouts").select("description").order("uploaded_at", desc=True).limit(1).execute()
        map_description = "A standard 2-floor hotel layout."
        if layout_res.data:
            map_description = layout_res.data[0]['description']
            
        # 2. Fetch Active Hazards (YELLOW/RED) from recent frames
        # For MVP, we pass an empty list if no active hazards are tracked globally yet.
        active_incidents = [{"location": "Unknown", "level": "None"}]
        
        # 3. Request AI Route
        from .ai_routing import calculate_ai_route
        ai_response = calculate_ai_route(request.user_location, request.destination, map_description, active_incidents)
        
        if ai_response and "path" in ai_response:
            calculated_path = ai_response["path"]
            status = "ai_success"
        else:
            # Fallback to BFS
            calculated_path = bfs_shortest_path(BUILDING_GRAPH, request.user_location, request.destination)
            if not calculated_path:
                calculated_path = [request.user_location, "Unknown Route", request.destination]
                status = "fallback_unknown"
            else:
                status = "fallback_static"
        
        # 4. Log to Supabase table
        supabase.table("evacuations").insert({
            "user_location": request.user_location,
            "destination": request.destination,
            "path_provided": calculated_path,
            "status": status
        }).execute()
        
        return EvacuationRouteResponse(path=calculated_path, status=status)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
