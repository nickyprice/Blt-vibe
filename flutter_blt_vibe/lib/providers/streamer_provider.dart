import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/streaming_config.dart';
import '../services/streaming_service.dart';
import '../services/audio_service.dart';

enum StreamingState { idle, connecting, streaming, error }

/// Orchestrates audio capture and network streaming.
///
/// This provider:
///  - Persists [StreamingConfig] to [SharedPreferences].
///  - Starts/stops connections to Shoutcast and Icecast servers.
///  - Pipes raw PCM bytes from [AudioService] to [StreamingService].
///  - Manages recording sessions.
class StreamerProvider extends ChangeNotifier {
  final StreamingService _streamingService;
  final AudioService _audioService;

  StreamingConfig _config = StreamingConfig();
  StreamingState _state = StreamingState.idle;
  bool _isRecording = false;
  String? _recordingPath;
  String? _errorMessage;
  String? _statusMessage;

  StreamSubscription<List<int>>? _audioSub;

  StreamerProvider(this._streamingService, this._audioService) {
    _loadConfig();
  }

  StreamingConfig get config => _config;
  StreamingState get state => _state;
  bool get isStreaming => _state == StreamingState.streaming;
  bool get isConnecting => _state == StreamingState.connecting;
  bool get isRecording => _isRecording;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  StreamingService get streamingService => _streamingService;

  // ──────────────────────────────────────────────────────────────────────────
  // Config persistence
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('streaming_config');
      if (json != null) {
        _config = StreamingConfig.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('streaming_config', jsonEncode(_config.toJson()));
    } catch (_) {}
  }

  void updateShoutcastConfig(ServerConfig config) {
    _config.shoutcast = config;
    saveConfig();
    notifyListeners();
  }

  void updateIcecastConfig(ServerConfig config) {
    _config.icecast = config;
    saveConfig();
    notifyListeners();
  }

  void updateAudioConfig({int? sampleRate, int? channels}) {
    if (sampleRate != null) _config.sampleRate = sampleRate;
    if (channels != null) _config.channels = channels;
    saveConfig();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Streaming
  // ──────────────────────────────────────────────────────────────────────────

  /// Connects to enabled servers and starts streaming the microphone input.
  Future<void> startStreaming() async {
    if (_state != StreamingState.idle && _state != StreamingState.error) return;

    _state = StreamingState.connecting;
    _errorMessage = null;
    _statusMessage = 'Connecting…';
    notifyListeners();

    // Stop the passive level monitor so we can reclaim the microphone
    await _audioService.stopMonitoring();

    bool anyConnected = false;

    if (_config.shoutcast.enabled && _config.shoutcast.host.isNotEmpty) {
      final result = await _streamingService.connectShoutcast(_config.shoutcast);
      if (result == ConnectionResult.success) {
        anyConnected = true;
      } else {
        _errorMessage = 'Shoutcast connection failed';
      }
    }

    if (_config.icecast.enabled && _config.icecast.host.isNotEmpty) {
      final result = await _streamingService.connectIcecast(_config.icecast);
      if (result == ConnectionResult.success) {
        anyConnected = true;
      } else {
        final prev = _errorMessage;
        _errorMessage =
            prev != null ? '$prev; Icecast connection failed' : 'Icecast connection failed';
      }
    }

    if (!anyConnected) {
      _state = StreamingState.error;
      _statusMessage = null;
      // Restart level monitoring
      await _audioService.startMonitoring();
      notifyListeners();
      return;
    }

    // Start audio capture and pipe to streaming service
    final audioStream = await _audioService.startStream();
    if (audioStream == null) {
      await _streamingService.disconnect();
      _state = StreamingState.error;
      _errorMessage = 'Microphone not available';
      _statusMessage = null;
      notifyListeners();
      return;
    }

    _audioSub = audioStream.listen(
      (data) {
        if (_state == StreamingState.streaming) {
          _streamingService.sendAudioData(data);
        }
      },
      onError: (_) {
        if (_state == StreamingState.streaming) {
          stopStreaming();
        }
      },
      onDone: () {
        if (_state == StreamingState.streaming) {
          stopStreaming();
        }
      },
    );

    _state = StreamingState.streaming;
    _statusMessage = 'Live';
    notifyListeners();
  }

  /// Stops streaming and disconnects from all servers.
  Future<void> stopStreaming() async {
    if (_state == StreamingState.idle) return;

    await _audioSub?.cancel();
    _audioSub = null;

    await _audioService.stopStream();
    await _streamingService.disconnect();

    _state = StreamingState.idle;
    _statusMessage = null;
    notifyListeners();

    // Restart level monitoring
    await _audioService.startMonitoring();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Recording
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts recording audio to the app documents directory.
  Future<void> startRecording() async {
    if (_isRecording) return;
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/blt_vibe_rec_$timestamp.wav';
    await _audioService.startRecording(path);
    _recordingPath = path;
    _isRecording = true;
    notifyListeners();
  }

  /// Stops recording and returns the saved file path.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _audioService.stopRecording();
    _isRecording = false;
    _recordingPath = null;
    notifyListeners();
    return path;
  }

  String? get currentRecordingPath => _recordingPath;

  // ──────────────────────────────────────────────────────────────────────────
  // Teardown
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _audioSub?.cancel();
    // Fire-and-forget async cleanup; errors are intentionally swallowed here.
    _audioService.dispose().ignore();
    _streamingService.disconnect().ignore();
    super.dispose();
  }
}
