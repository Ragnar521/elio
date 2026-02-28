import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/elio_colors.dart';

/// Standard empty state layout with SVG illustration, title, description, and optional CTA.
///
/// Provides a consistent empty state design across all screens:
/// - SVG illustration with warm cream tone
/// - Headline text
/// - Description text with reduced opacity
/// - Optional call-to-action button
///
/// Usage:
/// ```dart
/// EmptyStateView(
///   svgAsset: 'assets/empty_states/history_empty.svg',
///   title: 'No entries yet',
///   description: 'Your check-in history will appear here',
///   ctaLabel: 'Check in now',
///   onCtaPressed: () => Navigator.push(...),
/// )
/// ```
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.svgAsset,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCtaPressed,
  });

  /// Path to the SVG asset to display
  final String svgAsset;

  /// Main headline text
  final String title;

  /// Descriptive text below the title
  final String description;

  /// Optional label for the call-to-action button
  final String? ctaLabel;

  /// Optional callback for the call-to-action button
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG illustration with warm cream tone
            SvgPicture.asset(
              svgAsset,
              width: 120,
              height: 120,
              colorFilter: ColorFilter.mode(
                ElioColors.darkPrimaryText.withOpacity(0.6),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),

            // Optional CTA button
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onCtaPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: ElioColors.darkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
