import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/reflection_service.dart';
import '../theme/elio_colors.dart';

class CustomQuestionScreen extends StatefulWidget {
  const CustomQuestionScreen({super.key});

  @override
  State<CustomQuestionScreen> createState() => _CustomQuestionScreenState();
}

class _CustomQuestionScreenState extends State<CustomQuestionScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _selectedCategory = 'learning';
  bool _hasText = false;

  final Map<String, String> _categories = {
    'gratitude': 'Gratitude',
    'pride': 'Pride & Wins',
    'learning': 'Learning & Growth',
    'energy': 'Energy & Awareness',
    'tomorrow': 'Tomorrow & Forward',
    'connection': 'Connection',
    'selfcare': 'Self-care',
    'reflection': 'Reflection',
    'presence': 'Presence',
  };

  @override
  void initState() {
    super.initState();
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

  Future<void> _addQuestion() async {
    if (!_hasText) return;

    HapticFeedback.selectionClick();

    await ReflectionService.instance.addCustomQuestion(
      text: _controller.text.trim(),
      category: _selectedCategory,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ElioColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ElioColors.darkPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Custom Question',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: ElioColors.darkPrimaryText),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Your question',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: ElioColors.darkPrimaryText),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: ElioColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 3,
                  maxLength: 100,
                  keyboardAppearance: Brightness.dark,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: ElioColors.darkPrimaryText),
                  decoration: InputDecoration(
                    hintText: 'Did I work on my side project today?',
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ElioColors.darkPrimaryText.withOpacity(0.5),
                        ),
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
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Category',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: ElioColors.darkPrimaryText),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: ElioColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: ElioColors.darkSurface,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: ElioColors.darkPrimaryText),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: ElioColors.darkPrimaryText),
                  items: _categories.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasText ? _addQuestion : null,
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
                  child: const Text('Add Question'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
