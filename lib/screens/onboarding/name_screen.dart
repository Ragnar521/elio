import 'package:flutter/material.dart';

import '../../theme/elio_colors.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.onContinue, required this.onSkip});

  final ValueChanged<String> onContinue;
  final VoidCallback onSkip;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'What should we call you?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ElioColors.darkPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 28),
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
                maxLength: 20,
                keyboardAppearance: Brightness.dark,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: ElioColors.darkPrimaryText),
                decoration: InputDecoration(
                  hintText: 'Your name',
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
                onSubmitted: (_) => _hasText ? widget.onContinue(_controller.text) : null,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _hasText ? () => widget.onContinue(_controller.text) : null,
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
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: ElioColors.darkPrimaryText.withOpacity(0.7),
                ),
                child: const Text('Skip for now'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
