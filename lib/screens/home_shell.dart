import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'history_screen.dart';
import 'insights_screen.dart';
import 'directions_screen.dart';
import 'mood_entry_screen.dart';
import 'settings_screen.dart';
import '../main.dart';
import '../services/storage_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;
  int _homeTapCount = 0;
  DateTime? _lastHomeTap;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  Future<void> _resetApp(BuildContext context) async {
    // Wipe all data (entries, directions, settings, everything)
    await StorageService.instance.wipeAllData();

    if (!context.mounted) return;

    // Navigate to OnboardingGate — since settings are wiped,
    // launcherCompleted is false, so it will show LauncherScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingGate()),
      (route) => false,
    );
  }

  Future<void> _handleTap(int value) async {
    if (kDebugMode && value == 0) {
      final now = DateTime.now();
      final lastTap = _lastHomeTap;
      if (lastTap == null || now.difference(lastTap) > const Duration(milliseconds: 800)) {
        _homeTapCount = 1;
      } else {
        _homeTapCount += 1;
      }
      _lastHomeTap = now;
      if (_homeTapCount >= 3) {
        _homeTapCount = 0;
        await _resetApp(context);
        return;
      }
    } else {
      _homeTapCount = 0;
      _lastHomeTap = null;
    }
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          MoodEntryScreen(),
          InsightsScreen(),
          DirectionsScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _handleTap,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph_outlined),
              activeIcon: Icon(Icons.auto_graph),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Directions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
