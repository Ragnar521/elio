import 'package:flutter/material.dart';

import '../theme/elio_colors.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: ElioColors.darkAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
