import 'dart:async';

import 'package:record/record.dart';

import '../models/audio_level.dart';

/// Wraps the [AudioRecorder] from the `record` package.
///
/// Responsibilities:
///  - Requesting microphone permission.
///  - Providing a continuous stream of [AudioLevel] values for the VU meter.
///  - Providing a [Stream<List<int>>] of raw PCM bytes for live streaming.
///  - Recording audio to a file on disk.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  final _levelController = StreamController<AudioLevel>.broadcast();
  Timer? _levelTimer;

  bool _isMonitoring = false;
  bool _isStreaming = false;
  bool _isRecording = false;

  Stream<AudioLevel> get levelStream => _levelController.stream;
  bool get isMonitoring => _isMonitoring;
  bool get isStreaming => _isStreaming;
  bool get isRecording => _isRecording;

  // ──────────────────────────────────────────────────────────────────────────
  // Permissions
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns true if the app has microphone permission.
  Future<bool> hasMicrophonePermission() async {
    return _recorder.hasPermission();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Level monitoring (VU meter)
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts polling the microphone amplitude at ~10 Hz.
  ///
  /// Starts a silent recording in the background so that amplitude values
  /// are available without writing a permanent file.
  Future<void> startMonitoring() async {
    if (_isMonitoring || _isStreaming || _isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    // Start a low-overhead in-memory stream (we discard the data here)
    await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 44100,
      numChannels: 1,
    ));

    _isMonitoring = true;
    _startLevelPolling();
  }

  /// Stops the VU meter polling.
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;
    _stopLevelPolling();
    await _recorder.stop();
    _isMonitoring = false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Live streaming
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts the microphone and returns a [Stream<List<int>>] of raw PCM16 bytes.
  ///
  /// The caller (e.g. [StreamerProvider]) is responsible for encoding and
  /// forwarding the data to the streaming server.
  Future<Stream<List<int>>?> startStream() async {
    if (_isStreaming || _isRecording) return null;
    if (_isMonitoring) await stopMonitoring();

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    final audioStream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 44100,
      numChannels: 2,
    ));

    _isStreaming = true;
    _startLevelPolling();
    return audioStream;
  }

  /// Stops live streaming.
  Future<void> stopStream() async {
    if (!_isStreaming) return;
    _stopLevelPolling();
    await _recorder.stop();
    _isStreaming = false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File recording
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts recording audio to [filePath].
  Future<void> startRecording(String filePath) async {
    if (_isRecording) return;
    if (_isMonitoring) await stopMonitoring();
    if (_isStreaming) {
      // Recording can run alongside streaming; restart with file output
      await _recorder.stop();
      _isStreaming = false;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 2,
        bitRate: 128000,
      ),
      path: filePath,
    );

    _isRecording = true;
    _startLevelPolling();
  }

  /// Stops recording and returns the path of the saved file.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _stopLevelPolling();
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────────────────

  void _startLevelPolling() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        final amp = await _recorder.getAmplitude();
        // amp.current is in dBFS (typically –160 to 0).  Normalise to 0–1.
        final normalised = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        _levelController.add(
          AudioLevel(level: normalised, timestamp: DateTime.now()),
        );
      } catch (_) {}
    });
  }

  void _stopLevelPolling() {
    _levelTimer?.cancel();
    _levelTimer = null;
    _levelController.add(AudioLevel(level: 0, timestamp: DateTime.now()));
  }

  /// Releases all resources.
  Future<void> dispose() async {
    _stopLevelPolling();
    await _levelController.close();
    await _recorder.dispose();
  }
}
