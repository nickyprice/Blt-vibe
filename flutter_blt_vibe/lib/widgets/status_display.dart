import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/streamer_provider.dart';

/// Compact streaming-state banner shown at the top of the home screen.
class StatusDisplay extends StatelessWidget {
  const StatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StreamerProvider>();
    final state = provider.state;

    final (icon, label, bgColor) = switch (state) {
      StreamingState.idle => (
          Icons.radio_button_unchecked,
          'Ready',
          Colors.grey.shade700,
        ),
      StreamingState.connecting => (
          Icons.sync,
          'Connecting…',
          Colors.orange,
        ),
      StreamingState.streaming => (
          Icons.radio_button_checked,
          'LIVE',
          Colors.red,
        ),
      StreamingState.error => (
          Icons.error_outline,
          'Error',
          Colors.red.shade800,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state == StreamingState.streaming)
            const _PulsingDot()
          else
            Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          if (provider.isRecording) ...[
            const SizedBox(width: 16),
            const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            const Text(
              'REC',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small pulsing red dot that indicates live streaming.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const Icon(Icons.circle, color: Colors.white, size: 16),
    );
  }
}
