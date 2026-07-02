import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/audio_level.dart';
import '../services/audio_service.dart';

/// Exposes microphone state and real-time audio levels to the UI.
class AudioProvider extends ChangeNotifier {
  final AudioService _audioService;

  AudioLevel _currentLevel = AudioLevel(level: 0, timestamp: DateTime.now());
  bool _hasPermission = false;
  StreamSubscription<AudioLevel>? _levelSub;

  AudioProvider(this._audioService) {
    _init();
  }

  AudioLevel get currentLevel => _currentLevel;
  bool get hasPermission => _hasPermission;
  AudioService get service => _audioService;

  Future<void> _init() async {
    _hasPermission = await _audioService.hasMicrophonePermission();
    notifyListeners();

    _levelSub = _audioService.levelStream.listen((level) {
      _currentLevel = level;
      notifyListeners();
    });

    if (_hasPermission) {
      await _audioService.startMonitoring();
    }
  }

  /// Re-checks microphone permission and starts monitoring if granted.
  Future<void> requestPermission() async {
    _hasPermission = await _audioService.hasMicrophonePermission();
    notifyListeners();
    if (_hasPermission) {
      await _audioService.startMonitoring();
    }
  }

  @override
  void dispose() {
    _levelSub?.cancel();
    super.dispose();
  }
}
