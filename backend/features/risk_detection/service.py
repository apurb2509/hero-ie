import os
import base64
from groq import Groq
from core.config import settings

class RiskDetectionService:
    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = "meta-llama/llama-4-scout-17b-16e-instruct"

    def analyze_frame(self, image_bytes: bytes):
        """
        Analyzes a frame using Groq Vision and returns a classification (Green, Yellow, Red).
        """
        base64_image = base64.b64encode(image_bytes).decode('utf-8')
        
        prompt = """
        Analyze this image from a hospitality venue CCTV. 
        Classify it into one of these categories:
        - GREEN: Normal activity, no threat.
        - YELLOW: Potential risk (suspicious behavior, smoke, minor overcrowding).
        - RED: Immediate danger (fire, weapons, structural failure).
        
        Provide your response in JSON format:
        {
            "classification": "GREEN" | "YELLOW" | "RED",
            "reason": "Brief explanation",
            "confidence": 0.0-1.0
        }
        """

        print(f"[GROQ AI] Analyzing frame with {self.model}...")
        chat_completion = self.client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                            },
                        },
                    ],
                }
            ],
            model=self.model,
            response_format={"type": "json_object"}
        )

        result = chat_completion.choices[0].message.content
        print(f"[GROQ AI] Analysis received: {result}")
        return result
