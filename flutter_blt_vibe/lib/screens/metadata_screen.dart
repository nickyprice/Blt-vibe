import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/metadata_provider.dart';
import '../providers/streamer_provider.dart';

/// Metadata screen: edit artist, title, on-air name and push to servers.
class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  late TextEditingController _artistCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _onAirCtrl;

  @override
  void initState() {
    super.initState();
    final meta = context.read<MetadataProvider>().metadata;
    _artistCtrl = TextEditingController(text: meta.artist);
    _titleCtrl = TextEditingController(text: meta.title);
    _onAirCtrl = TextEditingController(text: meta.onAirName);
  }

  @override
  void dispose() {
    _artistCtrl.dispose();
    _titleCtrl.dispose();
    _onAirCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateMetadata() async {
    final metaProvider = context.read<MetadataProvider>();
    final streamerProvider = context.read<StreamerProvider>();

    metaProvider.setArtist(_artistCtrl.text.trim());
    metaProvider.setTitle(_titleCtrl.text.trim());
    metaProvider.setOnAirName(_onAirCtrl.text.trim());

    await metaProvider.updateMetadata(streamerProvider.config);

    if (!mounted) return;
    if (metaProvider.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠ ${metaProvider.lastError}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Metadata updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaProvider = context.watch<MetadataProvider>();
    final streamerProvider = context.watch<StreamerProvider>();
    final isStreaming = streamerProvider.isStreaming;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎵 Now Playing',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _MetaField(
                    label: 'Artist',
                    controller: _artistCtrl,
                    hint: 'e.g. The Beatles',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _MetaField(
                    label: 'Title',
                    controller: _titleCtrl,
                    hint: 'e.g. Hey Jude',
                    icon: Icons.music_note,
                  ),
                  const SizedBox(height: 12),
                  _MetaField(
                    label: 'On Air Name',
                    controller: _onAirCtrl,
                    hint: 'e.g. DJ Awesome',
                    icon: Icons.mic,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Song string preview
          if (_artistCtrl.text.isNotEmpty || _titleCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Preview: ${_buildSong()}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),

          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed: metaProvider.isUpdating ? null : _updateMetadata,
            icon: metaProvider.isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(
              isStreaming ? 'Update Metadata (Live)' : 'Update Metadata',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),

          if (!isStreaming)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Note: metadata will be sent to the server once streaming starts.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),

          if (metaProvider.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last updated: ${_formatTime(metaProvider.lastUpdated!)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _buildSong() {
    final a = _artistCtrl.text.trim();
    final t = _titleCtrl.text.trim();
    if (a.isNotEmpty && t.isNotEmpty) return '$a - $t';
    if (a.isNotEmpty) return a;
    return t;
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

class _MetaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData icon;

  const _MetaField({
    required this.label,
    required this.controller,
    this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
