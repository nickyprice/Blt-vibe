import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/streaming_config.dart';
import '../models/metadata.dart';

/// The result of a streaming connection attempt.
enum ConnectionResult { success, failed }

/// Handles low-level Shoutcast / Icecast connections.
///
/// Both protocols are source-client protocols that ride on top of a raw
/// TCP socket.  Once the handshake is complete, raw (or encoded) audio bytes
/// are written to the socket continuously.
///
/// Shoutcast v1:
///   SOURCE /mountPoint ICY/1.0\r\n
///   icy-password: <password>\r\n
///   icy-br: <bitrate>\r\n
///   ...
///
/// Icecast (HTTP PUT source):
///   PUT /mountPoint HTTP/1.0\r\n
///   Authorization: Basic <base64(source:password)>\r\n
///   Content-Type: audio/mpeg\r\n
///   ...
class StreamingService {
  Socket? _shoutcastSocket;
  Socket? _icecastSocket;

  bool _shoutcastConnected = false;
  bool _icecastConnected = false;

  bool get shoutcastConnected => _shoutcastConnected;
  bool get icecastConnected => _icecastConnected;
  bool get anyConnected => _shoutcastConnected || _icecastConnected;

  // ──────────────────────────────────────────────────────────────────────────
  // Shoutcast
  // ──────────────────────────────────────────────────────────────────────────

  /// Opens a Shoutcast v1 source connection.
  Future<ConnectionResult> connectShoutcast(ServerConfig config) async {
    try {
      final socket =
          await Socket.connect(config.host, config.port, timeout: const Duration(seconds: 10));

      // Send Shoutcast v1 handshake
      final handshake = StringBuffer()
        ..write('SOURCE ${config.mountPoint} ICY/1.0\r\n')
        ..write('icy-password: ${config.password}\r\n')
        ..write('icy-br: ${config.bitrate}\r\n')
        ..write('icy-genre: Radio\r\n')
        ..write('icy-name: BLT Vibe\r\n')
        ..write('icy-url: http://${config.host}:${config.port}\r\n')
        ..write('icy-pub: 0\r\n')
        ..write('content-type: audio/mpeg\r\n')
        ..write('\r\n');

      socket.write(handshake.toString());
      await socket.flush();

      // Wait briefly for server acknowledgement
      final completer = Completer<bool>();
      late StreamSubscription sub;
      sub = socket.listen(
        (data) {
          final response = String.fromCharCodes(data);
          if (response.contains('OK') || response.contains('200')) {
            if (!completer.isCompleted) completer.complete(true);
          } else {
            if (!completer.isCompleted) completer.complete(false);
          }
          sub.cancel();
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
          sub.cancel();
        },
      );

      // Some servers don't respond; treat silence as OK after 2 s
      final ok = await completer.future
          .timeout(const Duration(seconds: 2), onTimeout: () => true);

      if (ok) {
        _shoutcastSocket = socket;
        _shoutcastConnected = true;
        return ConnectionResult.success;
      } else {
        await socket.close();
        return ConnectionResult.failed;
      }
    } catch (e) {
      return ConnectionResult.failed;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Icecast
  // ──────────────────────────────────────────────────────────────────────────

  /// Opens an Icecast source connection using HTTP PUT.
  Future<ConnectionResult> connectIcecast(ServerConfig config) async {
    try {
      final socket =
          await Socket.connect(config.host, config.port, timeout: const Duration(seconds: 10));

      final credentials = base64Encode(utf8.encode('source:${config.password}'));

      final handshake = StringBuffer()
        ..write('PUT ${config.mountPoint} HTTP/1.0\r\n')
        ..write('Authorization: Basic $credentials\r\n')
        ..write('Content-Type: audio/mpeg\r\n')
        ..write('ice-name: BLT Vibe\r\n')
        ..write('ice-genre: Radio\r\n')
        ..write('ice-public: 0\r\n')
        ..write('ice-description: BLT Vibe Stream\r\n')
        ..write('ice-audio-info: bitrate=${config.bitrate}\r\n')
        ..write('icy-br: ${config.bitrate}\r\n')
        ..write('Transfer-Encoding: chunked\r\n')
        ..write('\r\n');

      socket.write(handshake.toString());
      await socket.flush();

      // Read server response
      final completer = Completer<bool>();
      late StreamSubscription sub;
      sub = socket.listen(
        (data) {
          final response = String.fromCharCodes(data);
          final accepted = response.contains('200') ||
              response.contains('HTTP/1.0 200') ||
              response.contains('HTTP/1.1 200');
          if (!completer.isCompleted) completer.complete(accepted);
          sub.cancel();
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
          sub.cancel();
        },
      );

      final ok = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);

      if (ok) {
        _icecastSocket = socket;
        _icecastConnected = true;
        return ConnectionResult.success;
      } else {
        await socket.close();
        return ConnectionResult.failed;
      }
    } catch (e) {
      return ConnectionResult.failed;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Audio data
  // ──────────────────────────────────────────────────────────────────────────

  /// Sends raw audio bytes to all connected servers.
  void sendAudioData(List<int> data) {
    if (_shoutcastConnected && _shoutcastSocket != null) {
      try {
        _shoutcastSocket!.add(data);
      } catch (_) {
        _shoutcastConnected = false;
      }
    }

    if (_icecastConnected && _icecastSocket != null) {
      try {
        // Icecast uses chunked transfer encoding
        final chunkHeader = '${data.length.toRadixString(16)}\r\n';
        _icecastSocket!.write(chunkHeader);
        _icecastSocket!.add(data);
        _icecastSocket!.write('\r\n');
      } catch (_) {
        _icecastConnected = false;
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Metadata
  // ──────────────────────────────────────────────────────────────────────────

  /// Updates the now-playing metadata on an Icecast server via HTTP GET.
  ///
  /// Endpoint: GET /admin/metadata?mount=<mount>&mode=updinfo&song=<song>
  Future<bool> updateIcecastMetadata(
    ServerConfig config,
    Metadata metadata,
  ) async {
    try {
      final song = Uri.encodeComponent(metadata.songString);
      final url = Uri.parse(
        'http://${config.host}:${config.port}/admin/metadata'
        '?mount=${config.mountPoint}&mode=updinfo&song=$song',
      );
      final credentials = base64Encode(utf8.encode('source:${config.password}'));
      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Updates the now-playing metadata on a Shoutcast v1 server via HTTP GET.
  ///
  /// Endpoint: GET /admin.cgi?pass=<password>&mode=updinfo&song=<song>
  Future<bool> updateShoutcastMetadata(
    ServerConfig config,
    Metadata metadata,
  ) async {
    try {
      final song = Uri.encodeComponent(metadata.songString);
      final url = Uri.parse(
        'http://${config.host}:${config.port}/admin.cgi'
        '?pass=${config.password}&mode=updinfo&song=$song',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Teardown
  // ──────────────────────────────────────────────────────────────────────────

  /// Disconnects from all servers.
  Future<void> disconnect() async {
    if (_shoutcastSocket != null) {
      try {
        await _shoutcastSocket!.close();
      } catch (_) {}
      _shoutcastSocket = null;
      _shoutcastConnected = false;
    }

    if (_icecastSocket != null) {
      try {
        // Send chunked terminator
        _icecastSocket!.write('0\r\n\r\n');
        await _icecastSocket!.flush();
        await _icecastSocket!.close();
      } catch (_) {}
      _icecastSocket = null;
      _icecastConnected = false;
    }
  }
}
