import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'history_screen.dart';
import 'insights_screen.dart';
import 'mood_entry_screen.dart';
import 'onboarding/onboarding_flow.dart';
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
    _index = widget.initialIndex.clamp(0, 2) as int;
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    await StorageService.instance.setOnboardingCompleted(false);
    await StorageService.instance.setNotificationsEnabled(false);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OnboardingFlow(
          onFinished: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 1)),
              (route) => false,
            );
          },
        ),
      ),
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
        await _resetOnboarding(context);
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
          HistoryScreen(),
          InsightsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _handleTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_outlined),
            activeIcon: Icon(Icons.auto_graph),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
