import json
from core.config import settings
from groq import Groq

client = Groq(api_key=settings.GROQ_API_KEY)

def calculate_ai_route(user_location: str, destination: str, map_description: str, active_incidents: list) -> dict:
    """
    Uses the Groq API to determine the safest route based on the facility layout and current threats.
    """
    try:
        prompt = f"""
        You are an elite emergency response AI. Calculate the SAFEST evacuation route.
        
        Facility Layout Definition:
        {map_description}
        
        Active Threats/Incidents:
        {json.dumps(active_incidents)}
        
        Given the above layout and active threats, determine the safest continuous path from the User Location to the Destination. 
        You MUST avoid any areas listed as having YELLOW or RED incidents.
        
        User Location: {user_location}
        Destination: {destination}
        
        Output valid JSON exactly matching this format. Do not include markdown:
        {{
            "path": ["node1", "node2", "node3"],
            "reason": "Brief safety justification"
        }}
        """

        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a crisis routing AI. Always return JSON."
                },
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            temperature=0.1,
            max_tokens=500
        )
        
        response_text = chat_completion.choices[0].message.content
        # attempt to strip markdown if any
        if response_text.startswith("```json"):
            response_text = response_text[7:-3]
            
        return json.loads(response_text.strip())
        
    except Exception as e:
        print(f"Groq Routing Failed: {e}")
        return None
