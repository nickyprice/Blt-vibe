#!/bin/bash
# Build script for all platforms

echo "Building BLT Vibe for all platforms..."

# Install PyInstaller
pip install pyinstaller

# Create output directory
mkdir -p dist/releases

echo ""
echo "=== Building Windows executable ==="
pyinstaller --onefile \
  --icon=icon.ico \
  --name="BLT-Vibe-Windows" \
  --add-data="config.example.json:." \
  --add-data="core:core" \
  main.py

mv dist/BLT-Vibe-Windows.exe dist/releases/blt-vibe-windows.exe

echo ""
echo "=== Building macOS app ==="
pyinstaller --onefile \
  --name="BLT Vibe" \
  --osx-bundle-identifier="com.blt-vibe.app" \
  --add-data="config.example.json:." \
  --add-data="core:core" \
  main.py

mv dist/BLT\ Vibe.app dist/releases/blt-vibe.app

echo ""
echo "=== Building Linux AppImage ==="
pyinstaller --onefile \
  --name="BLT_Vibe" \
  --add-data="config.example.json:." \
  --add-data="core:core" \
  main.py

mv dist/BLT_Vibe dist/releases/blt-vibe-linux

echo ""
echo "Build complete!"
echo "Executables ready in: dist/releases/"
ls -lh dist/releases/
