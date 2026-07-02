/// Represents a single audio level reading (0.0 – 1.0).
class AudioLevel {
  final double level;
  final DateTime timestamp;

  const AudioLevel({required this.level, required this.timestamp});

  /// Clamps [level] to [0.0, 1.0].
  double get clamped => level.clamp(0.0, 1.0);

  /// Returns the level as a percentage string (e.g. "42%").
  String get percentLabel => '${(clamped * 100).toInt()}%';

  @override
  String toString() => 'AudioLevel(level: $level)';
}
