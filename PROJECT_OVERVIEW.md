# ScanShield - System Architecture & Technical Overview

> **Document Purpose:** This document serves as a comprehensive developer and AI reference manual for **ScanShield**. It explains the system architecture, stack capabilities, file structure, API endpoints, and security mechanisms without disclosing sensitive keys or environment variables.

---

## 🛡️ Project Overview

**ScanShield** is a dual-layered security analysis and risk assessment platform designed to detect malicious behavior in Android Application Packages (`.apk`) and Portable Document Format (`.pdf`) documents. 

It combines a cross-platform mobile frontend with a lightweight, specialized Python analysis microservice backend.

---

## 🏗️ High-Level System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 ScanShield Flutter App                  │
│       (UI Layer / User Dashboard / Scan Engine UI)       │
└────────────────────────────┬────────────────────────────┘
                             │
       HTTP Multi-part File Upload / JSON Analysis Response
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                 Python Flask Backend                    │
│   ┌───────────────────────┬──────────────────────────┐  │
│   │   Androguard (APK)    │    PyMuPDF (PDF Engine)  │  │
│   └───────────────────────┴──────────────────────────┘  │
│                             │                           │
│                             ▼                           │
│                 Heuristic Risk Engine                   │
│          (Score Calculation & Malicious Signals)         │
└─────────────────────────────────────────────────────────┘
                             │
                             ▼
               Firebase Firestore & Authentication
```

---

## 🛠️ Technology Stack & Dependencies

### 1. Frontend (Mobile Client)
* **Framework:** Flutter SDK (`^3.10.4`), Dart
* **Authentication:** Firebase Auth (`^5.3.1`), Google Sign-In (`^6.2.1`)
* **Database & Cloud Storage:** Cloud Firestore (`^5.4.4`)
* **HTTP / Network:** `http` (`^1.1.0`)
* **Visualization & Formatting:** `fl_chart` (`^0.65.0`), `lottie` (`^2.7.0`), `google_fonts` (`^6.1.0`), `flutter_markdown` (`^0.7.1`)
* **File Management:** `file_picker` (`^8.0.0`)

### 2. Backend (Static & Dynamic Analysis Microservice)
* **Framework:** Python Flask (`3.1.3`), Flask-CORS (`6.0.5`)
* **APK Static Analysis:** `androguard` (`4.1.4`)
* **PDF Inspection & Parsing:** `pymupdf` (`1.28.0`)
* **Environment Configuration:** `python-dotenv` (`1.2.2`)

---

## 📁 Repository Structure

```
ScanShield/
├── android/                   # Android native configuration & manifests
├── assets/                    # Static assets (images, lottie animations, app icons)
├── backend/                   # Python Flask Security Analysis Microservice
│   ├── analyzer/              # Analysis Engines
│   │   ├── apk_analyzer.py    # APK Permissions, Intent Filters, Certificate Inspector
│   │   ├── pdf_analyzer.py    # Embedded JavaScript, Launch Actions, Hidden Streams Inspector
│   │   └── risk_engine.py     # Heuristic Risk Aggregator & Scoring Logic
│   ├── reports/               # Generated scan reports / logs
│   ├── uploads/               # Temporary file buffer directory (auto-sanitized)
│   ├── app.py                 # Flask Server Entry Point & Endpoint Handlers
│   ├── requirements.txt       # Python Dependencies Manifest
│   └── .env                   # Environment variable template (Secrets excluded)
├── lib/                       # Flutter Application Source Code
│   ├── chatbot/               # Embedded AI Assistant / Security Help Chat UI
│   ├── models/                # Data Models (Scan Results, User Profiles, Risk Metrics)
│   ├── screens/               # App Views (Dashboard, File Upload, Report Details, Auth)
│   ├── services/              # API Client Services, Firebase Services, File Handler
│   ├── utils/                 # Constants, Colors, Formatting Helpers
│   ├── widgets/               # Reusable UI Components & Custom Widgets
│   ├── firebase_options.dart  # Firebase Configuration Initializer
│   └── main.dart              # Application Entry Point
├── pubspec.yaml               # Flutter Package & Asset Manifest
└── README.md                  # Quickstart documentation
```

---

## 📡 API Specifications

### Base URL: `http://<HOST>:<PORT>` (Default: `http://localhost:5000`)

### 1. Health Check
* **Endpoint:** `GET /`
* **Response Example:**
```json
{
  "message": "ScanShield Backend Running",
  "status": "success",
  "version": "1.0.0",
  "service": "ScanShield API"
}
```

### 2. File Analysis
* **Endpoint:** `POST /analyze`
* **Content-Type:** `multipart/form-data`
* **Form Field:** `file` (Supports `.apk`, `.pdf` up to 100 MB)
* **Response Example:**
```json
{
  "file_name": "sample_app.apk",
  "file_type": "apk",
  "risk_score": 78,
  "risk_level": "HIGH",
  "findings": [
    {
      "severity": "CRITICAL",
      "description": "Requests sensitive permission: android.permission.SEND_SMS"
    }
  ]
}
```

---

## 🔐 Security & Safety Policies

1. **No Hardcoded Credentials:** All private tokens, API keys, and service secrets must remain inside `.env` or Firebase console configurations (excluded via `.gitignore`).
2. **Buffer Sanitation:** Uploaded files stored in `backend/uploads/` are processed transiently and automatically purged upon inspection completion.
3. **Payload Thresholds:** Backend enforces strict request body limits (`MAX_CONTENT_LENGTH = 100 MB`).

---

## 🚀 Setup & Execution Guide

### Running Backend Service
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

### Running Flutter App
```bash
flutter pub get
flutter run
```
