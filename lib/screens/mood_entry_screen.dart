import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/elio_colors.dart';
import '../services/storage_service.dart';
import 'intention_screen.dart';

class MoodEntryScreen extends StatefulWidget {
  const MoodEntryScreen({super.key});

  @override
  State<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends State<MoodEntryScreen> with SingleTickerProviderStateMixin {
  double _moodValue = 0.5;
  bool _hasInteracted = false;
  int _lastThresholdIndex = 0;
  late String _userName;
  AnimationController? _buttonAnimationController;
  Animation<Offset>? _buttonSlideAnimation;
  Animation<double>? _buttonFadeAnimation;

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

    // Initialize button animation
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _buttonAnimationController = controller;
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController?.dispose();
    super.dispose();
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
    final wasInteracted = _hasInteracted;
    setState(() {
      _moodValue = value;
      _hasInteracted = true;
    });

    // Animate button in on first interaction
    if (!wasInteracted) {
      _buttonAnimationController?.forward();
    }

    final nextIndex = _thresholdIndexFor(value);
    if (nextIndex != _lastThresholdIndex) {
      _lastThresholdIndex = nextIndex;
      if (Platform.isIOS) {
        HapticFeedback.selectionClick();
      }
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
            if (_hasInteracted && _buttonSlideAnimation != null && _buttonFadeAnimation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SlideTransition(
                  position: _buttonSlideAnimation!,
                  child: FadeTransition(
                    opacity: _buttonFadeAnimation!,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IntentionScreen(
                                moodValue: _moodValue,
                                moodWord: _moodWordFor(_moodValue),
                              ),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (states) {
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
                ),
              )
            else
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
