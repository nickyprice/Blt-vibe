import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/streaming_config.dart';
import '../providers/streamer_provider.dart';

/// Settings screen: server configuration for Shoutcast and Icecast.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Shoutcast controllers
  late TextEditingController _scHost;
  late TextEditingController _scPort;
  late TextEditingController _scPassword;
  late TextEditingController _scMount;

  // Icecast controllers
  late TextEditingController _icHost;
  late TextEditingController _icPort;
  late TextEditingController _icPassword;
  late TextEditingController _icMount;

  bool _scEnabled = true;
  bool _icEnabled = false;
  int _scBitrate = 128;
  int _icBitrate = 128;

  @override
  void initState() {
    super.initState();
    final config =
        context.read<StreamerProvider>().config;

    _scHost = TextEditingController(text: config.shoutcast.host);
    _scPort = TextEditingController(text: config.shoutcast.port.toString());
    _scPassword = TextEditingController(text: config.shoutcast.password);
    _scMount = TextEditingController(text: config.shoutcast.mountPoint);
    _scEnabled = config.shoutcast.enabled;
    _scBitrate = config.shoutcast.bitrate;

    _icHost = TextEditingController(text: config.icecast.host);
    _icPort = TextEditingController(text: config.icecast.port.toString());
    _icPassword = TextEditingController(text: config.icecast.password);
    _icMount = TextEditingController(text: config.icecast.mountPoint);
    _icEnabled = config.icecast.enabled;
    _icBitrate = config.icecast.bitrate;
  }

  @override
  void dispose() {
    _scHost.dispose();
    _scPort.dispose();
    _scPassword.dispose();
    _scMount.dispose();
    _icHost.dispose();
    _icPort.dispose();
    _icPassword.dispose();
    _icMount.dispose();
    super.dispose();
  }

  void _save() {
    final provider = context.read<StreamerProvider>();

    provider.updateShoutcastConfig(ServerConfig(
      enabled: _scEnabled,
      host: _scHost.text.trim(),
      port: int.tryParse(_scPort.text) ?? 8000,
      password: _scPassword.text,
      mountPoint: _scMount.text.trim(),
      bitrate: _scBitrate,
    ));

    provider.updateIcecastConfig(ServerConfig(
      enabled: _icEnabled,
      host: _icHost.text.trim(),
      port: int.tryParse(_icPort.text) ?? 8000,
      password: _icPassword.text,
      mountPoint: _icMount.text.trim(),
      bitrate: _icBitrate,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Shoutcast ──────────────────────────────────────────────────
          _ServerSection(
            title: '📻 Shoutcast Server',
            enabled: _scEnabled,
            onEnabledChanged: (v) => setState(() => _scEnabled = v),
            hostController: _scHost,
            portController: _scPort,
            passwordController: _scPassword,
            mountController: _scMount,
            bitrate: _scBitrate,
            onBitrateChanged: (v) => setState(() => _scBitrate = v),
          ),

          const SizedBox(height: 16),

          // ── Icecast ────────────────────────────────────────────────────
          _ServerSection(
            title: '🌊 Icecast Server',
            enabled: _icEnabled,
            onEnabledChanged: (v) => setState(() => _icEnabled = v),
            hostController: _icHost,
            portController: _icPort,
            passwordController: _icPassword,
            mountController: _icMount,
            bitrate: _icBitrate,
            onBitrateChanged: (v) => setState(() => _icBitrate = v),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Reusable server configuration card
// ──────────────────────────────────────────────────────────────────────────────

class _ServerSection extends StatelessWidget {
  final String title;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController passwordController;
  final TextEditingController mountController;
  final int bitrate;
  final ValueChanged<int> onBitrateChanged;

  const _ServerSection({
    required this.title,
    required this.enabled,
    required this.onEnabledChanged,
    required this.hostController,
    required this.portController,
    required this.passwordController,
    required this.mountController,
    required this.bitrate,
    required this.onBitrateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 12),
              _Field(
                label: 'Host',
                controller: hostController,
                hint: 'stream.example.com',
                inputType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              _Field(
                label: 'Port',
                controller: portController,
                hint: '8000',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              _Field(
                label: 'Password',
                controller: passwordController,
                hint: '••••••••',
                obscure: true,
              ),
              const SizedBox(height: 8),
              _Field(
                label: 'Mount Point',
                controller: mountController,
                hint: '/stream',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Bitrate (kbps):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: bitrate,
                    items: const [
                      DropdownMenuItem(value: 64, child: Text('64')),
                      DropdownMenuItem(value: 96, child: Text('96')),
                      DropdownMenuItem(value: 128, child: Text('128')),
                      DropdownMenuItem(value: 192, child: Text('192')),
                      DropdownMenuItem(value: 320, child: Text('320')),
                    ],
                    onChanged: (v) {
                      if (v != null) onBitrateChanged(v);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType inputType;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
