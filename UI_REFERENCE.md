# BLT Vibe - UI Reference Guide

## Application Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  BLT Vibe - Live Streaming                                   [_][□][X]  │
├─────────────────────────────────────────────────────────────────┤
│  📊 Audio Input  |  🔊 Streaming  |  🎵 Metadata  |              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─ Audio Input Device ──────────────────────────────────────┐  │
│  │ Device:              [Dropdown ▼ USB Mixer]              │  │
│  │ Sample Rate (Hz):    [44100]                             │  │
│  │ Channels:           [2]                                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─ Audio Levels ────────────────────────────────────────────┐  │
│  │ Input Level:                                              │  │
│  │ [████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 45%      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  [▶ Start Streaming] [⏹ Stop Streaming] [⭕ Record] [⚙ Settings] │
│                                                                   │
├─────────────────────────────────────────────────────────────────┤
│  🔴 STREAMING | Connected to: shoutcast.example.com:8000       │
└─────────────────────────────────────────────────────────────────┘
```

## Tab 1: Audio Input

**Shows:**
- Available audio devices (USB mixers, microphones)
- Sample rate selection (8000-96000 Hz)
- Channel count (mono, stereo, surround)
- Real-time audio level meter with visual bar
- Peak level indicator

**Color Scheme:**
- Level bar: Green (0-70%), Yellow (70-90%), Red (90-100%)
- Background: Light gray (#f0f0f0)
- Text: Dark gray (#333)

## Tab 2: Streaming Configuration

**Shows:**

### Shoutcast Server
```
┌─ Shoutcast Server ────────────────────────────┐
│ Host:        [stream.example.com           ] │
│ Port:        [8000                        ] │
│ Password:    [••••••••••••••••••          ] │
│ Mount Point: [/stream                     ] │
│ Status:      [✓ Enable Shoutcast]         │
└───────────────────────────────────────────────┘
```

### Icecast Server
```
┌─ Icecast Server ──────────────────────────────┐
│ Host:        [icecast.example.com         ] │
│ Port:        [8000                        ] │
│ Password:    [••••••••••••••••••          ] │
│ Mount Point: [/stream                     ] │
│ Status:      [✓ Enable Icecast]           │
└───────────────────────────────────────────────┘
```

### Encoding
```
┌─ Encoding ────────────────────────────────────┐
│ Bitrate:     [128 ▾] kbps                    │
│ Codec:       [MP3 ▾]                         │
│              Options: MP3, OGG Vorbis        │
└───────────────────────────────────────────────┘
```

## Tab 3: Metadata Display

**Shows:**

### Metadata Source
```
┌─ Metadata Source ──────────────────────────────┐
│ Source:      [PlayIt Live ▾]                  │
│              Options:                         │
│              - PlayIt Live                    │
│              - Virtual DJ                     │
│              - Manual Entry                   │
│ API URL:     [http://localhost:7601/      ] │
└────────────────────────────────────────────────┘
```

### Currently Playing
```
┌─ Currently Playing ────────────────────────────┐
│ Artist:      [The Beatles              ] ✓ │
│ Title:       [Let It Be                 ] ✓ │
│ On Air:      [John Smith                ] ✓ │
└────────────────────────────────────────────────┘
```

### Manual Entry
```
┌─ Manual Entry ─────────────────────────────────┐
│ Artist:      [_____________________________] │
│ Title:       [_____________________________] │
│ On Air:      [_____________________________] │
│             [Update Metadata]                 │
└────────────────────────────────────────────────┘
```

## Control Buttons

### Start Streaming
- **Color:** Green (#4CAF50)
- **Text:** "▶ Start Streaming"
- **Action:** Initialize audio, connect to servers, start streaming

### Stop Streaming
- **Color:** Red (#f44336)
- **Text:** "⏹ Stop Streaming"
- **Action:** Stop audio capture, disconnect from servers
- **Disabled** when not streaming

### Record
- **Color:** Orange (#FF5722) inactive, Green (#4CAF50) active
- **Text:** "⭕ Record" or "⏹ Stop Recording"
- **Action:** Toggle local file recording
- **Requires:** Active streaming

### Settings
- **Color:** Gray (#999)
- **Text:** "⚙ Settings"
- **Action:** Open settings dialog

## Status Bar

**Bottom of window shows:**
- 🔴 **STREAMING** - Red indicator when streaming
- ⚪ **Ready** - Gray indicator when idle
- Connection status and server address
- Bitrate and codec information

## Color Palette

```
Primary Green:    #4CAF50  (Start, Active states)
Error Red:        #f44336  (Stop, Errors)
Warning Orange:   #FF5722  (Recording)
Neutral Gray:     #999     (Disabled, Secondary)
Background:       #f0f0f0  (Main window)
Dark Text:        #333     (Primary text)
Light Border:     #ddd     (Separators)
Input White:      #ffffff  (Text fields)
```

## Typography

- **Font:** Segoe UI, Arial, sans-serif
- **Title:** 14pt bold
- **Labels:** 11pt regular
- **Input:** 11pt regular
- **Status:** 10pt mono (for technical info)

## Responsive Elements

1. **Tabs** - Easy navigation between three main sections
2. **GroupBoxes** - Organize related settings
3. **Forms** - Consistent label + input layout
4. **Progress Bars** - Real-time visual feedback
5. **Status Messages** - Clear error/success indicators

## User Flow

```
1. SELECT AUDIO DEVICE
   ↓
2. CONFIGURE SERVERS (Shoutcast/Icecast)
   ↓
3. SELECT METADATA SOURCE
   ↓
4. CLICK "START STREAMING"
   ↓
5. MONITOR AUDIO LEVELS
   ↓
6. UPDATE METADATA (Auto or Manual)
   ↓
7. OPTIONALLY RECORD
   ↓
8. CLICK "STOP STREAMING"
```

## Error States

**Connection Failed:**
- ❌ Red status indicator
- Error dialog with connection details
- Suggestion to check credentials
- Log entry for debugging

**Audio Device Error:**
- Cannot start streaming
- Message suggests driver update
- List available devices for retry

**Invalid Metadata Source:**
- Warning icon next to API URL
- Automatic retry with exponential backoff
- Falls back to manual entry

---

This reference guide shows the complete UI layout and visual design for BLT Vibe!
