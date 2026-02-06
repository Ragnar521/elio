import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../theme/elio_colors.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.timeLabel,
    required this.moodColor,
  });

  final Entry entry;
  final String timeLabel;
  final Color moodColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: moodColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.moodWord,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: ElioColors.darkPrimaryText),
              ),
              const Spacer(),
              Text(
                timeLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.intention,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}
