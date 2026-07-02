import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/streamer_provider.dart';

/// Large, touch-friendly Start / Stop / Record control row.
class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StreamerProvider>();
    final isStreaming = provider.isStreaming;
    final isConnecting = provider.isConnecting;
    final isRecording = provider.isRecording;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BigButton(
                  label: isConnecting
                      ? 'Connecting…'
                      : isStreaming
                          ? 'Stop'
                          : 'Start',
                  icon: isStreaming || isConnecting
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outlined,
                  color: isStreaming
                      ? Colors.red
                      : isConnecting
                          ? Colors.orange
                          : Colors.green,
                  onPressed: (isConnecting)
                      ? null
                      : isStreaming
                          ? () => provider.stopStreaming()
                          : () => provider.startStreaming(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigButton(
                  label: isRecording ? 'Stop Rec' : 'Record',
                  icon: isRecording
                      ? Icons.stop_circle
                      : Icons.fiber_manual_record,
                  color: isRecording ? Colors.green : Colors.deepOrange,
                  onPressed: isRecording
                      ? () async {
                          final path = await provider.stopRecording();
                          if (context.mounted && path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Saved: $path')),
                            );
                          }
                        }
                      : () => provider.startRecording(),
                ),
              ),
            ],
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label),
    );
  }
}
