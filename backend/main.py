import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from features.risk_detection.router import router as risk_router
from features.deadmans_switch.router import router as switch_router
from features.evacuation.router import router as evacuation_router
from features.heatmap.router import router as heatmap_router
from features.broadcast.router import router as broadcast_router
from features.admin.router import router as admin_router
from features.auth.router import router as auth_router

app = FastAPI(
    title="HERO-IE Backend",
    description="Hospitality Emergency Response and Orchestration - Integrated Ecosystem",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Adjust for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(risk_router)
app.include_router(switch_router)
app.include_router(evacuation_router)
app.include_router(heatmap_router)
app.include_router(broadcast_router)
app.include_router(admin_router)
app.include_router(auth_router)

@app.get("/")
async def root():
    return {
        "message": "Welcome to HERO-IE API",
        "status": "online",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=settings.PORT, reload=settings.DEBUG)
