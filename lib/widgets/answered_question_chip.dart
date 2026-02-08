import 'package:flutter/material.dart';

import '../theme/elio_colors.dart';

class AnsweredQuestionChip extends StatelessWidget {
  const AnsweredQuestionChip({
    super.key,
    required this.questionText,
    required this.answer,
  });

  final String questionText;
  final String answer;

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 1)}…';
  }

  String get _displayText {
    final prefix = questionText.split(' ').take(2).join(' ');
    return '$prefix: ${_truncate(answer, 30)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: ElioColors.darkAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _displayText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.7),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
