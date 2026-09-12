# 🛡️ ScanShield

**AI-Powered Android APK & PDF Security Scanner** — Static analysis, heuristic risk scoring, and an embedded AI assistant, built with Flutter + Python Flask + Firebase + Groq LLM.

<p>
<img src="https://img.shields.io/badge/Flutter-3.10.4-02569B?logo=flutter" alt="Flutter"/>
<img src="https://img.shields.io/badge/Python-3.10+-3776AB?logo=python" alt="Python"/>
<img src="https://img.shields.io/badge/Flask-3.1.3-000000?logo=flask" alt="Flask"/>
<img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase" alt="Firebase"/>
<img src="https://img.shields.io/badge/AI-Groq%20LLM-f97316" alt="Groq"/>
<img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

---

## ✨ Features

- 🔍 **APK Static Analysis** — Manifest parsing, component auditing (Activities / Services / Receivers / Providers), exported component detection, permission hazard categorization
- ⚡ **DEX Byte-Stream Scanning** — Fast regex/signature scanning of `classes*.dex` for suspicious APIs (`DexClassLoader`, `Runtime.exec`, SMS handlers), network indicators, crypto algorithms, and anti-analysis techniques
- 📄 **PDF Inspection** — Encryption state, page count & metadata via PyMuPDF
- 🧠 **Heuristic Risk Engine** — 0–100 risk score with Low / Medium / High classification
- 🤖 **ShieldBot AI Assistant** — Context-aware chatbot (Groq `qwen/qwen3.8-27b`) that reads live scan reports and explains findings in plain language
- ☁️ **Cloud Sync** — Cloud Firestore scan history, batch management & cross-session persistence
- 🔒 **Privacy-First** — Files processed transiently and auto-deleted; zero persistent backend storage

## 🏗️ Architecture

```javascript
Flutter App ──┬── Firebase Auth (Email/Password + Google OAuth)
              ├── Cloud Firestore (users / scans / stats)
              ├── Groq API (ShieldBot AI)
              └── Flask Backend ── LightAPK (Androguard) + PyMuPDF + Risk Engine
```

## 🛠️ Tech Stack

| Layer | Tech |
| --- | --- |
| Frontend | Flutter 3.10.4, Dart, FL Chart, Lottie, file_picker |
| Backend | Python 3.10+, Flask, Flask-CORS, Androguard 4.1.4, PyMuPDF 1.28.0 |
| Cloud | Firebase Auth, Cloud Firestore |
| AI | Groq Cloud LLM (`qwen/qwen3.8-27b`) |

## 🚀 Quick Start

### Backend

```bash
cd backend
python3 -m venv venv && source venv/bin/activate   # Windows: venv\Scriptsctivate
pip install -r requirements.txt
echo "PORT=5000" > .env
python app.py   # → http://localhost:5000
```

### Frontend

```bash
flutter pub get
# Set API_BASE_URL in .env (Android emulator: http://10.0.2.2:5000)
flutter run
```

### Tests

```bash
flutter test
```

## 📡 API

| Endpoint | Method | Description |
| --- | --- | --- |
| `/` | GET | Health check / warm-up |
| `/analyze` | POST | Multipart upload of `.apk` / `.pdf` (max 100 MB) → JSON risk report |

**Sample response (`POST /analyze`):**

```json
{
  "package_name": "com.security.example",
  "overall_risk": 75,
  "risk_level": "High",
  "permissions_breakdown": {
    "Critical": ["android.permission.SYSTEM_ALERT_WINDOW"],
    "Dangerous": ["android.permission.SEND_SMS"],
    "Normal": ["android.permission.INTERNET"]
  },
  "network_indicators": { "urls": ["https://api.example.com"], "localhost": false },
  "crypto_indicators": ["AES", "SHA256"]
}
```

## 🗄️ Firestore Schema

- **`users/{uid}`** — `email`, `name`, `created_at`, `last_login`, `total_scans`
- **`scans/{autoId}`** — `user_id`, `file_name`, `file_type`, `overall_risk`, `risk_level`, `scanned_at`
- **`stats/global_stats`** — `total_scans`, `low_count`, `medium_count`, `high_count`

## 📁 Project Structure

```javascript
├── backend/
│   ├── analyzer/     # apk_analyzer.py · pdf_analyzer.py · risk_engine.py
│   ├── app.py        # Flask server & routes
│   └── requirements.txt
└── lib/
    ├── chatbot/      # ShieldBot AI overlay & services
    ├── models/       # scan_model.dart · user_model.dart
    ├── screens/      # auth, dashboard, scan, report, history
    ├── services/     # api · auth · firestore
    ├── utils/        # theme, constants, recommendation engine
    └── widgets/      # reusable UI components
```

## 🔒 Security Notes

- Uploads capped at **100 MB** (`MAX_CONTENT_LENGTH`) to prevent DoS
- Custom `LightAPK` loader cuts APK memory footprint from >200 MB to <25 MB
- Uploaded files deleted in a `finally` block — guaranteed cleanup
- Secrets isolated in `.env` (excluded via `.gitignore`)

---

<p align="center">Made with 🛡️ by one and only Shreyash Jadhav</p>
