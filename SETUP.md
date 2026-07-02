# BLT Vibe - Windows Setup Guide

Complete installation and setup instructions for BLT Vibe on Windows 10/11.

## Prerequisites

- Windows 10 or Windows 11
- Python 3.9 or later
- Git (optional, for cloning)
- Administrator access (for some drivers)

## Step 1: Install Python

1. Download Python 3.11 from https://www.python.org/downloads/
2. Run the installer
3. **IMPORTANT**: Check "Add Python to PATH"
4. Click "Install Now"
5. Verify installation:
   ```bash
   python --version
   ```

## Step 2: Clone or Download BLT Vibe

**Option A: Using Git**
```bash
git clone https://github.com/nickyprice/blt-vibe.git
cd blt-vibe
```

**Option B: Download ZIP**
1. Go to https://github.com/nickyprice/blt-vibe
2. Click "Code" → "Download ZIP"
3. Extract to a folder
4. Open Command Prompt in that folder

## Step 3: Create Virtual Environment

```bash
python -m venv venv
```

Activate it:
```bash
.\venv\Scripts\activate
```

You should see `(venv)` at the start of your command line.

## Step 4: Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

This will install:
- PyQt6 (GUI framework)
- PyAudio (audio input)
- NumPy (audio processing)
- Requests (API calls)
- And other required libraries

## Step 5: Install Audio Drivers

For USB audio input to work, you may need:

**For USB Mixers:**
1. Download the latest driver from your mixer manufacturer
2. Install the driver
3. Restart your computer

**Common USB Audio Interfaces:**
- Behringer: https://www.behringer.com/support
- Focusrite: https://focusrite.com/support
- Turtle Beach: https://www.turtlebeach.com/support

## Step 6: Run BLT Vibe

```bash
python main.py
```

The application window should open!

## Configuration

### Shoutcast Server

1. Get your Shoutcast credentials from your provider
2. In BLT Vibe, go to "Streaming" tab
3. Enter:
   - **Host**: Your Shoutcast server address
   - **Port**: Usually 8000
   - **Mount**: e.g., `/stream`
   - **Password**: Your admin password
4. Check "Enable Shoutcast"

### Icecast Server

1. Get your Icecast credentials
2. Go to "Streaming" tab
3. Enter:
   - **Host**: Your Icecast server address
   - **Port**: Usually 8000
   - **Mount**: e.g., `/stream`
   - **Password**: Your source password
4. Check "Enable Icecast"

### PlayIt Live Metadata

1. Open PlayIt Live on the same computer
2. In BLT Vibe, go to "Metadata" tab
3. Select "PlayIt Live" from dropdown
4. Verify API URL: `http://localhost:7601/`
5. BLT Vibe will now auto-update metadata from PlayIt Live

### Virtual DJ Metadata

1. Open Virtual DJ
2. In BLT Vibe, go to "Metadata" tab
3. Select "Virtual DJ" from dropdown
4. Verify API URL: `http://localhost:8099/`
5. BLT Vibe will auto-update metadata from Virtual DJ

## Troubleshooting

### No Audio Devices Found
- **Solution**: Install USB audio driver for your mixer/microphone
- Check Device Manager (Right-click Start → Device Manager)
- Look for "Unknown Device" or "Other Devices"

### Python Not Found
- **Solution**: Reinstall Python and check "Add Python to PATH"
- Or use full path: `C:\Python311\python.exe main.py`

### PyAudio Installation Fails
- **Solution**: Install Microsoft Visual C++ Build Tools
  - Download: https://visualstudio.microsoft.com/visual-cpp-build-tools/
  - Install "Desktop development with C++"

### Connection to Shoutcast/Icecast Fails
- **Solution**: 
  - Verify server credentials are correct
  - Check server is running and accessible
  - Verify firewall isn't blocking port 8000
  - Test with: `ping your-server.com`

### API Connection to PlayIt Live/Virtual DJ Fails
- **Solution**:
  - Verify the application is running
  - Check the API URL is correct
  - Try opening the URL in a browser
  - Look at `blt_vibe.log` for errors

## Logs

Application logs are saved to `blt_vibe.log` in the same directory.

Check here for detailed error messages:
```bash
notepad blt_vibe.log
```

## Getting Help

1. Check `blt_vibe.log` for error messages
2. Verify all credentials and URLs
3. Test each component separately
4. Open an issue on GitHub with:
   - Your error message
   - Steps to reproduce
   - Contents of `blt_vibe.log`

## Next Steps

1. Configure your streaming server
2. Test audio input with level meter
3. Connect to metadata source
4. Start streaming!

---

**Happy streaming! 🎙️**
