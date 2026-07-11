# PraVIA — Personal Jarvis-Style AI Assistant

**Phase 1 (this delivery):** Voice Assistant Core + App Control + Contact/Call Assistant + SMS Assistant.

---

## 1. Project Structure

```
pravia/
├── backend/                     # Python FastAPI intent-parsing service
│   ├── main.py                  # App entrypoint
│   ├── requirements.txt
│   ├── ai/
│   │   └── intent_parser.py     # Rule-based NLU (regex), swappable for an LLM later
│   ├── database/
│   │   └── models.py            # SQLAlchemy models + SQLite setup
│   └── api/
│       └── routes.py            # /api/intent, /api/messages endpoints
│
└── frontend/                    # Flutter app
    ├── pubspec.yaml
    ├── android/app/src/main/AndroidManifest.xml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── models/
        │   │   ├── intent_model.dart
        │   │   └── chat_message_model.dart
        │   ├── services/
        │   │   ├── app_controller.dart      # launchApp(), getInstalledApps()
        │   │   ├── contact_service.dart      # getContactByName(), makeCall()
        │   │   ├── sms_service.dart          # sendSMS(), message history
        │   │   ├── speech_service.dart       # STT + TTS
        │   │   ├── api_client.dart           # talks to FastAPI backend
        │   │   └── local_intent_parser.dart  # offline fallback parser
        │   └── controllers/
        │       ├── intent_executor.dart      # routes intent -> action
        │       └── assistant_providers.dart  # Riverpod state + orchestration
        └── screens/
            ├── home_screen.dart       # Jarvis mic UI
            ├── chat_history_screen.dart
            └── settings_screen.dart
```

---

## 2. Backend Setup (FastAPI)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Verify it's running:
```bash
curl http://127.0.0.1:8000/
# {"status":"ok","service":"PraVIA Backend"}

curl -X POST http://127.0.0.1:8000/api/intent \
  -H "Content-Type: application/json" \
  -d '{"text":"Call Mom"}'
# {"intent":"MAKE_CALL","parameters":{"contact":"Mom"},"confidence":1.0}
```

Both endpoints above have already been tested and confirmed working during development.

### API Endpoints (Phase 1)

| Method | Path                | Description                                   |
|--------|---------------------|------------------------------------------------|
| GET    | `/`                 | Health check                                   |
| POST   | `/api/intent`       | `{ "text": "..." }` → structured intent JSON   |
| POST   | `/api/messages/log` | Log a sent SMS (`receiver`, `message`)         |
| GET    | `/api/messages`     | List SMS history                               |

### Database Schema (SQLite via SQLAlchemy)

```
messages
  id          INTEGER PK
  receiver    TEXT
  message     TEXT
  timestamp   DATETIME

expenses      -- created now, wired up in Phase 2
  id          INTEGER PK
  amount      FLOAT
  category    TEXT
  merchant    TEXT
  date        DATETIME

trades        -- created now, wired up in Phase 3
  id              INTEGER PK
  stock           TEXT
  quantity        INTEGER
  entry_price     FLOAT
  exit_price      FLOAT
  profit_loss     FLOAT
  strategy        TEXT
  date            DATETIME
```

---

## 3. Frontend Setup (Flutter)

**Prerequisites:** Flutter SDK ≥ 3.19 installed, an Android device/emulator with API 26+.

```bash
cd frontend
flutter pub get
flutter run
```

### Connecting to the backend

- **Android emulator:** no changes needed — `10.0.2.2` (set in `api_client.dart`) already maps to your host machine's `localhost:8000`.
- **Physical device on same Wi-Fi:** edit `lib/core/services/api_client.dart` and set `baseUrl` to `http://<your-computer-LAN-IP>:8000`.

> The app works even if the backend is unreachable — `ApiClient` automatically falls back to `LocalIntentParser`, an on-device Dart port of the same rule-based logic, so core commands (open app / call / SMS) never depend on network availability.

### Android Permissions (already declared in `AndroidManifest.xml`)

| Permission | Why |
|---|---|
| `RECORD_AUDIO` | Voice input (speech-to-text) |
| `READ_CONTACTS` | Resolve "Mom" / "Rahul" to phone numbers |
| `CALL_PHONE` | Place calls directly |
| `SEND_SMS`, `READ_SMS`, `RECEIVE_SMS` | Send messages now; read SMS for Phase 2 expense parsing |
| `QUERY_ALL_PACKAGES` + `<queries>` | Detect and launch installed apps |
| `INTERNET` | Talk to FastAPI backend |

All of these are **runtime** permissions on Android 6+ — the app requests them contextually the first time each feature is used (see `contact_service.dart`, `sms_service.dart`, `speech_service.dart`), and you can review/re-grant them anytime from the in-app **Settings** screen.

### Key pubspec.yaml packages and why

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `speech_to_text` | Voice → text |
| `flutter_tts` | Text → voice replies |
| `device_apps` + `android_intent_plus` | List & launch installed apps |
| `flutter_contacts` | Contact lookup |
| `telephony` | Send SMS without leaving the app (also used for reading SMS in Phase 2) |
| `permission_handler` | Runtime permission requests |
| `hive` / `hive_flutter` | Local message history storage |
| `http` | Calls to the FastAPI backend |

---

## 4. How a Voice Command Flows (Phase 1)

```
User taps mic
   → SpeechService.startListening()      (speech_to_text)
   → transcribed text
   → ApiClient.parseIntent(text)         (FastAPI /api/intent, or local fallback)
   → IntentModel { intent, parameters }
   → IntentExecutor.execute(intent)
        ├─ OPEN_APP  → AppController.launchApp()
        ├─ MAKE_CALL → ContactService.callByName()
        └─ SEND_SMS  → SmsService.sendToContactByName()
   → response string
   → ChatHistoryNotifier (shown in Chat History screen)
   → SpeechService.speak(response)       (flutter_tts)
```

## 5. Tested Example Commands (Phase 1)

| Voice Command | Result |
|---|---|
| "Open Instagram" | Launches Instagram if installed |
| "Call Mom" | Looks up "Mom" in contacts, places call |
| "Message Rahul saying I will reach late" | Looks up "Rahul", sends SMS, logs to history |

The intent parser (both backend Python and the Dart offline fallback) has been unit-tested against all three of these plus edge cases — see `backend/ai/intent_parser.py`'s `__main__` block for the test harness (already run successfully).

---

## 6. Roadmap (Not Yet Implemented)

- **Phase 2 — Expense Tracker:** parse transaction SMS, `expenses` table (already created), dashboard with charts.
- **Phase 3 — Trading Journal:** manual trade entry, P/L calculation, `trades` table (already created), win-rate dashboard.
- **Phase 4 — Music Assistant:** `MusicController.dart` using Android's `MediaController` / `just_audio` + platform channel.
- **Phase 5 — AI Memory System:** persistent conversational memory, likely a local vector store + summarization layer.

`IntentExecutor` already has switch-case stubs wired up for all Phase 2–4 intents, returning a "coming in a later phase" message, so extending it is a matter of filling in each case — no restructuring needed.

---

## 7. Known Limitations to Be Aware Of

- `device_apps` and `telephony` are Android-only — this app is Android-first per your spec (no iOS SMS/call parity is possible on iOS due to platform restrictions).
- The rule-based intent parser handles the exact command patterns shown above and reasonable variations, but isn't a full LLM — Phase 5 (or an earlier upgrade) can swap `ai/intent_parser.py`'s internals for a local/hosted LLM call while keeping the same `/api/intent` contract, so the Flutter side needs zero changes.
- `CALL_PHONE` directly places a call with no confirmation dialog — this is intentional per your "Jarvis" spec, but review whether you want a confirmation step before shipping, since silent-calling is a common Play Store review flag.
