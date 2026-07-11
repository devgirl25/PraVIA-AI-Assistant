"""
PraVIA Backend — FastAPI entrypoint

Run:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Then from an Android device/emulator, the Flutter app should call:
    http://10.0.2.2:8000   (Android emulator -> host machine)
    http://<your-lan-ip>:8000  (physical device on same Wi-Fi)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database.models import init_db
from api.routes import router as api_router

app = FastAPI(title="PraVIA Backend", version="0.1.0")

# Allow the Flutter app (running from any origin/device) to call this API.
# Lock this down to specific origins before shipping to production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    init_db()


@app.get("/")
def health_check():
    return {"status": "ok", "service": "PraVIA Backend"}


app.include_router(api_router, prefix="/api", tags=["assistant"])
