# BLT Vibe – Flutter Mobile App

Mobile companion to the **BLT Vibe** desktop streaming client.  
Streams live audio from your phone's microphone to **Shoutcast** and **Icecast** servers without going through any app store.

---

## Features

| Feature | Detail |
|---|---|
| 🎙 Audio level meter | Real-time colour-coded VU meter (green → orange → red) |
| 📻 Shoutcast streaming | Raw TCP source connection (Shoutcast v1 protocol) |
| 🌊 Icecast streaming | HTTP PUT source connection with chunked transfer |
| 🎵 Metadata | Push artist/title/on-air name to servers in real time |
| ⏺ Recording | Save WAV recordings to device storage |
| 🌙 Dark mode | Follows system dark/light preference |
| 📱 Responsive | Phones and tablets (portrait + landscape) |

---

## Requirements

| Tool | Minimum version |
|---|---|
| Flutter | 3.10+ |
| Dart SDK | 3.0+ |
| Android | API 21 (Android 5.0) |
| iOS | 12.0 |

---

## Getting Started

### 1. Install Flutter

Follow the official guide: <https://docs.flutter.dev/get-started/install>

### 2. Get dependencies

```bash
cd flutter_blt_vibe
flutter pub get
```

### 3. Run on a connected device / emulator

```bash
flutter run
```

---

## Building for Distribution

### Android APK (direct install – no Play Store needed)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Share `app-release.apk` with your radio group via email, WhatsApp, or
GitHub Releases.  Recipients must enable **"Install from unknown sources"**
in Android settings.

### iOS IPA (Ad Hoc – no App Store needed)

> **Requires** an Apple Developer account (free or paid).
> With a **free account** you can sideload to up to 3 devices you've
> registered via Xcode.  A **paid account** ($99/year) lets you distribute
> to up to 100 devices via Ad Hoc provisioning.

```bash
flutter build ipa --release
# Output: build/ios/ipa/*.ipa
```

Distribute via AltStore, Sideloadly, or Apple Configurator 2.

---

## Project Structure

```
flutter_blt_vibe/
├── lib/
│   ├── main.dart                  # App entry point, providers, routing
│   ├── models/
│   │   ├── audio_level.dart       # AudioLevel value object
│   │   ├── metadata.dart          # Song metadata model
│   │   └── streaming_config.dart  # Server + audio configuration
│   ├── providers/
│   │   ├── audio_provider.dart    # Microphone permission + level stream
│   │   ├── metadata_provider.dart # Metadata state + server push
│   │   └── streamer_provider.dart # Streaming orchestration + recording
│   ├── screens/
│   │   ├── home_screen.dart       # VU meter, status, control buttons
│   │   ├── settings_screen.dart   # Server configuration forms
│   │   └── metadata_screen.dart   # Artist/title/on-air input
│   ├── services/
│   │   ├── audio_service.dart     # Microphone capture via `record`
│   │   └── streaming_service.dart # TCP socket streaming + metadata HTTP
│   └── widgets/
│       ├── control_buttons.dart   # Start / Stop / Record buttons
│       ├── level_meter.dart       # Colour-coded LinearProgressIndicator
│       └── status_display.dart    # Live / connecting / error banner
├── android/                       # Android platform project
├── ios/                           # iOS platform project
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Key Packages

| Package | Purpose |
|---|---|
| `provider` | Reactive state management |
| `record` | Microphone capture + amplitude monitoring |
| `http` | Metadata HTTP requests |
| `shared_preferences` | Persistent server settings |
| `permission_handler` | Runtime microphone permission |
| `path_provider` | Device file-system paths |

---

## Audio Streaming Notes

The app sends **raw PCM-16 audio** over the TCP socket connection.  Most
Shoutcast / Icecast servers expect **MP3** encoded audio.  For full
production use you have two options:

1. **Server-side transcoding** – configure your Icecast server with a
   transcoding mount that accepts PCM and re-encodes to MP3.
2. **On-device encoding** – add a native MP3 encoder via a platform
   channel or a future Dart FFI package.  The `StreamingService` is
   designed to accept any `List<int>` byte stream so swapping the
   audio format requires only a change in `audio_service.dart`.

---

## Permissions

### Android
- `RECORD_AUDIO` – microphone capture
- `INTERNET` – streaming / metadata updates
- `WAKE_LOCK` + `FOREGROUND_SERVICE` – keep streaming while screen is off

### iOS
- `NSMicrophoneUsageDescription` – microphone
- `UIBackgroundModes: audio` – continue streaming in background
- `NSAllowsArbitraryLoads` – allow HTTP to streaming servers
