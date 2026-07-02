import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/audio_provider.dart';
import 'providers/metadata_provider.dart';
import 'providers/streamer_provider.dart';
import 'screens/home_screen.dart';
import 'screens/metadata_screen.dart';
import 'screens/settings_screen.dart';
import 'services/audio_service.dart';
import 'services/streaming_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BltVibeApp());
}

class BltVibeApp extends StatelessWidget {
  const BltVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared service singletons once at the top of the widget tree.
    final audioService = AudioService();
    final streamingService = StreamingService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AudioProvider(audioService),
        ),
        ChangeNotifierProvider(
          create: (_) => StreamerProvider(streamingService, audioService),
        ),
        ChangeNotifierProxyProvider<StreamerProvider, MetadataProvider>(
          create: (_) => MetadataProvider(streamingService),
          update: (_, __, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        title: 'BLT Vibe',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const _RootScaffold(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0), // Deep blue brand colour
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
  }
}

/// Root scaffold with a bottom navigation bar switching between the three
/// main screens.
class _RootScaffold extends StatefulWidget {
  const _RootScaffold();

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _selectedIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings'),
    _NavItem(
        icon: Icons.music_note_outlined,
        activeIcon: Icons.music_note,
        label: 'Metadata'),
  ];

  static const List<Widget> _screens = [
    HomeScreen(),
    SettingsScreen(),
    MetadataScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLT Vibe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StreamingBadge(),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Small badge in the app bar indicating streaming / recording state.
class _StreamingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<StreamerProvider>();
    if (state.isStreaming) {
      return const Chip(
        avatar: Icon(Icons.circle, color: Colors.red, size: 12),
        label: Text('LIVE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }
    if (state.isRecording) {
      return const Chip(
        avatar: Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
        label: Text('REC',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }
    return const SizedBox.shrink();
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
