# 🛡️ HERO-IE: Hospitality Emergency Response and Orchestration

**HERO-IE** is an AI-driven, decentralized emergency management ecosystem specifically designed for high-density hospitality environments (hotels, resorts, stadiums). It leverages cutting-edge Computer Vision and P2P Mesh Networking to provide real-time risk detection, crowd monitoring, and evacuation guidance—even when the internet goes down.

## 🚀 Key Features

### 🧠 AI Risk Detection (Vision)
Utilizes state-of-the-art Large Language Models (LLMs) with vision capabilities to monitor CCTV/Live-cam feeds.
- **Two-Step Simulation**: Optimized ingestion process featuring one-time video storage and lightweight, 5-second analysis polling.
- **Zone-Based Analysis**: Categorizes risks into **GREEN** (Safe), **YELLOW** (Warning), and **RED** (Immediate Danger).

### 📶 Offline Mesh Network (SOS)
Ensures survival-critical communication even in total internet blackouts.
- **Nearby Connections**: Devices automatically form a P2P mesh network to propagate SOS alerts.
- **Rich Media SOS**: Users can upload images or short videos of hazards, which are analyzed by AI to update building-wide evacuation routes.

### 🗺️ Live Risk Heatmap
A real-time "pulse" of the facility for staff, showing high-density areas and potential bottlenecks.
- **Vitals Monitoring**: Aggregates heart rate and location data (anonymized) to identify areas in distress.

### 🏃 Dynamic AI Evacuation Routing
- Automatically calculates the safest path to exits by avoiding zones where the AI has detected fire, smoke, or overcrowding.

### 🔔 Deadman's Switch
- Automated emergency triggers that activate if a user (e.g., security personnel) doesn't check in after a high-risk event detection.

### 🌍 Universal Accessibility
- Full localization supporting **English, Hindi (हिन्दी), Marathi (मराठी), and Bengali (বাংলা)**.

---

## 🛠️ Technology Stack

### Backend (FastAPI / Python)
- **Framework**: `FastAPI` (High-performance API)
- **AI Model**: `meta-llama/llama-4-scout-17b-16e-instruct` (via Groq Vision)
- **Database & Storage**: `Supabase` (Real-time DB + FIFO Image Storage)
- **Image Processing**: `OpenCV` (Frame extraction from simulations)
- **Automation**: `Python-Dotenv`, `Uvicorn`

### Frontend (Flutter)
- **Framework**: `Flutter` (Cross-platform Mobile)
- **State Management**: `ValueNotifier` & `Provider` patterns
- **Networking**: `HTTP`, `Dart IO`
- **P2P Mesh**: `nearby_connections: ^4.3.0` (Google Nearby API)
- **Routing**: `go_router: ^17.2.1`
- **Media**: `video_player: ^2.9.2`, `image_picker: ^1.1.2`

---

## 📂 Project Structure

```text
/
├── backend/                  # Python FastAPI Core
│   ├── core/                 # Supabase clients & configuration
│   ├── data/                 # Local simulation storage
│   ├── features/             # Modular business logic
│   │   ├── risk_detection/   # Groq AI Vision & FIFO Storage
│   │   ├── evacuation/       # Pathfinding logic
│   │   ├── deadmans_switch/  # Alarm logic
│   │   └── heatmap/          # Zone-density aggregation
│   └── main.py               # API Entry Point
└── frontend/
    └── hero_ie_app/          # Flutter Application
        ├── lib/
        │   ├── core/         # Localization & API services
        │   ├── features/     # UI screens (Admin & Guest roles)
        │   └── HERO-IE_ICON.png # High-res app icon
        └── pubspec.yaml
```

---

## ⚙️ Setup Instructions

### 1. Backend Setup
1. `cd backend`
2. Install dependencies: `pip install -r requirements.txt`
3. Create a `.env` file based on the following template:
   ```env
   GROQ_API_KEY=your_key_here
   SUPABASE_URL=your_project_url
   SUPABASE_KEY=your_service_role_key
   ```
4. Start the server: `python main.py`

### 2. Frontend Setup
1. `cd frontend/hero_ie_app`
2. Fetch packages: `flutter pub get`
3. Generate icons (if needed): `dart run flutter_launcher_icons`
4. Run on a connected device: `flutter run`

---

## 📱 Multi-Device Deployment (Mesh Testing)

To test the **Offline Mesh Network**, you need to install the app on at least two devices. If you are deploying to a friend's phone, use the following fast method:

1.  **Enable Developer Options** on the target phone (Tap 'Build Number' 7 times).
2.  **Enable USB Debugging**.
3.  Plug the phone into your PC and find its ID:
    ```powershell
    adb devices
    ```
4.  **Install the APK** directly (Fastest way):
    ```powershell
    adb -s FRIEND_ID install -r f:\projects\donut\frontend\hero_ie_app\build\app\outputs\flutter-apk\app-debug.apk
    ```

---

## ⚖️ License
HERO-IE is developed as a submission for the **Google Solution Challenge**. All rights reserved by the development team: "**RunTime Error**.
