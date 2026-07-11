from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import datetime

from database.models import get_db, Message
from ai.intent_parser import parse_intent

router = APIRouter()


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class CommandRequest(BaseModel):
    text: str


class IntentResponse(BaseModel):
    intent: str
    parameters: dict
    confidence: float


class MessageLogRequest(BaseModel):
    receiver: str
    message: str


# ---------------------------------------------------------------------------
# Routes — Phase 1
# ---------------------------------------------------------------------------

@router.post("/intent", response_model=IntentResponse)
def get_intent(payload: CommandRequest):
    """
    Core endpoint used by the Flutter app.
    Send raw transcribed text -> get back a structured intent.
    """
    result = parse_intent(payload.text)
    return result.to_dict()


@router.post("/messages/log")
def log_message(payload: MessageLogRequest, db: Session = Depends(get_db)):
    """
    Called by the app after it sends an SMS locally via the native
    SMS API, so the backend keeps a history record too.
    """
    msg = Message(receiver=payload.receiver, message=payload.message, timestamp=datetime.utcnow())
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return {"id": msg.id, "receiver": msg.receiver, "message": msg.message, "timestamp": msg.timestamp}


@router.get("/messages")
def list_messages(db: Session = Depends(get_db)):
    messages = db.query(Message).order_by(Message.timestamp.desc()).all()
    return [
        {"id": m.id, "receiver": m.receiver, "message": m.message, "timestamp": m.timestamp}
        for m in messages
    ]
