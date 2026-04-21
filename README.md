<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=18,20,24&height=200&section=header&text=MindSarthi%20🧠&fontSize=55&fontColor=fff&animation=twinkling&fontAlignY=38&desc=Your%20Pocket%20Mental%20Health%20Companion&descAlignY=58&descSize=18&descColor=B39DDB"/>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&pause=1000&color=B39DDB&center=true&vCenter=true&width=700&lines=AI-Powered+Emotional+Support+%F0%9F%A4%96;Real-Time+Panic+%2F+SOS+System+%F0%9F%9A%A8;Verified+Professional+Consultations+%F0%9F%91%A8%E2%80%8D%E2%9A%95%EF%B8%8F;Daily+Wellness+Tools+%E2%80%94+Mood%2C+Journal%2C+Goals+%F0%9F%93%93;Built+with+Flutter+%2B+Firebase+%2B+Gemini+%F0%9F%94%A5)](https://git.io/typing-svg)

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-Android%2FiOS-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Gemini_API-AI%20Powered-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![Hive](https://img.shields.io/badge/Hive-Local%20Storage-FF7043?style=for-the-badge)](https://hivedb.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

> *Accessible, secure, and empathetic mental health support — for individuals, professionals, and organizations* 💜

</div>

---

## 📋 Table of Contents

<div align="center">

| | | |
|:---:|:---:|:---:|
| [🧠 Overview](#-overview) | [✨ Features](#-core-features) | [🗺️ App Architecture](#%EF%B8%8F-app-architecture) |
| [🔄 App Flow](#-app-flow) | [🛠️ Tech Stack](#%EF%B8%8F-tech-stack) | [📸 Screenshots](#-screenshots) |
| [🚀 Getting Started](#-getting-started) | [🛡️ Security](#%EF%B8%8F-security--environment) | [🚧 Roadmap](#-features-in-progress) |
| [📂 Folder Structure](#-folder-structure) | [👥 Team](#-team-ctrl-freaks) | [🙏 Acknowledgments](#-acknowledgments) |

</div>

---

## 🧠 Overview

**MindSarthi** is a mobile-first mental wellness platform built to deliver **accessible, secure, and empathetic support** to individuals, mental health professionals, and organizations.

<div align="center">

| 👤 Personal Users | 👨‍⚕️ Professionals | 🏢 Organizations |
|:---:|:---:|:---:|
| Daily wellness tools | Session management | Anonymized reports |
| AI emotional support | Client consultations | Team wellness dashboards |
| Panic SOS system | Verified profiles | Role-based access |

</div>

---

## ✨ Core Features

<div align="center">

| Feature | Description |
|:---:|:---|
| 🔐 **Role-based Onboarding** | Separate flows for Personal, Professional & Organization users |
| 😌 **Mood Tracker** | Log and visualize your daily emotional state |
| 📓 **Journaling** | Encrypted local journaling via Hive |
| 🎯 **Daily Goals** | Set and track small wellness milestones |
| 🚨 **Panic SOS Button** | Trigger emergency flow + mock connect — *Unique Safety USP* |
| 🤖 **ChatPal** | AI-powered chatbot for instant mental health guidance |
| 📅 **Consult** | Book & manage therapy sessions with verified professionals |
| 📰 **Insights** | Expert-curated mental health articles & resources |
| 🫂 **Community** | Peer support space — share, connect, uplift |

</div>

---

## 🗺️ App Architecture

```mermaid
flowchart TD
    AUTH([🔐 Onboarding & Authentication]):::auth

    AUTH --> NAV

    subgraph NAV[📱 Main Navigation]
        direction LR
        H[🏠 Home]:::home
        C[📅 Consult]:::consult
        I[📰 Insights]:::insights
        CM[🫂 Community]:::community
        CP[🤖 ChatPal]:::chatpal
    end

    H --> H1[😌 Mood Tracker]:::feature
    H --> H2[🆘 Relief Resources]:::feature
    H --> H3[🎯 Daily Goals]:::feature
    H --> H4[📓 Journal]:::feature
    H --> H5[🚨 Panic Assist]:::feature

    H2 --> R1[Anxiety & Panic Attacks]:::sub
    H2 --> R2[Depression]:::sub
    H2 --> R3[Self-Harm & Suicidal Ideation]:::sub

    C --> C1[📋 Your Sessions]:::feature
    C --> C2[➕ Book a Session]:::feature

    I --> I1[Expert-curated Articles\n& Resources]:::desc
    CM --> CM1[Connect · Share · Support\nPeer Wellness Community]:::desc
    CP --> CP1[AI Chatbot · Instant Support\nMental Health Guidance 24/7]:::desc

    classDef auth     fill:#4A148C,color:#fff,stroke:none
    classDef home     fill:#1A237E,color:#fff,stroke:none
    classDef consult  fill:#006064,color:#fff,stroke:none
    classDef insights fill:#1B5E20,color:#fff,stroke:none
    classDef community fill:#E65100,color:#fff,stroke:none
    classDef chatpal  fill:#880E4F,color:#fff,stroke:none
    classDef feature  fill:#283593,color:#fff,stroke:#5C6BC0
    classDef sub      fill:#4A148C,color:#fff,stroke:#9C27B0,stroke-dasharray:4
    classDef desc     fill:#212121,color:#B39DDB,stroke:#5C6BC0,stroke-dasharray:3
```

---

## 🔄 App Flow

```mermaid
flowchart LR
    A([👤 User Opens App]):::start
    B{🔐 Authenticated?}:::decision
    C[📝 Onboarding\n+ Role Selection]:::process
    D{👤 Role?}:::decision
    E[🏠 Personal\nDashboard]:::personal
    F[👨‍⚕️ Professional\nDashboard]:::pro
    G[🏢 Organization\nDashboard]:::org

    A --> B
    B -->|No| C --> D
    B -->|Yes| D
    D -->|Personal| E
    D -->|Professional| F
    D -->|Organization| G

    E --> M[😌 Mood · 📓 Journal\n🎯 Goals · 🚨 SOS]:::feature
    E --> N[🤖 ChatPal\nAI Support]:::ai
    F --> O[📅 Sessions\n👥 Client Mgmt]:::feature
    G --> P[📊 Wellness\nReports]:::feature

    classDef start    fill:#4A148C,color:#fff,stroke:none
    classDef decision fill:#37474F,color:#fff,stroke:none
    classDef process  fill:#1A237E,color:#fff,stroke:none
    classDef personal fill:#006064,color:#fff,stroke:none
    classDef pro      fill:#1B5E20,color:#fff,stroke:none
    classDef org      fill:#E65100,color:#fff,stroke:none
    classDef feature  fill:#283593,color:#fff,stroke:#5C6BC0
    classDef ai       fill:#880E4F,color:#fff,stroke:none
```

---

## 🛠️ Tech Stack

<div align="center">

| Layer | Technology | Purpose |
|:---:|:---:|:---|
| 📱 Frontend | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) | Cross-platform Android/iOS app |
| 🔥 Backend | ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black) | Auth, Firestore DB, real-time sync |
| 💾 Local Storage | ![Hive](https://img.shields.io/badge/Hive-FF7043?style=flat) | Encrypted journaling & offline data |
| 🤖 AI / NLP | ![Gemini](https://img.shields.io/badge/Gemini_API-4285F4?style=flat&logo=google&logoColor=white) | ChatPal AI responses *(planned)* |
| 🎨 Design | ![Figma](https://img.shields.io/badge/Figma-F24E1E?style=flat&logo=figma&logoColor=white) | UI/UX design & prototyping |
| 💬 Language | ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) | App development language |

</div>

---

## 📸 Screenshots

<div align="center">
<img src="https://github.com/user-attachments/assets/4452d734-4b81-4b86-a9b6-84db737f4e6d" width="180"/>
<img src="https://github.com/user-attachments/assets/586488bd-7f89-46af-86a3-4b37d0f3035e" width="180"/>
<img src="https://github.com/user-attachments/assets/1ad68376-1f0a-4f56-a6e3-ea77d6ba9691" width="180"/>
<img src="https://github.com/user-attachments/assets/410ca569-2c82-4775-9ceb-a8021b8ab0d3" width="180"/>
<img src="https://github.com/user-attachments/assets/d3637de6-87bd-4cdb-a0f6-be52e6373e3b" width="180"/>
</div>

---

## 🚀 Getting Started

### Prerequisites

```
✅ Flutter 3.x SDK
✅ Dart SDK
✅ Firebase project (Firestore + Auth enabled)
✅ Gemini API key  →  https://ai.google.dev
```

### Setup

**1️⃣ Clone the repository**
```bash
git clone https://github.com/TeamCtrlFreaks/MindSarthi
cd MindSarthi
```

**2️⃣ Install dependencies**
```bash
dart pub get
```

**3️⃣ Configure Firebase**
```bash
flutterfire configure
```

**4️⃣ Add Gemini API key**

Create `lib/services/gemini_api_key.dart` and add your key:
```dart
const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

**5️⃣ Run the app**
```bash
flutter run
```

### 🔥 Firebase Collections Required

```
users/         → Role-based user profiles
sessions/      → Therapy session bookings
moods/         → Mood tracker entries
```

---

## 🛡️ Security & Environment

> ⚠️ Sensitive files are **excluded from version control** via `.gitignore`

<details>
<summary><b>🔒 Ignored Files (click to expand)</b></summary>

<br/>

| File | Reason |
|:---|:---|
| `lib/firebase_options.dart` | Auto-generated Firebase config — run `flutterfire configure` to regenerate |
| `lib/services/gemini_api_key.dart` | Gemini API Key — add your own securely |

</details>

> ✅ *Never commit secrets or credentials. Use `.env`, `flutter_dotenv`, or secure key management for production.*

---

## 🚧 Features in Progress

<div align="center">

| Feature | Status |
|:---|:---:|
| 🎙️ Voice-based AI journaling | 🔄 In Progress |
| 🌐 Regional language support | 🔄 In Progress |
| 📊 Org dashboards with anonymized wellness reports | 📋 Planned |
| 🧠 Live Gemini API integration for real-time sentiment | 📋 Planned |
| 💬 Community & peer discussion module | 📋 Planned |

</div>

---

## 📂 Folder Structure

<details>
<summary><b>📁 Click to expand</b></summary>

```
/lib
  /screens        → UI Screens per module
  /services       → Firebase, Hive, API helpers
  /models         → Data models
  /widgets        → Reusable components
  /utils          → Constants, routing, themes
```

</details>

---

## 👥 Team Ctrl Freaks

<div align="center">

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/GeetishM">
        <img src="https://github.com/GeetishM.png" width="80" style="border-radius:50%"/><br/>
        <b>Geetish Mahato</b>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/anamikadey099">
        <img src="https://github.com/anamikadey099.png" width="80" style="border-radius:50%"/><br/>
        <b>Anamika Dey</b>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/Pragya-Kumar">
        <img src="https://github.com/Pragya-Kumar.png" width="80" style="border-radius:50%"/><br/>
        <b>Pragya Kumar</b>
      </a>
    </td>
  </tr>
</table>

</div>

---

## 🙏 Acknowledgments

- 🏆 Mentors & Judges from **Hacksagon 2025**
- 🔥 **Google Firebase** + **Gemini APIs**
- 💙 **Flutter Community**
- 💜 Mental health advocates who inspired this idea

---

<div align="center">

*If MindSarthi resonates with you, please consider giving it a* ⭐

> 💜 *Mental health matters. You are not alone.*

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=18,20,24&height=100&section=footer"/>

</div>
