from fastapi import APIRouter, UploadFile, File, HTTPException, Form, Body
from .service import RiskDetectionService
from .storage import StorageService
from features.deadmans_switch.service import DeadMansSwitchService
import json

import cv2
import numpy as np

router = APIRouter(prefix="/risk", tags=["Risk Detection"])

@router.post("/sim/setup")
async def setup_simulation(file: UploadFile = File(...)):
    """
    Step 1: Upload the big video once and store it.
    Returns a simulation_id.
    """
    import uuid
    import os
    sim_id = str(uuid.uuid4())
    os.makedirs("data/simulations", exist_ok=True)
    file_path = f"data/simulations/{sim_id}.mp4"
    
    print(f"[SIM SETUP] Saving video for simulation {sim_id}...")
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)
    
    print(f"[SIM SETUP] ✅ Video stored at {file_path}")
    return {"simulation_id": sim_id}

@router.post("/sim/frame")
async def process_simulation_frame(simulation_id: str = Form(...), offset_seconds: int = Form(...)):
    """
    Step 2: Lightweight polling. Extracts a frame from the stored video
    at the given offset and analyzes it.
    """
    from .service import RiskDetectionService
    from .storage import StorageService
    from features.deadmans_switch.service import DeadMansSwitchService
    import os
    import cv2
    import json

    risk_service = RiskDetectionService()
    storage_service = StorageService()
    switch_service = DeadMansSwitchService()

    video_path = f"data/simulations/{simulation_id}.mp4"
    if not os.path.exists(video_path):
        raise HTTPException(status_code=404, detail="Simulation video not found.")

    print(f"[SIM FRAME] Extracting frame at {offset_seconds}s from {simulation_id}...")
    cap = cv2.VideoCapture(video_path)
    cap.set(cv2.CAP_PROP_POS_MSEC, offset_seconds * 1000)
    success, frame = cap.read()
    cap.release()

    if not success:
        # If we hit the end of the video, loop back to start
        print("[SIM FRAME] End of video reached or extraction failed. Re-trying from 0s...")
        cap = cv2.VideoCapture(video_path)
        cap.set(cv2.CAP_PROP_POS_MSEC, 0)
        success, frame = cap.read()
        cap.release()

    if not success:
        raise HTTPException(status_code=500, detail="Failed to extract frame from simulation video.")

    _, encoded_image = cv2.imencode('.jpg', frame)
    image_bytes = encoded_image.tobytes()

    # Reuse the same analysis pipeline as the direct ingest
    try:
        print(f"[SIM FRAME] Analyzing frame for simulation {simulation_id}...")
        analysis_raw = risk_service.analyze_frame(image_bytes)
        analysis = json.loads(analysis_raw)
        
        classification = analysis.get("classification", "GREEN").upper()
        print(f"[SIM FRAME] 🧠 RESULT: {classification}")
        
        file_path = storage_service.upload_frame(
            image_bytes, 
            classification, 
            metadata={"reason": analysis.get("reason"), "confidence": analysis.get("confidence"), "sim_id": simulation_id}
        )

        if classification in ["YELLOW", "RED"]:
            frame_id = file_path.split("/")[-1].replace(".jpg", "")
            await switch_service.initiate_switch(frame_id, classification)

        return {
            "status": "success",
            "classification": classification,
            "path": file_path,
            "details": analysis
        }
    except Exception as e:
        print(f"[SIM FRAME] ❌ Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/ingest")
async def ingest_file(file: UploadFile = File(...)):
    # Lazy service instantiation inside the route handler
    from .service import RiskDetectionService
    from .storage import StorageService
    from features.deadmans_switch.service import DeadMansSwitchService
    import uuid
    import os
    
    risk_service = RiskDetectionService()
    storage_service = StorageService()
    switch_service = DeadMansSwitchService()
    
    print(f"\n[RISK INGEST] >>> Incoming Request Received <<<")
    print(f"[RISK INGEST] Filename: {file.filename}")
    print(f"[RISK INGEST] Header Content-Type: {file.content_type}")
    
    # Lenient type detection: Check extension if content-type is generic
    content_type = file.content_type
    if content_type == "application/octet-stream" and file.filename:
        ext = file.filename.split('.')[-1].lower()
        if ext in ['mp4', 'mkv', 'mov', 'avi']:
            content_type = f"video/{ext}"
        elif ext in ['jpg', 'jpeg', 'png']:
            content_type = f"image/{ext}"
    
    print(f"[RISK INGEST] Resolved Content-Type: {content_type}")

    image_bytes = None

    if content_type.startswith("video/"):
        print("[RISK INGEST] Starting Video Processing Pipeline...")
        video_bytes = await file.read()
        temp_filename = f"temp_{uuid.uuid4()}.mp4"
        try:
            with open(temp_filename, "wb") as f:
                f.write(video_bytes)
            print(f"[RISK INGEST] Video written to disk: {temp_filename} ({len(video_bytes)} bytes)")
                
            cap = cv2.VideoCapture(temp_filename)
            # Extract frame at 1-second mark
            cap.set(cv2.CAP_PROP_POS_MSEC, 1000)
            success, frame = cap.read()
            cap.release()
            
            # Cleanup temp file safely (Windows can be slow to release handles)
            try:
                if os.path.exists(temp_filename):
                    os.remove(temp_filename)
                    print(f"[RISK INGEST] Temp file {temp_filename} removed.")
            except Exception as e:
                print(f"[RISK INGEST] Warning: Could not remove temp file {temp_filename}: {e}")
            
            if not success:
                print("[RISK INGEST] ❌ ERROR: OpenCV failed to extract frame.")
                raise HTTPException(status_code=400, detail="Could not extract frame from video.")
                
            _, encoded_image = cv2.imencode('.jpg', frame)
            image_bytes = encoded_image.tobytes()
            print(f"[RISK INGEST] ✅ Frame extracted. Size: {len(image_bytes)} bytes")
        except HTTPException:
            raise
        except Exception as e:
            # Safe cleanup attempt in case of error
            try:
                if os.path.exists(temp_filename): os.remove(temp_filename)
            except: pass
            print(f"[RISK INGEST] ❌ VIDEO PROCESSING FAILED: {e}")
            raise HTTPException(status_code=500, detail=f"Internal Video Processing Error: {e}")
            
    elif content_type.startswith("image/"):
        print("[RISK INGEST] Starting Direct Image Pipeline...")
        image_bytes = await file.read()
        print(f"[RISK INGEST] ✅ Image received. Size: {len(image_bytes)} bytes")
    else:
        print(f"[RISK INGEST] ❌ UNSUPPORTED TYPE: {content_type}")
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {content_type}. Please upload image or video.")

    try:
        print("[RISK INGEST] Calling Groq Vision AI for analysis...")
        # 1. Analyze with Groq
        analysis_raw = risk_service.analyze_frame(image_bytes)
        analysis = json.loads(analysis_raw)
        
        classification = analysis.get("classification", "GREEN").upper()
        print(f"[RISK INGEST] 🧠 AI ANALYSIS RESULT: {classification}")
        print(f"[RISK INGEST] 📝 REASONING: {analysis.get('reason')}")
        
        # 2. Store in Supabase + Metadata in Supabase Table
        print(f"[RISK INGEST] Persisting to storage (Bucket: {storage_service.bucket})...")
        file_path = storage_service.upload_frame(
            image_bytes, 
            classification, 
            metadata={"reason": analysis.get("reason"), "confidence": analysis.get("confidence")}
        )
        print(f"[RISK INGEST] ✅ Successfully stored at: {file_path}")

        # 3. Handle Alerts (Yellow/Red)
        if classification in ["YELLOW", "RED"]:
            print(f"[RISK INGEST] ⚠️ TRIGGERING EMERGENCY PROTOCOL for {classification}")
            frame_id = file_path.split("/")[-1].replace(".jpg", "")
            await switch_service.initiate_switch(frame_id, classification)

        return {
            "status": "success",
            "classification": classification,
            "path": file_path,
            "details": analysis
        }

    except Exception as e:
        print(f"[RISK INGEST] ❌ PIPELINE CRITICAL ERROR: {e}")
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")
