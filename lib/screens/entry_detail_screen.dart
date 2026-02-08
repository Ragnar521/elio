import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../models/reflection_answer.dart';
import '../services/reflection_service.dart';
import '../theme/elio_colors.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({
    super.key,
    required this.entry,
    required this.timeLabel,
    required this.dateLabel,
    required this.moodColor,
  });

  final Entry entry;
  final String timeLabel;
  final String dateLabel;
  final Color moodColor;

  @override
  Widget build(BuildContext context) {
    // Load reflection answers if any
    final reflectionAnswers = entry.reflectionAnswerIds != null
        ? ReflectionService.instance.getAnswersByIds(entry.reflectionAnswerIds!)
        : <ReflectionAnswer>[];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ElioColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ElioColors.darkPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Entry Details',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: ElioColors.darkPrimaryText),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and time
              Text(
                '$dateLabel • $timeLabel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 24),

              // Mood section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ElioColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: moodColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Feeling ${entry.moodWord}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: ElioColors.darkPrimaryText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Mood intensity bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.moodValue,
                        backgroundColor: ElioColors.darkBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Intention section
              Text(
                'INTENTION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ElioColors.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  entry.intention,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ElioColors.darkPrimaryText,
                        height: 1.5,
                      ),
                ),
              ),

              // Reflections section (only show if there are answers)
              if (reflectionAnswers.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'REFLECTIONS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),

                // Display each reflection answer
                for (final answer in reflectionAnswers) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ElioColors.darkSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.question_answer,
                              size: 18,
                              color: ElioColors.darkAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                answer.questionText,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: ElioColors.darkPrimaryText.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            answer.answer,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: ElioColors.darkPrimaryText,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
