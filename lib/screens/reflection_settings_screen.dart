import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/reflection_service.dart';
import '../theme/elio_colors.dart';
import 'custom_question_screen.dart';
import 'question_library_screen.dart';

class ReflectionSettingsScreen extends StatefulWidget {
  const ReflectionSettingsScreen({super.key});

  @override
  State<ReflectionSettingsScreen> createState() => _ReflectionSettingsScreenState();
}

class _ReflectionSettingsScreenState extends State<ReflectionSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedQuestions = ReflectionService.instance.getSelectedQuestions();
    final favorites = selectedQuestions.where((q) => q.isFavorite).toList();
    final nonFavorites = selectedQuestions.where((q) => !q.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ElioColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ElioColors.darkPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reflection Questions',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: ElioColors.darkPrimaryText),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            // Favorites section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'FAVORITES (shown first)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tap ⭐ on any question to pin it (max 2 favorites)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.6),
                    ),
              ),
            ),
            const SizedBox(height: 16),

            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No favorites yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.5),
                      ),
                ),
              ),

            for (final question in favorites)
              _buildQuestionItem(question, isFavorite: true),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: ElioColors.darkSurface),
            ),
            const SizedBox(height: 24),

            // Your questions section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'YOUR QUESTIONS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            for (final question in nonFavorites)
              _buildQuestionItem(question, isFavorite: false),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: ElioColors.darkSurface),
            ),
            const SizedBox(height: 24),

            // Add buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuestionLibraryScreen(),
                      ),
                    );
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ElioColors.darkPrimaryText,
                    side: BorderSide(
                      color: ElioColors.darkPrimaryText.withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('+ Add from library'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomQuestionScreen(),
                      ),
                    );
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ElioColors.darkPrimaryText,
                    side: BorderSide(
                      color: ElioColors.darkPrimaryText.withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('+ Write custom question'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(dynamic question, {required bool isFavorite}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: ElioColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleFavorite(question.id);
                },
                child: Icon(
                  question.isFavorite ? Icons.star : Icons.star_border,
                  color: question.isFavorite
                      ? ElioColors.darkAccent
                      : ElioColors.darkPrimaryText.withOpacity(0.4),
                  size: 24,
                ),
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
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _removeQuestion(question.id);
                },
                child: Icon(
                  Icons.remove_circle_outline,
                  color: ElioColors.darkPrimaryText.withOpacity(0.4),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String questionId) async {
    await ReflectionService.instance.toggleFavorite(questionId);
    setState(() {});
  }

  Future<void> _removeQuestion(String questionId) async {
    await ReflectionService.instance.toggleSelected(questionId);
    setState(() {});
  }
}
