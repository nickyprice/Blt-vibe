# BLT Vibe - Requirements and Dependencies

## Core Python Dependencies

```
PyQt6==6.7.0
pyaudio==0.2.13
numpy==1.24.3
requests==2.31.0
```

## Optional Audio Libraries

### For MP3 Encoding (Windows)
```
# Install LAME for MP3 support
# Download: https://lame.sourceforge.io/

# Windows: Copy libmp3lame.dll to System32 folder
# Or install via package manager:
pip install pydub
```

### For OGG/Vorbis Encoding
```
pip install pydub
```

### For Advanced Audio Processing
```
scipy==1.11.0
librosa==0.10.0
```

## Platform-Specific Installation

### Windows 10/11

#### 1. Python Installation
```bash
# Install Python 3.11
# Download from https://www.python.org/downloads/
# CHECK: "Add Python to PATH"

# Verify installation
python --version
```

#### 2. Visual C++ Build Tools
Required for PyAudio compilation:
```
# Download: https://visualstudio.microsoft.com/visual-cpp-build-tools/
# Install: "Desktop development with C++"
```

#### 3. Create Virtual Environment
```bash
python -m venv venv
.\venv\Scripts\activate
```

#### 4. Install Dependencies
```bash
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

#### 5. Install LAME (Optional, for MP3)
```
# Download: https://lame.sourceforge.io/download.php
# Extract and add libmp3lame.dll to System32:
# C:\Windows\System32\

# Or use Chocolatey:
choco install lame
```

### macOS

#### 1. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Audio Libraries
```bash
brew install portaudio
brew install lame
```

#### 3. Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
```

#### 4. Install Dependencies
```bash
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

### Linux (Ubuntu/Debian)

#### 1. Install Audio Libraries
```bash
sudo apt-get update
sudo apt-get install python3-dev
sudo apt-get install portaudio19-dev
sudo apt-get install libmp3lame-dev
```

#### 2. Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
```

#### 3. Install Dependencies
```bash
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

## Verify Installation

```bash
# Test Python packages
python -c "import PyQt6; print('PyQt6 OK')"
python -c "import pyaudio; print('PyAudio OK')"
python -c "import numpy; print('NumPy OK')"
python -c "import requests; print('Requests OK')"

# Test LAME (optional)
python -c "import ctypes; ctypes.CDLL('libmp3lame.dll'); print('LAME OK')"
```

## Troubleshooting

### PyAudio Installation Failed
**Solution:**
- Install Microsoft Visual C++ Build Tools
- Or use pre-built wheel: `pip install pipwin && pipwin install pyaudio`

### LAME Library Not Found
**Solution (Windows):**
- Download from https://lame.sourceforge.io/download.php
- Extract and copy `libmp3lame.dll` to `C:\Windows\System32\`
- Restart application

**Solution (macOS):**
```bash
brew install lame
```

**Solution (Linux):**
```bash
sudo apt-get install libmp3lame-dev
```

### PyQt6 Display Issues on Linux
```bash
sudo apt-get install libxkbcommon-x11-0
sudo apt-get install libdbus-1-3
```

### PortAudio Not Found
**Windows:** Usually included with PyAudio

**macOS:**
```bash
brew install portaudio
```

**Linux:**
```bash
sudo apt-get install portaudio19-dev
```

## Performance Optimization

For better streaming performance, install optional packages:

```bash
# C extensions for faster processing
pip install ujson

# Hardware acceleration
pip install numpy-mkl

# Optional media support
pip install moviepy
```

## Development Dependencies (Optional)

```bash
# For development and testing
pip install pytest
pip install black
pip install pylint
pip install pytest-cov
```

Install with:
```bash
pip install -r requirements-dev.txt
```

## Version Compatibility

- **Python:** 3.9, 3.10, 3.11 (Recommended), 3.12
- **Windows:** 10, 11
- **macOS:** 10.13+
- **Linux:** Ubuntu 18.04+, Debian 9+

## Next Steps

1. **Create virtual environment:** `python -m venv venv`
2. **Activate environment:** `.\venv\Scripts\activate` (Windows) or `source venv/bin/activate` (Mac/Linux)
3. **Install dependencies:** `pip install -r requirements.txt`
4. **Run application:** `python main.py`

---

For issues, check the logs in `blt_vibe.log` or refer to the GitHub issues page.
