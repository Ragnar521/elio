import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/elio_colors.dart';
import '../services/storage_service.dart';
import '../services/weekly_summary_service.dart';
import '../services/nudge_service.dart';
import '../services/direction_service.dart';
import '../models/weekly_summary.dart';
import '../models/nudge.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/nudge_card.dart';
import 'intention_screen.dart';
import 'weekly_summary_screen.dart';
import 'direction_detail_screen.dart';

Route _checkInRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(0.0, 0.15),
        end: Offset.zero,
      );
      final slideAnimation = animation.drive(
        slideTween.chain(CurveTween(curve: Curves.easeInOut)),
      );
      final fadeAnimation = animation.drive(
        Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
      );
      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

class MoodEntryScreen extends StatefulWidget {
  const MoodEntryScreen({super.key});

  @override
  State<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends State<MoodEntryScreen> {
  double _moodValue = 0.5;
  bool _hasInteracted = false;
  int _lastThresholdIndex = 0;
  late String _userName;
  WeeklySummary? _pendingSummary;
  bool _summaryDismissed = false;
  Nudge? _currentNudge;
  bool _nudgeDismissed = false;
  late final AppLifecycleListener _lifecycleListener;

  static const _moodWords = [
    'Heavy',
    'Tired',
    'Flat',
    'Okay',
    'Calm',
    'Good',
    'Energized',
    'Great',
  ];

  static const _thresholds = [
    0.0,
    0.14,
    0.28,
    0.42,
    0.56,
    0.70,
    0.84,
    1.0,
  ];

  @override
  void initState() {
    super.initState();
    _lastThresholdIndex = _thresholdIndexFor(_moodValue);
    _userName = StorageService.instance.userName;
    _checkForWeeklySummary();
    _checkForNudges();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => _checkForNudges(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _checkForWeeklySummary() async {
    final summary = await WeeklySummaryService.instance.getOrGenerateCurrentSummary();
    if (summary != null && !summary.hasBeenViewed && mounted) {
      setState(() => _pendingSummary = summary);
    }
  }

  Future<void> _dismissSummary() async {
    if (_pendingSummary != null) {
      await WeeklySummaryService.instance.markAsViewed(_pendingSummary!.id);
      setState(() {
        _summaryDismissed = true;
        _pendingSummary = null;
      });
    }
  }

  void _openSummary() {
    if (_pendingSummary == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeeklySummaryScreen(summary: _pendingSummary!),
      ),
    ).then((_) {
      setState(() {
        _summaryDismissed = true;
        _pendingSummary = null;
      });
    });
  }

  Future<void> _checkForNudges() async {
    // First check for pending nudge from post-check-in
    final pending = NudgeService.instance.consumePendingNudge();
    if (pending != null && mounted) {
      setState(() {
        _currentNudge = pending;
        _nudgeDismissed = false;
      });
      return;
    }

    // Then check for app-open nudges (dormant directions)
    final nudge = await NudgeService.instance.checkOnAppOpen();
    if (nudge != null && mounted) {
      setState(() {
        _currentNudge = nudge;
        _nudgeDismissed = false;
      });
    }
  }

  Future<void> _dismissNudge() async {
    if (_currentNudge == null) return;
    final cooldownKey = _currentNudge!.id;
    await NudgeService.instance.dismissNudge(cooldownKey);
    setState(() {
      _nudgeDismissed = true;
      _currentNudge = null;
    });
  }

  void _handleNudgeTap() {
    if (_currentNudge == null) return;
    final nudge = _currentNudge!;

    if (nudge.type == NudgeType.dormantDirection && nudge.directionId != null) {
      // Navigate to DirectionDetailScreen
      final direction = DirectionService.instance.getDirection(nudge.directionId!);
      if (direction != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DirectionDetailScreen(direction: direction),
          ),
        );
      }
    }
    // Streak celebrations and mood patterns: dismiss only (no navigation)
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $_userName';
    if (hour < 18) return 'Good afternoon, $_userName';
    return 'Good evening, $_userName';
  }

  int _thresholdIndexFor(double value) {
    for (var i = 0; i < _thresholds.length; i++) {
      if (value <= _thresholds[i]) return i;
    }
    return _thresholds.length - 1;
  }

  void _onMoodChanged(double value) {
    setState(() {
      _moodValue = value;
      _hasInteracted = true;
    });

    final nextIndex = _thresholdIndexFor(value);
    if (nextIndex != _lastThresholdIndex) {
      _lastThresholdIndex = nextIndex;
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  Color _moodGlow() {
    const low = Color(0xFF4B5A68);
    const high = ElioColors.darkAccent;
    return Color.lerp(low, high, _moodValue) ?? high;
  }

  String _moodWordFor(double value) {
    final moodWordIndex = (value * (_moodWords.length - 1)).round();
    return _moodWords[moodWordIndex];
  }

  @override
  Widget build(BuildContext context) {
    final moodWord = _moodWordFor(_moodValue);
    final glow = _moodGlow();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_pendingSummary != null && !_summaryDismissed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: WeeklySummaryCard(
                  summary: _pendingSummary!,
                  onTap: _openSummary,
                  onDismiss: _dismissSummary,
                ),
              ),
            if (_currentNudge != null && !_nudgeDismissed && (_pendingSummary == null || _summaryDismissed))
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: NudgeCard(
                  nudge: _currentNudge!,
                  onDismiss: _dismissNudge,
                  onTap: _currentNudge!.actionText != null ? _handleNudgeTap : null,
                ),
              ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How are you feeling right now?',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: ElioColors.darkSurface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: glow.withOpacity(0.35),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            moodWord,
                            key: ValueKey(moodWord),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: ElioColors.darkPrimaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: glow,
                            inactiveTrackColor: ElioColors.darkPrimaryText.withOpacity(0.15),
                            thumbColor: ElioColors.darkPrimaryText,
                            overlayColor: glow.withOpacity(0.15),
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          ),
                          child: Slider(
                            value: _moodValue,
                            onChanged: _onMoodChanged,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Heavy',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ElioColors.darkPrimaryText.withOpacity(0.5),
                                    ),
                              ),
                              Text(
                                'Great',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ElioColors.darkPrimaryText.withOpacity(0.5),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasInteracted
                      ? () {
                          Navigator.of(context).push(
                            _checkInRoute(
                              IntentionScreen(
                                moodValue: _moodValue,
                                moodWord: _moodWordFor(_moodValue),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return ElioColors.darkAccent.withOpacity(0.4);
                        }
                        if (states.contains(WidgetState.pressed)) {
                          return const Color(0xFFE5562E);
                        }
                        return ElioColors.darkAccent;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.all(ElioColors.darkPrimaryText),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
