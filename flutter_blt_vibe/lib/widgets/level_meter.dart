import 'package:flutter/material.dart';

/// A color-coded audio VU meter.
///
/// The bar transitions through green → orange → red as the level rises:
///   0 – 60 %  → green
///   60 – 80 % → orange
///   80 – 100% → red
class LevelMeter extends StatelessWidget {
  /// Normalised level: 0.0 (silence) to 1.0 (clip).
  final double level;

  /// Height of the meter bar.
  final double height;

  const LevelMeter({
    super.key,
    required this.level,
    this.height = 24,
  });

  Color _colorForLevel(double l) {
    if (l < 0.6) return const Color(0xFF4CAF50); // green
    if (l < 0.8) return const Color(0xFFFF9800); // orange
    return const Color(0xFFF44336); // red
  }

  @override
  Widget build(BuildContext context) {
    final clamped = level.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: height,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(_colorForLevel(clamped)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              '${(clamped * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '100',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}
