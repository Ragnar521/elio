import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reflection_question.dart';
import '../services/reflection_service.dart';
import '../theme/elio_colors.dart';

class QuestionLibraryScreen extends StatefulWidget {
  const QuestionLibraryScreen({super.key});

  @override
  State<QuestionLibraryScreen> createState() => _QuestionLibraryScreenState();
}

class _QuestionLibraryScreenState extends State<QuestionLibraryScreen> {
  final Map<String, String> _categoryLabels = {
    'gratitude': 'GRATITUDE',
    'pride': 'PRIDE & WINS',
    'learning': 'LEARNING & GROWTH',
    'energy': 'ENERGY & AWARENESS',
    'tomorrow': 'TOMORROW & FORWARD',
    'connection': 'CONNECTION',
    'selfcare': 'SELF-CARE',
    'reflection': 'REFLECTION',
    'presence': 'PRESENCE',
  };

  @override
  Widget build(BuildContext context) {
    final questionsByCategory = ReflectionService.instance.getQuestionsByCategory();
    final sortedCategories = _categoryLabels.keys.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ElioColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ElioColors.darkPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Question Library',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: ElioColors.darkPrimaryText),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  for (final categoryKey in sortedCategories)
                    if (questionsByCategory[categoryKey] != null &&
                        questionsByCategory[categoryKey]!.isNotEmpty)
                      _buildCategorySection(
                        _categoryLabels[categoryKey]!,
                        questionsByCategory[categoryKey]!,
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(ElioColors.darkAccent),
                    foregroundColor: WidgetStateProperty.all(ElioColors.darkPrimaryText),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String label, List<ReflectionQuestion> questions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: ElioColors.darkSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: questions
                  .map((question) => _buildQuestionItem(question))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(ReflectionQuestion question) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _toggleQuestion(question);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: question.isSelected
                      ? ElioColors.darkAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: question.isSelected
                        ? ElioColors.darkAccent
                        : ElioColors.darkPrimaryText.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: question.isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: ElioColors.darkPrimaryText,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleQuestion(ReflectionQuestion question) async {
    await ReflectionService.instance.toggleSelected(question.id);
    setState(() {});
  }
}
