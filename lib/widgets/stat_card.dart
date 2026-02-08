import 'package:flutter/material.dart';

import '../theme/elio_colors.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.comparison,
    this.isPositive,
  });

  final String value;
  final String label;
  final String? comparison;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElioColors.darkPrimaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ElioColors.darkPrimaryText.withOpacity(0.6),
                  fontSize: 11,
                  height: 1.2,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (comparison != null) ...[
            const SizedBox(height: 4),
            Text(
              comparison!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: isPositive == true
                        ? const Color(0xFF4CAF50)
                        : ElioColors.darkPrimaryText.withOpacity(0.5),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Add spacer when no comparison to maintain consistent height
          if (comparison == null) const SizedBox(height: 15),
        ],
      ),
    );
  }
}
