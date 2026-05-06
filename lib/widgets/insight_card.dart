import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/elio_colors.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, this.text, this.insights});

  final String? text;
  final List<InsightItem>? insights;

  @override
  Widget build(BuildContext context) {
    // Support both old single text and new multiple insights
    final items =
        insights ??
        (text != null
            ? [InsightItem(Icons.lightbulb_outline, text!)]
            : <InsightItem>[]);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(items[i].icon, size: 20, color: ElioColors.darkAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[i].text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ElioColors.darkPrimaryText,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
