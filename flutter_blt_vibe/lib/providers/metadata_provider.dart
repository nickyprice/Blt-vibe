import 'package:flutter/foundation.dart';

import '../models/metadata.dart';
import '../services/streaming_service.dart';
import '../models/streaming_config.dart';

/// Manages now-playing metadata and pushes updates to streaming servers.
class MetadataProvider extends ChangeNotifier {
  final StreamingService _streamingService;

  Metadata _metadata = Metadata();
  bool _isUpdating = false;
  String? _lastError;
  DateTime? _lastUpdated;

  MetadataProvider(this._streamingService);

  Metadata get metadata => _metadata;
  bool get isUpdating => _isUpdating;
  String? get lastError => _lastError;
  DateTime? get lastUpdated => _lastUpdated;

  void setArtist(String value) {
    _metadata.artist = value;
    notifyListeners();
  }

  void setTitle(String value) {
    _metadata.title = value;
    notifyListeners();
  }

  void setOnAirName(String value) {
    _metadata.onAirName = value;
    notifyListeners();
  }

  /// Pushes the current metadata to all enabled and connected servers.
  Future<void> updateMetadata(StreamingConfig config) async {
    _isUpdating = true;
    _lastError = null;
    notifyListeners();

    final errors = <String>[];

    if (config.shoutcast.enabled && _streamingService.shoutcastConnected) {
      final ok = await _streamingService.updateShoutcastMetadata(
        config.shoutcast,
        _metadata,
      );
      if (!ok) errors.add('Shoutcast metadata update failed');
    }

    if (config.icecast.enabled && _streamingService.icecastConnected) {
      final ok = await _streamingService.updateIcecastMetadata(
        config.icecast,
        _metadata,
      );
      if (!ok) errors.add('Icecast metadata update failed');
    }

    _isUpdating = false;
    _lastUpdated = DateTime.now();
    _lastError = errors.isNotEmpty ? errors.join('; ') : null;
    notifyListeners();
  }
}
