import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/storage_service.dart';
import '../theme/elio_colors.dart';
import 'confirmation_screen.dart';
import 'reflection_screen.dart';

class IntentionScreen extends StatefulWidget {
  const IntentionScreen({super.key, required this.moodValue, required this.moodWord});

  final double moodValue;
  final String moodWord;

  @override
  State<IntentionScreen> createState() => _IntentionScreenState();
}

class _IntentionScreenState extends State<IntentionScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  bool get _isLowMood => widget.moodValue < 0.33;
  bool get _isMidMood => widget.moodValue >= 0.33 && widget.moodValue < 0.66;

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

  void _navigateNext() {
    final reflectionEnabled = StorageService.instance.reflectionEnabled;

    if (reflectionEnabled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReflectionScreen(
            moodWord: widget.moodWord,
            moodValue: widget.moodValue,
            intention: _controller.text.trim(),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            moodWord: widget.moodWord,
            moodValue: widget.moodValue,
            intentionText: _controller.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "You're feeling ${widget.moodWord}",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _promptText,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: ElioColors.darkAccent, width: 1),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _hasText ? _navigateNext() : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _suggestions
                    .map(
                      (suggestion) => GestureDetector(
                        onTap: () => _applySuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasText ? _navigateNext : null,
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
                  child: const Text('Set Intention'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
