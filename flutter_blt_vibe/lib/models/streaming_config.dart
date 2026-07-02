/// Configuration for a single streaming server (Shoutcast or Icecast).
class ServerConfig {
  bool enabled;
  String host;
  int port;
  String password;
  String mountPoint;
  int bitrate;
  String codec;

  ServerConfig({
    this.enabled = false,
    this.host = '',
    this.port = 8000,
    this.password = '',
    this.mountPoint = '/stream',
    this.bitrate = 128,
    this.codec = 'mp3',
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'host': host,
        'port': port,
        'password': password,
        'mount_point': mountPoint,
        'bitrate': bitrate,
        'codec': codec,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        enabled: (json['enabled'] as bool?) ?? false,
        host: (json['host'] as String?) ?? '',
        port: (json['port'] as int?) ?? 8000,
        password: (json['password'] as String?) ?? '',
        mountPoint: (json['mount_point'] as String?) ?? '/stream',
        bitrate: (json['bitrate'] as int?) ?? 128,
        codec: (json['codec'] as String?) ?? 'mp3',
      );

  ServerConfig copyWith({
    bool? enabled,
    String? host,
    int? port,
    String? password,
    String? mountPoint,
    int? bitrate,
    String? codec,
  }) =>
      ServerConfig(
        enabled: enabled ?? this.enabled,
        host: host ?? this.host,
        port: port ?? this.port,
        password: password ?? this.password,
        mountPoint: mountPoint ?? this.mountPoint,
        bitrate: bitrate ?? this.bitrate,
        codec: codec ?? this.codec,
      );
}

/// Combined configuration for both streaming targets and audio settings.
class StreamingConfig {
  ServerConfig shoutcast;
  ServerConfig icecast;
  int sampleRate;
  int channels;

  StreamingConfig({
    ServerConfig? shoutcast,
    ServerConfig? icecast,
    this.sampleRate = 44100,
    this.channels = 2,
  })  : shoutcast = shoutcast ?? ServerConfig(enabled: true, port: 8000),
        icecast = icecast ?? ServerConfig(port: 8000);

  Map<String, dynamic> toJson() => {
        'shoutcast': shoutcast.toJson(),
        'icecast': icecast.toJson(),
        'sample_rate': sampleRate,
        'channels': channels,
      };

  factory StreamingConfig.fromJson(Map<String, dynamic> json) =>
      StreamingConfig(
        shoutcast: json['shoutcast'] != null
            ? ServerConfig.fromJson(json['shoutcast'] as Map<String, dynamic>)
            : null,
        icecast: json['icecast'] != null
            ? ServerConfig.fromJson(json['icecast'] as Map<String, dynamic>)
            : null,
        sampleRate: (json['sample_rate'] as int?) ?? 44100,
        channels: (json['channels'] as int?) ?? 2,
      );
}
