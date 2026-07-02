# BLT Vibe - Mobile & Desktop Strategy Guide

## Platform Overview

### Current Status
✅ **Desktop (Windows/macOS/Linux)** - Complete with PyQt6
⏳ **Mobile (iOS/Android)** - Planning phase

---

## Option 1: Native Mobile Apps (RECOMMENDED FOR YOUR USE CASE)

### Why Native for BLT Vibe?
- **Audio Processing**: iOS and Android have specialized audio frameworks
- **Stream Quality**: Better control over hardware acceleration
- **Battery Optimization**: Native audio APIs use less power
- **Bluetooth/WiFi**: Direct access to hardware for quality control
- **Background Streaming**: Native background task support

### iOS Native (Swift)

**Pros:**
- Best performance for audio streaming
- Direct access to AirPlay, Bluetooth
- Best security model for passwords
- Native UI matches user expectations

**Stack:**
- **Language**: Swift
- **Audio Framework**: AVAudioEngine, AudioToolbox
- **Networking**: URLSession (native HTTP)
- **UI**: SwiftUI
- **IDE**: Xcode

**Timeline:** 4-6 weeks for feature-parity with desktop
**Cost:** ~$99/year Apple Developer Program

**Key Libraries:**
```swift
import AVFoundation
import Network
import AudioToolbox
```

### Android Native (Kotlin)

**Pros:**
- Best for Android-specific features
- Better integration with Android Audio System
- Native Bluetooth/WiFi management
- Excellent media controls

**Stack:**
- **Language**: Kotlin
- **Audio Framework**: AudioTrack, Oboe
- **Networking**: OkHttp, Retrofit
- **UI**: Jetpack Compose
- **IDE**: Android Studio

**Timeline:** 4-6 weeks for feature-parity
**Cost:** Free (one-time $25 Google Play registration)

**Key Libraries:**
```kotlin
import android.media.AudioTrack
import okhttp3.OkHttpClient
import androidx.compose.ui.*
```

---

## Option 2: Cross-Platform Framework (FASTER DEVELOPMENT)

### Flutter (RECOMMENDED FOR SPEED)

**Why Flutter for BLT Vibe?**
- Single codebase for iOS + Android
- 80% code sharing
- Excellent audio support via plugins
- Beautiful UI out of the box
- Hot reload for fast development

**Stack:**
- **Language**: Dart
- **Audio**: just_audio, audio_session plugins
- **Networking**: http, dio packages
- **UI**: Material Design + Cupertino (iOS style)
- **IDE**: VS Code or Android Studio

**Timeline:** 2-3 weeks for full implementation
**Cost:** Free

**Architecture:**
```
lib/
├── main.dart
├── models/
│   ├── streaming.dart
│   ├── audio.dart
│   └── metadata.dart
├── providers/
│   ├── streamer_provider.dart
│   ├── audio_provider.dart
│   └── metadata_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   └── metadata_screen.dart
└── widgets/
    ├── audio_level_meter.dart
    ├── streaming_controls.dart
    └── metadata_display.dart
```

**Key Packages:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  just_audio: ^0.9.0
  audio_session: ^0.1.0
  http: ^1.1.0
  provider: ^6.0.0
  cupertino_icons: ^1.0.0
```

**Code Example:**
```dart
class StreamingProvider extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  StreamingConnection? _connection;
  
  Future<void> connectShoutcast(
    String host,
    int port,
    String password,
    String mount,
  ) async {
    try {
      _connection = StreamingConnection(
        host: host,
        port: port,
        password: password,
        mount: mount,
      );
      await _connection!.connect();
      notifyListeners();
    } catch (e) {
      throw StreamingException('Failed to connect: $e');
    }
  }
  
  Future<void> sendAudio(Uint8List audioData) async {
    await _connection?.sendAudio(audioData);
  }
}
```

### React Native (ALTERNATIVE)

**Pros:**
- JavaScript/TypeScript ecosystem
- Good performance for streaming
- Reusable code between web and mobile
- Large community

**Cons:**
- Slightly more complex audio setup
- Bridge overhead for real-time audio
- Not ideal for low-latency streaming

**Timeline:** 3-4 weeks

---

## Option 3: Web App + Progressive Web App (PWA)

### React + Tauri (Best of Both Worlds)

**Why?**
- Single React codebase
- Runs as desktop app (Tauri) or web app
- Smaller bundle than Electron
- Native performance
- Mobile-responsive UI

**Stack:**
```
Frontend: React + TypeScript
Desktop: Tauri (Rust backend)
Mobile: React Native or Flutter wrap
UI: Tailwind CSS
Audio: Web Audio API
```

**Timeline:** 3-4 weeks desktop, +2 weeks mobile wrapper

---

## Recommendation for BLT Vibe

### Phase 1: Desktop ✅ (DONE)
- Windows/macOS/Linux with PyQt6

### Phase 2: Cross-Platform Mobile (RECOMMENDED)
**Use Flutter** for iOS + Android
- **Timeline:** 2-3 weeks
- **Shared Logic:** Extract Python core as REST API or gRPC service
- **Benefits:** Single team, rapid development, shared UI patterns

### Phase 3: Web App (OPTIONAL)
- React-based control panel
- Remote streaming management
- Browser-based monitoring

---

## Architecture Comparison

### Current: Desktop-Only
```
User → PyQt6 GUI → Python Backend → Shoutcast/Icecast
                  ↓
                Audio Device
```

### Recommended: Desktop + Mobile
```
                    ┌─── PyQt6 GUI ────┐
                    │                  ↓
Shoutcast/Icecast ←─┤─── Python Core ──┤
                    │                  ↑
                    └─ Flutter App ────┘
                         (iOS/Android)
```

### Best: API-Driven (Scalable)
```
                    ┌─── PyQt6 GUI ─────┐
                    │                   ↓
Shoutcast/Icecast ←─┤─ REST API ────── Python Worker
                    │   (FastAPI)       (Streaming Engine)
                    ├─ Flutter App ─────┤
                    │                   ↓
                    └─ React Web ───────┘
                         (Browser)
```

---

## Implementation Steps

### For Flutter Approach:

**Week 1:**
```
Day 1-2: Setup Flutter project structure
Day 3-4: Create streaming module (Dart wrapper for HTTP)
Day 5: Audio input/level meter UI
```

**Week 2:**
```
Day 1-2: Metadata provider (PlayIt Live API integration)
Day 3-4: Streaming controls UI
Day 5: Testing and refinement
```

**Week 3:**
```
Day 1-2: Settings/configuration screen
Day 3: Platform-specific audio handling (iOS/Android)
Day 4-5: Packaging and app store prep
```

### For Native Approach:

**iOS (Swift):**
```
Week 1: Core streaming engine with AVAudioEngine
Week 2: UI with SwiftUI
Week 3: Testing, optimization, App Store submission
```

**Android (Kotlin):**
```
Week 1: Core streaming with AudioTrack
Week 2: UI with Jetpack Compose
Week 3: Testing, optimization, Play Store submission
```

---

## Cost Comparison

| Option | Development | Publishing | Maintenance |
|--------|-------------|-----------|------------|
| Flutter (iOS+Android) | $5-8K | $25/year | Low |
| Native iOS | $8-10K | $99/year | Medium |
| Native Android | $5-7K | $25 (one-time) | Medium |
| Native Both | $13-17K | $124/year | High |
| Web + Desktop | $6-9K | $0-100/year | Low |

---

## Recommended Path Forward

### For BLT Vibe:

1. **Keep Desktop** (PyQt6) - Already working ✅
2. **Add Flutter Mobile** (2-3 weeks)
   - iOS + Android from single codebase
   - Touch-optimized UI for mobile
   - Same features as desktop
3. **Optional: Add Web** (1-2 weeks later)
   - Browser-based control panel
   - Remote monitoring dashboard

**Total Investment:** 3-4 weeks development + $25/year

---

## Example Flutter Implementation

### lib/services/streaming_service.dart
```dart
class StreamingService {
  final http.Client _httpClient = http.Client();
  StreamSocket? _socket;
  
  Future<bool> connectShoutcast({
    required String host,
    required int port,
    required String password,
    required String mount,
  }) async {
    try {
      final socket = await Socket.connect(host, port);
      _socket = StreamSocket(socket);
      
      final auth = base64.encode(utf8.encode('source:$password'));
      final header = 
        'PUT $mount HTTP/1.0\r\n'
        'Authorization: Basic $auth\r\n'
        'Content-Type: audio/mpeg\r\n'
        'Connection: close\r\n\r\n';
      
      _socket!.write(header);
      return await _socket!.waitForResponse();
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }
  
  Future<void> sendAudio(Uint8List data) async {
    await _socket?.write(String.fromCharCodes(data));
  }
}
```

### lib/screens/home_screen.dart
```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StreamingProvider _streamingProvider;
  
  @override
  void initState() {
    super.initState();
    _streamingProvider = Provider.of<StreamingProvider>(context, listen: false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<StreamingProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            AudioLevelMeter(level: provider.audioLevel),
            StreamingControls(
              isStreaming: provider.isStreaming,
              onStart: () => _startStreaming(),
              onStop: () => _stopStreaming(),
            ),
            MetadataDisplay(
              artist: provider.currentArtist,
              title: provider.currentTitle,
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _startStreaming() async {
    await _streamingProvider.connect();
  }
  
  Future<void> _stopStreaming() async {
    await _streamingProvider.disconnect();
  }
}
```

---

## Next Steps

1. **Decide:** Native (more control) vs Flutter (faster development)
2. **Setup:** Create new project in chosen framework
3. **Reuse:** Extract common logic into shared module
4. **Test:** Cross-platform compatibility testing
5. **Deploy:** App Store & Play Store submission

Would you like me to start with the Flutter implementation?

---

## Resources

- **Flutter Audio:** https://pub.dev/packages/just_audio
- **Swift Audio:** https://developer.apple.com/documentation/avfoundation
- **Kotlin Audio:** https://developer.android.com/guide/topics/media-apps/audio-routing
- **Web Audio:** https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
