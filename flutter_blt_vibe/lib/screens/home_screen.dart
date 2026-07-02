import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../providers/metadata_provider.dart';
import '../providers/streamer_provider.dart';
import '../widgets/level_meter.dart';
import '../widgets/control_buttons.dart';
import '../widgets/status_display.dart';

/// Main screen: audio level meter, streaming controls, and connection status.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final streamerProvider = context.watch<StreamerProvider>();
    final metaProvider = context.watch<MetadataProvider>();
    final config = streamerProvider.config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Status banner ──────────────────────────────────────────────────
        const StatusDisplay(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Audio level ──────────────────────────────────────────
                _SectionCard(
                  title: '🎙 Audio Level',
                  child: Column(
                    children: [
                      LevelMeter(
                        level: audioProvider.currentLevel.clamped,
                        height: 28,
                      ),
                      const SizedBox(height: 8),
                      if (!audioProvider.hasPermission)
                        OutlinedButton.icon(
                          onPressed: () => audioProvider.requestPermission(),
                          icon: const Icon(Icons.mic),
                          label: const Text('Grant Microphone Permission'),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Connection summary ───────────────────────────────────
                _SectionCard(
                  title: '📡 Servers',
                  child: Column(
                    children: [
                      _ServerRow(
                        label: 'Shoutcast',
                        host: config.shoutcast.host,
                        port: config.shoutcast.port,
                        enabled: config.shoutcast.enabled,
                        connected: streamerProvider.streamingService
                            .shoutcastConnected,
                      ),
                      const Divider(height: 16),
                      _ServerRow(
                        label: 'Icecast',
                        host: config.icecast.host,
                        port: config.icecast.port,
                        enabled: config.icecast.enabled,
                        connected: streamerProvider.streamingService
                            .icecastConnected,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Metadata preview ─────────────────────────────────────
                _SectionCard(
                  title: '🎵 Now Playing',
                  child: _MetadataPreview(
                    artist: metaProvider.metadata.artist,
                    title: metaProvider.metadata.title,
                    onAirName: metaProvider.metadata.onAirName,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Controls ──────────────────────────────────────────────────────
        const Divider(height: 1),
        const ControlButtons(),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ──────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  final String label;
  final String host;
  final int port;
  final bool enabled;
  final bool connected;

  const _ServerRow({
    required this.label,
    required this.host,
    required this.port,
    required this.enabled,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusText;
    if (!enabled) {
      statusColor = Colors.grey;
      statusText = 'Disabled';
    } else if (connected) {
      statusColor = Colors.green;
      statusText = 'Connected';
    } else {
      statusColor = Colors.orange;
      statusText = host.isEmpty ? 'Not configured' : 'Disconnected';
    }

    return Row(
      children: [
        Icon(Icons.circle, color: statusColor, size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          host.isEmpty ? '—' : '$host:$port',
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MetadataPreview extends StatelessWidget {
  final String artist;
  final String title;
  final String onAirName;

  const _MetadataPreview({
    required this.artist,
    required this.title,
    required this.onAirName,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = artist.isEmpty && title.isEmpty && onAirName.isEmpty;
    if (isEmpty) {
      return Text(
        'No metadata set — go to the Metadata tab.',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (artist.isNotEmpty)
          _MetaRow(label: 'Artist', value: artist),
        if (title.isNotEmpty)
          _MetaRow(label: 'Title', value: title),
        if (onAirName.isNotEmpty)
          _MetaRow(label: 'On Air', value: onAirName),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
