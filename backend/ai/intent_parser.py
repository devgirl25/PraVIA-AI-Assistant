"""
PraVIA Intent Parser
---------------------
Converts a raw natural-language command into a structured intent JSON
that the Flutter app can execute.

This is a rule-based parser using regex + keyword matching, designed to
run fast and fully offline. It is structured so that a local LLM
(e.g. llama.cpp, Ollama) or a remote LLM call can be dropped in later
by replacing `parse_intent()` internals while keeping the same
input/output contract.

Supported intents:
    OPEN_APP
    MAKE_CALL
    SEND_SMS
    PLAY_MUSIC
    PAUSE_MUSIC
    NEXT_TRACK
    PREVIOUS_TRACK
    ADD_EXPENSE
    ADD_TRADE
    SHOW_EXPENSES
    SHOW_TRADING_STATS
    UNKNOWN
"""

import re
from typing import Optional, Dict, Any


class IntentResult:
    def __init__(self, intent: str, parameters: Dict[str, Any], confidence: float = 1.0):
        self.intent = intent
        self.parameters = parameters
        self.confidence = confidence

    def to_dict(self) -> Dict[str, Any]:
        return {
            "intent": self.intent,
            "parameters": self.parameters,
            "confidence": self.confidence,
        }


# ---------------------------------------------------------------------------
# Helper patterns
# ---------------------------------------------------------------------------

_OPEN_APP_PATTERNS = [
    r"^open\s+(?P<app>.+)$",
    r"^launch\s+(?P<app>.+)$",
    r"^start\s+(?P<app>.+)$",
]

_CALL_PATTERNS = [
    r"^call\s+(?P<contact>.+)$",
    r"^phone\s+(?P<contact>.+)$",
    r"^dial\s+(?P<contact>.+)$",
]

# "message rahul saying i will reach late"
# "text rahul that i will reach late"
# "send sms to rahul saying i am on my way"
_SMS_PATTERNS = [
    r"^(?:message|text)\s+(?P<contact>[a-zA-Z ]+?)\s+(?:saying|that|to say)\s+(?P<message>.+)$",
    r"^send\s+(?:sms|message|text)\s+to\s+(?P<contact>[a-zA-Z ]+?)\s+(?:saying|that|to say)\s+(?P<message>.+)$",
]

_MUSIC_PLAY_PATTERNS = [
    r"^play\s+(?:my\s+)?(?P<playlist>.+)$",
    r"^resume\s+music$",
]

_MUSIC_PAUSE_PATTERNS = [
    r"^pause(?:\s+music)?$",
    r"^stop(?:\s+music)?$",
]

_MUSIC_NEXT_PATTERNS = [r"^(?:next|skip)(?:\s+track|\s+song)?$"]
_MUSIC_PREV_PATTERNS = [r"^(?:previous|back|last)(?:\s+track|\s+song)?$"]

# "add expense 250 for food at cafe coffee day"
# "paid rs 250 at cafe coffee day"
_EXPENSE_PATTERNS = [
    r"(?:paid|spent)\s+(?:rs\.?|inr|₹)?\s*(?P<amount>\d+(?:\.\d+)?)\s+(?:at|on|for)\s+(?P<merchant>.+)$",
    r"add\s+expense\s+(?:rs\.?|inr|₹)?\s*(?P<amount>\d+(?:\.\d+)?)\s+(?:for\s+(?P<category>[a-zA-Z]+)\s+)?(?:at|on)\s+(?P<merchant>.+)$",
]

_SHOW_EXPENSE_PATTERNS = [
    r"how much did i spend(?:\s+this\s+(?P<period>\w+))?",
    r"show\s+(?:my\s+)?(?P<category>[a-zA-Z]+)?\s*expenses",
    r"show\s+(?:my\s+)?spending",
]

_ADD_TRADE_PATTERNS = [r"^add\s+(?:a\s+)?trade$"]

_TRADING_STATS_PATTERNS = [
    r"how did i (?:perform|do)(?:\s+this\s+(?P<period>\w+))?",
    r"my best trade",
    r"(?:show\s+)?trading\s+stats",
]


def _match_any(patterns, text) -> Optional[re.Match]:
    for p in patterns:
        m = re.match(p, text, re.IGNORECASE)
        if m:
            return m
    return None


def parse_intent(raw_text: str) -> IntentResult:
    """
    Parse a raw voice/text command into a structured intent.

    Args:
        raw_text: the transcribed user command, e.g. "Open Instagram"

    Returns:
        IntentResult with `intent` and `parameters`
    """
    text = raw_text.strip().lower()
    text = re.sub(r"[.!?]+$", "", text)  # strip trailing punctuation

    # --- SMS (check before OPEN_APP/CALL since it has more specific keywords) ---
    m = _match_any(_SMS_PATTERNS, text)
    if m:
        contact = m.group("contact").strip().title()
        message = m.group("message").strip().capitalize()
        return IntentResult("SEND_SMS", {"contact": contact, "message": message})

    # --- MAKE_CALL ---
    m = _match_any(_CALL_PATTERNS, text)
    if m:
        contact = m.group("contact").strip().title()
        return IntentResult("MAKE_CALL", {"contact": contact})

    # --- MUSIC ---
    m = _match_any(_MUSIC_PAUSE_PATTERNS, text)
    if m:
        return IntentResult("PAUSE_MUSIC", {})

    m = _match_any(_MUSIC_NEXT_PATTERNS, text)
    if m:
        return IntentResult("NEXT_TRACK", {})

    m = _match_any(_MUSIC_PREV_PATTERNS, text)
    if m:
        return IntentResult("PREVIOUS_TRACK", {})

    m = _match_any(_MUSIC_PLAY_PATTERNS, text)
    if m:
        playlist = m.groupdict().get("playlist")
        return IntentResult("PLAY_MUSIC", {"query": playlist.strip() if playlist else None})

    # --- EXPENSE ---
    m = _match_any(_EXPENSE_PATTERNS, text)
    if m:
        gd = m.groupdict()
        return IntentResult(
            "ADD_EXPENSE",
            {
                "amount": float(gd["amount"]),
                "merchant": gd.get("merchant", "").strip().title() if gd.get("merchant") else None,
                "category": gd.get("category", "").strip().title() if gd.get("category") else None,
            },
        )

    m = _match_any(_SHOW_EXPENSE_PATTERNS, text)
    if m:
        gd = m.groupdict()
        return IntentResult(
            "SHOW_EXPENSES",
            {
                "period": gd.get("period"),
                "category": gd.get("category").strip().title() if gd.get("category") else None,
            },
        )

    # --- TRADING ---
    m = _match_any(_ADD_TRADE_PATTERNS, text)
    if m:
        return IntentResult("ADD_TRADE", {})

    m = _match_any(_TRADING_STATS_PATTERNS, text)
    if m:
        gd = m.groupdict()
        return IntentResult("SHOW_TRADING_STATS", {"period": gd.get("period")})

    # --- OPEN_APP (checked late since it's a catch-all "open X") ---
    m = _match_any(_OPEN_APP_PATTERNS, text)
    if m:
        app = m.group("app").strip().title()
        return IntentResult("OPEN_APP", {"app": app})

    # --- UNKNOWN ---
    return IntentResult("UNKNOWN", {"raw_text": raw_text}, confidence=0.0)


# ---------------------------------------------------------------------------
# Quick manual test (run: python -m ai.intent_parser)
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    tests = [
        "Open Instagram",
        "Call Mom",
        "Message Rahul saying I will reach late",
        "Play my study playlist",
        "Pause music",
        "Paid Rs 250 at Cafe Coffee Day",
        "How much did I spend this month?",
        "Add a trade",
        "How did I perform this week?",
        "gibberish command xyz",
    ]
    for t in tests:
        result = parse_intent(t)
        print(f"{t!r:55} -> {result.to_dict()}")
