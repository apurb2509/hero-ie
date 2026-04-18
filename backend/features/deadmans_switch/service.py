import asyncio
from datetime import datetime, timezone, timedelta
from core.supabase_client import get_supabase_client
from core.config import settings

class DeadMansSwitchService:
    def __init__(self):
        self.supabase = get_supabase_client()
        self.timeout_seconds = 15

    async def initiate_switch(self, frame_id: str, classification: str):
        """
        Starts the countdown for a RED/YELLOW alert using Supabase.
        """
        expires_at = datetime.now(timezone.utc) + timedelta(seconds=self.timeout_seconds)
        
        switch_data = {
            "frame_id": frame_id,
            "classification": classification,
            "status": "PENDING",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": expires_at.isoformat()
        }
        
        # Insert into Supabase 'switches' table
        try:
            self.supabase.table("switches").insert(switch_data).execute()
            print(f"[SWITCH] Emergency switch initialized for {frame_id}")
        except Exception as e:
            print(f"[SWITCH] ❌ Failed to initialize switch in Supabase: {e}")
            # Even if DB fails, we should still trigger the backup timer for safety
        
        # Start a background task to wait and verify
        asyncio.create_task(self._wait_and_trigger(frame_id))

    async def acknowledge_switch(self, frame_id: str, moderator_id: str):
        """
        Moderator acknowledges the alert, stopping the automated escalation.
        """
        try:
            self.supabase.table("switches") \
                .update({
                    "status": "ACKNOWLEDGED",
                    "moderator_id": moderator_id,
                    "acknowledged_at": datetime.now(timezone.utc).isoformat()
                }) \
                .eq("frame_id", frame_id) \
                .execute()
            print(f"[SWITCH] Alert {frame_id} Acknowledged by {moderator_id}")
        except Exception as e:
            print(f"[SWITCH] ❌ Acknowledgment failed: {e}")

    async def _wait_and_trigger(self, frame_id: str):
        """
        Wait for timeout and trigger alarm if still pending.
        """
        await asyncio.sleep(self.timeout_seconds)
        
        try:
            # Query the switch status
            response = self.supabase.table("switches") \
                .select("*") \
                .eq("frame_id", frame_id) \
                .execute()
            
            if not response.data:
                return

            data = response.data[0]
            if data.get("status") == "PENDING":
                # Trigger the Automated Outreach logic
                self._trigger_automated_outreach(data)
                
                # Update status
                self.supabase.table("switches") \
                    .update({
                        "status": "TRIGGERED",
                        "triggered_at": datetime.now(timezone.utc).isoformat() # We can add this col in DB
                    }) \
                    .eq("frame_id", frame_id) \
                    .execute()
        except Exception as e:
            print(f"[SWITCH] ❌ Error in trigger background task: {e}")

    def _trigger_automated_outreach(self, switch_data: dict):
        """
        Logic for calling police, fire stations, etc.
        """
        print(f"\n[🚨 ALARM 🚨] !!! AUTOMATED EMERGENCY PROTOCOL TRIGGERED !!!")
        print(f"[🚨 ALARM 🚨] Classification: {switch_data['classification']}")
        print(f"[🚨 ALARM 🚨] Frame Reference: {switch_data['frame_id']}")
        print(f"[🚨 ALARM 🚨] Initiating emergency broadcast...")
        # In a real scenario, this is where SMS/Call APIs would be triggered.
