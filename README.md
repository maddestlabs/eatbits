# EatBits 🎵📱
> Mobile-First, Web-First Professional Audio Workstation (DAW) built with Flutter, WebAudio API, and Wren Live Scripting.

---

## 🌟 Features

- **FL Studio Mobile & Cubasis Style Multitrack Arranger**:
  - Arranger timeline grid as the main focal point of the DAW.
  - Per-track pattern clips with drag-to-move and edge drag-to-resize controls.
  - Pixel-aligned track headers with Mute, Solo, Volume, Pan, and Track selection.
  - **Double-Tap / Double-Click Navigation**:
    - Double-tap any pattern clip -> opens in **Edit** (Piano Roll / Tracker).
    - Double-tap any track header/channel strip -> opens **Track Inspector**.

- **Unified Edit Section (Piano Roll & FastTracker)**:
  - **Piano Roll**: 2D graphical pitch/step canvas with multi-note editing.
  - **Tracker**: MilkyTracker / FastTracker style vertical hex event matrix (`C-4 01 V90 00`) with polyphonic sub-channel columns.

- **Wren Live Scripting DSP Engine**:
  - Write custom synthesizers & audio effects on-the-fly using embedded Wren code.
  - Automatic UI slider generation for parameters defined in code (`Param.add`).
  - Pre-built DSP presets: Acid 303 Synth, FM Synth, Bitcrusher, Tube Distortion.

- **Dedicated Track Inspector**:
  - Channel strip volume/pan faders & FX rack insert toggles.
  - Real-time sliders driven by Wren code parameters for the selected track.

- **Sample-Exact WebAudio Hardware Timing Scheduler**:
  - 100% zero-jitter rhythm playback built on WebAudio `AudioContext.currentTime` hardware clock.

- **Multi-Channel Mixer & WAV Exporter**:
  - Dedicated console strips, stereo peak VU meters, and 16-bit PCM WAV song exporter.

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
flutter build web --pwa-strategy=none
```

---

## 📄 License
MIT License
