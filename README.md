# MindSarthi: Your Pocket Mental Health Companion

*MindSarthi* is a mobile-first mental wellness platform built to deliver accessible, secure, and empathetic support to individuals, mental health professionals, and organizations. Developed during *Hacksagon 2025*, this is a functional MVP submission for the Mobile App track.

---

## 📱 Overview

MindSarthi enables:
- AI-powered emotional support (via ChatPal)
- Real-time panic/SOS system
- Verified professional consultations
- Daily wellness tools (mood tracker, journaling, insights)
- Role-based UX for personal, professional, and organizational users

---

## Screenshots


---

## ⚙ Tech Stack

| Layer         | Technology                                |
|---------------|--------------------------------------------|
| Frontend      | Flutter (Android/iOS)                     |
| Backend       | Firebase (Firestore, Auth)                |
| Local Storage | Hive (encrypted journaling & offline data)|
| AI / NLP      | Gemini API (planned)                      |

---

## 🧠 Core Features

- 🔐 Role-based Onboarding (Personal, Professional, Organization)
- 🧭 Dashboard with navigation to 5 key modules
- 😌 Mood Tracker + Daily Goals + Journaling (Hive)
- 🚨 **Panic SOS Button** (trigger flow + mock emergency connect) – *Unique Safety USP*
- 🤖 ChatPal: Simulated NLP-powered AI chat interface
- 📅 Book & View Therapy Sessions (mocked with placeholders)

---

## 🧪 How to Run Locally

```bash
# 1. Clone the repo
https://github.com/TeamCtrlFreaks/MindSarthi

# 2. Install Flutter packages
dart pub get

# 3. Run the app
flutter run
```

### 🔐 Firebase Setup

Ensure you link your Firebase project with:
- Authentication (Email/Password)
- Firestore (with rules for role-based users)
- Firestore Collections: users, sessions, moods

---

## 🛡️ Security & Environment Configuration

Sensitive keys and configuration files have been intentionally **excluded from version control** using `.gitignore` to ensure security and portability.

### 🔒 Ignored Files:

- `lib/firebase_options.dart` – Auto-generated Firebase config (use `flutterfire configure` to regenerate)
- `lib/services/gemini_api_key.dart` – Gemini API Key (replace with your own securely)

These files are excluded via `.gitignore` to **protect API keys** and prevent accidental exposure. If you're running the project locally, make sure to:
- Set up your Firebase project and regenerate `firebase_options.dart`
- Add your Gemini API key in the appropriate file

> ✅ *Do not commit secrets or credentials to the repo. Use `.env`, `flutter_dotenv`, or secure key management for production.*

---

## 🚧 Features in Progress

- 🎙 Voice-based AI journaling & regional language support
- 📊 Org dashboards with anonymized wellness reports
- 🧠 Live Gemini API integration for real-time sentiment support
- 💬 Community & peer discussion module

---

## 📂 Folder Structure

```
/lib
  /screens         --> UI Screens per module
  /services        --> Firebase, Hive, API helpers
  /models          --> Data models
  /widgets         --> Reusable components
  /utils           --> Constants, routing, themes
```

---

## 👥 Team Ctrl Freaks

- [Anamika Dey](https://github.com/anamikadey099)
- [Pragya Kumar](https://github.com/Pragya-Kumar)
- [Geetish Mahato](https://github.com/GeetishM) 

---

## 📽 Demo Video

[Link to demo video here once ready]

---

## 📣 License

MIT License – free to use for social good. Attribution appreciated!

---

## 🙏 Acknowledgments

- Mentors & Judges from Hacksagon 2025  
- Google Firebase + Gemini APIs  
- Flutter Community  
- Mental health advocates who inspired this idea  

---
