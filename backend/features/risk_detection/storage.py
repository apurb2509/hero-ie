import io
from datetime import datetime, timezone
from core.supabase_client import get_supabase_client
from core.config import settings

class StorageService:
    def __init__(self):
        self.supabase = get_supabase_client()
        self.bucket = settings.SUPABASE_STORAGE_BUCKET
        self.green_limit = 5000

    def upload_frame(self, image_bytes: bytes, classification: str, metadata: dict):
        """
        Uploads a frame to Supabase and manages FIFO if it's GREEN.
        """
        # Ensure UTC timezone
        timestamp = datetime.now(timezone.utc).isoformat()
        file_name = f"{classification.lower()}/{timestamp}.jpg"
        
        print(f"[STORAGE] Uploading {len(image_bytes)} bytes to bucket '{self.bucket}' as '{file_name}'...")
        # 1. Upload file to Supabase Storage
        try:
            self.supabase.storage.from_(self.bucket).upload(
                path=file_name,
                file=image_bytes,
                file_options={"content-type": "image/jpeg"}
            )
            print(f"[STORAGE] ✅ Supabase storage upload successful.")
        except Exception as e:
            print(f"[STORAGE] ❌ Supabase storage upload FAILED: {e}")
            raise e

        # 2. Store metadata in Supabase Table (Replaces Firestore)
        print(f"[STORAGE] Storing metadata in Supabase 'frames' table...")
        frame_data = {
            "path": file_name,
            "classification": classification,
            "timestamp": timestamp,
            "reason": metadata.get("reason"),
            "confidence": metadata.get("confidence")
        }
        try:
            self.supabase.table("frames").insert(frame_data).execute()
            print(f"[STORAGE] ✅ Supabase metadata stored.")
        except Exception as e:
            print(f"[STORAGE] ❌ Supabase metadata storage FAILED: {e}")
            # Non-critical, but logging it
        
        # 3. FIFO logic for GREEN images
        if classification == "GREEN":
            print(f"[STORAGE] Running FIFO cleanup for GREEN bucket...")
            self._handle_green_fifo()

        return file_name

    def _handle_green_fifo(self):
        """
        Maintains the 5,000 limit for GREEN images in Supabase.
        """
        try:
            # Query count of green images
            count_resp = self.supabase.table("frames") \
                .select("id", count="exact") \
                .eq("classification", "GREEN") \
                .execute()
            
            count = count_resp.count or 0

            if count > self.green_limit:
                to_delete_count = count - self.green_limit
                print(f"[STORAGE] FIFO: Deleting {to_delete_count} oldest GREEN frames...")

                # Get the oldest N records
                old_frames_resp = self.supabase.table("frames") \
                    .select("id, path") \
                    .eq("classification", "GREEN") \
                    .order("timestamp", desc=False) \
                    .limit(to_delete_count) \
                    .execute()
                
                old_frames = old_frames_resp.data
                if not old_frames:
                    return

                ids_to_delete = [f["id"] for f in old_frames]
                paths_to_delete = [f["path"] for f in old_frames]

                # Delete from DB
                self.supabase.table("frames").delete().in_("id", ids_to_delete).execute()
                
                # Delete from Storage
                if paths_to_delete:
                    self.supabase.storage.from_(self.bucket).remove(paths_to_delete)
                
                print(f"[STORAGE] ✅ FIFO cleanup complete.")
        except Exception as e:
            print(f"[STORAGE] ⚠️ FIFO cleanup encountered an error: {e}")
