# BLT Vibe - Complete Build & Distribution Guide

## Overview

This guide covers building BLT Vibe for:
- **Windows** (.exe)
- **macOS** (.app)
- **Linux** (AppImage)
- **Android** (.apk)
- **iOS** (.ipa)

---

## Desktop Application (PyQt6)

### Prerequisites

**Windows, macOS, Linux:**
```bash
# Python 3.8+
python --version

# Install dependencies
pip install -r requirements.txt
pip install pyinstaller
```

### Testing Locally

**Run the app before building:**
```bash
python main.py
```

**Should see:**
- PyQt6 window with 3 tabs
- Audio Input tab with level meter
- Streaming tab with Shoutcast/Icecast config
- Metadata tab
- Control buttons (Start/Stop/Record)

---

## Building Executables

### Option 1: Automated Build Script (Recommended)

**Windows (Command Prompt):**
```bash
build.bat
```

**macOS / Linux:**
```bash
bash build.sh
```

**Output:** `dist/releases/`
- `blt-vibe-windows.exe` (50MB)
- `blt-vibe-macos.app` (70MB)
- `blt-vibe-linux` AppImage (80MB)

---

### Option 2: Manual Build (Per-Platform)

#### Windows

```bash
pyinstaller --onefile --icon=icon.ico --name="BLT Vibe" --add-data "config.example.json;." --add-data "core;core" main.py
mv "dist/BLT Vibe.exe" "blt-vibe-windows.exe"
```

#### macOS

```bash
pyinstaller --onefile --name="BLT Vibe" --osx-bundle-identifier="com.blt-vibe.app" --add-data "config.example.json:." --add-data "core:core" main.py
mv "dist/BLT Vibe.app" dist/blt-vibe.app
```

#### Linux

```bash
pyinstaller --onefile --name="BLT_Vibe" --add-data "config.example.json:." --add-data "core:core" main.py
chmod +x dist/BLT_Vibe
mv dist/BLT_Vibe dist/blt-vibe-linux
```

---

## Mobile Application (Flutter)

### Prerequisites

**Install Flutter:**
```bash
# Download from https://flutter.dev/docs/get-started/install
flutter --version
flutter doctor
```

### Testing

**Navigate to Flutter project:**
```bash
cd flutter_blt_vibe
flutter run
```

---

## Building Mobile Apps

### Android APK

**Build release APK:**
```bash
cd flutter_blt_vibe
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-app-release.apk`

**Installation:**
1. Download APK
2. Enable Unknown Sources in Settings
3. Install APK
4. Done!

---

### iOS IPA

**Build for iOS:**
```bash
cd flutter_blt_vibe
flutter build ios --release
```

**Generate IPA in Xcode:**
```bash
open ios/Runner.xcworkspace
# Product > Archive > Distribute App > Ad Hoc > Export
```

**Output:** `.ipa` file

---

## Distribution via GitHub Releases

**Create Release:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

**Upload files to:** https://github.com/nickyprice/blt-vibe/releases

**Share with radio group:**
```
https://github.com/nickyprice/blt-vibe/releases/download/v1.0.0/blt-vibe-windows.exe
https://github.com/nickyprice/blt-vibe/releases/download/v1.0.0/blt-vibe-1.0.0.apk
```

---

## System Requirements

### Desktop
- Windows 7+ / macOS 10.12+ / Ubuntu 16.04+
- 100-150MB free space
- USB audio device (optional)

### Mobile
- Android 5.0+ (API 21+)
- iOS 12.0+
- 100-120MB free space
- Microphone & Internet permissions

---

## Quick Reference

```bash
# Install dependencies
pip install -r requirements.txt
pip install pyinstaller

# Test desktop
python main.py

# Build desktop executables
bash build.sh

# Build mobile
cd flutter_blt_vibe
flutter build apk --release
flutter build ios --release
```

---

**BLT Vibe is ready for distribution!** 🚀
