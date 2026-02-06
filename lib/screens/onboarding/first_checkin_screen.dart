import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/storage_service.dart';
import '../../theme/elio_colors.dart';

class FirstCheckinScreen extends StatefulWidget {
  const FirstCheckinScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<FirstCheckinScreen> createState() => _FirstCheckinScreenState();
}

class _FirstCheckinScreenState extends State<FirstCheckinScreen> {
  double _moodValue = 0.5;
  bool _hasInteracted = false;
  int _lastThresholdIndex = 0;
  bool _hasText = false;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

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
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
      if (Platform.isIOS) {
        HapticFeedback.selectionClick();
      }
    }

    if (_focusNode.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
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

  bool get _isLowMood => _moodValue < 0.33;
  bool get _isMidMood => _moodValue >= 0.33 && _moodValue < 0.66;

  String get _promptText {
    if (_isLowMood) return "What's one small thing that could help?";
    if (_isMidMood) return 'What do you want to focus on?';
    return 'What will you carry this energy into?';
  }

  List<String> get _suggestions {
    if (_isLowMood) {
      return const [
        'Rest without guilt',
        'One small win',
        'Be gentle with myself',
      ];
    }
    if (_isMidMood) {
      return const [
        'Stay present',
        'Focus on one task',
        'Connect with someone',
      ];
    }
    return const [
      'Share this energy',
      'Tackle something hard',
      'Help someone',
    ];
  }

  void _applySuggestion(String suggestion) {
    HapticFeedback.selectionClick();
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  Future<void> _handleDone() async {
    if (!_hasText) return;
    try {
      await StorageService.instance.saveEntry(
        moodValue: _moodValue,
        moodWord: _moodWordFor(_moodValue),
        intention: _controller.text.trim(),
      );
    } catch (_) {}
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodWord = _moodWordFor(_moodValue);
    final glow = _moodGlow();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Let's try your first check-in",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ElioColors.darkPrimaryText,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Slide to capture how you\'re feeling',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.6)),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: ElioColors.darkSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: glow.withOpacity(0.35),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _hasInteracted ? 1.0 : 0.0,
                    child: Text(
                      moodWord,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: ElioColors.darkPrimaryText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: !_hasInteracted
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      key: const ValueKey('intention'),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _promptText,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ElioColors.darkPrimaryText,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: ElioColors.darkSurface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLength: 100,
                              keyboardAppearance: Brightness.dark,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: ElioColors.darkPrimaryText),
                              decoration: InputDecoration(
                                hintText: 'e.g., Be patient in my meeting',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.5)),
                                counterText: '',
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide:
                                      const BorderSide(color: ElioColors.darkAccent, width: 1),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _hasText ? _handleDone() : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _suggestions
                                .map(
                                  (suggestion) => GestureDetector(
                                    onTap: () => _applySuggestion(suggestion),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ElioColors.darkSurface,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        suggestion,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: ElioColors.darkPrimaryText),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
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
                onPressed: _hasText ? _handleDone : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.disabled)) {
                        return ElioColors.darkAccent.withOpacity(0.4);
                      }
                      if (states.contains(MaterialState.pressed)) {
                        return const Color(0xFFE5562E);
                      }
                      return ElioColors.darkAccent;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.all(ElioColors.darkPrimaryText),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  elevation: MaterialStateProperty.all(0),
                ),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
