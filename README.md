# Eatsbits
Mobile-first and web-first, totally unprofessional digital audio workstation (DAW) built with Flutter, WebAudio API, and Lua Live Scripting.

---

## Live Web App

👉 **[https://maddestlabs.github.io/eatsbits/](https://maddestlabs.github.io/eatsbits/)**

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
git clone https://github.com/maddestlabs/eatsbits.git
cd eatsbits

# Fetch dependencies
flutter pub get

# Run Web app locally
flutter run -d chrome
```

### Building Web Release
```bash
flutter build web --release --base-href "/eatsbits/" --pwa-strategy=none
```

## GitHub Pages Build Stability

GitHub Pages deploys this app with Flutter web, and the Pages runner is less forgiving than local hot reload. The most recent breakages came from reintroducing `google_fonts`, which currently fails `dart2js` under the Flutter version used in CI.

Avoid these regressions with these rules:

- Prefer bundled fonts or generic `sans-serif` and `monospace` families for web builds instead of runtime font packages.
- Keep the Pages workflow on a pinned Flutter SDK version so upstream `stable` changes do not silently change the compiler/toolchain.
- Before pushing UI, dependency, or web bootstrap changes, run `flutter pub get`, `flutter analyze`, and `flutter build web --release --base-href "/eatsbits/"` locally.
- Treat `pubspec.yaml`, `pubspec.lock`, and `.github/workflows/deploy.yml` as one deployment surface. If one changes, verify the web release build before merging.
- If remote fonts are required later, bundle them as project assets and declare them in Flutter rather than depending on `google_fonts` for the Pages build path.

---

## 📄 License
MIT License
