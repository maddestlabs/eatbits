# EatBits
Mobile-first and web-first, totally unprofessional digital audio workstation (DAW) built with Flutter, WebAudio API, and Lua Live Scripting.

---

## Live Web App

👉 **[https://maddestlabs.github.io/eatbits/](https://maddestlabs.github.io/eatbits/)**

---

## Features

- Built for easy access on the web
- Built with Flutter for easy portability on native mobile and desktop
- Unified Edit Section (Piano Roll & Tracker)
- Lua Live Scripting of audio API

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or later)

### Running Locally
```bash
# Clone the repository
git clone https://github.com/maddestlabs/eatbits.git
cd eatbits

# Fetch dependencies
flutter pub get

# Run Web app locally
flutter run -d chrome
```

### Building Web Release
```bash
flutter build web --release --base-href "/eatbits/" --pwa-strategy=none
```

---

## 📄 License
MIT License
