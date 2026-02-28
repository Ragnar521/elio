import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../services/sample_data_service.dart';
import '../theme/elio_colors.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  bool _isLoading = false;

  Future<void> _handleDemoMode() async {
    setState(() => _isLoading = true);

    try {
      await SampleDataService.instance.loadDemoData();
      await StorageService.instance.setLauncherCompleted(true);
      widget.onFinished();
    } catch (e) {
      debugPrint('Error loading demo data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load demo data. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleFreshStart() async {
    await StorageService.instance.setLauncherCompleted(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElioColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App name
                  Text(
                    'Elio',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: ElioColors.darkPrimaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Your daily check-in companion',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ElioColors.darkPrimaryText.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Option 1: Use sample data
                  _OptionCard(
                    icon: Icons.auto_awesome,
                    title: 'Explore with sample data',
                    subtitle: 'See what 90 days of check-ins look like',
                    onTap: _isLoading ? null : _handleDemoMode,
                  ),
                  const SizedBox(height: 16),

                  // Option 2: Start fresh
                  _OptionCard(
                    icon: Icons.edit_note,
                    title: 'Start your own journey',
                    subtitle: 'Set up Elio in under 2 minutes',
                    onTap: _isLoading ? null : _handleFreshStart,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: ElioColors.darkBackground.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(ElioColors.darkAccent),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading sample data...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: ElioColors.darkPrimaryText.withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ElioColors.darkSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Icon
              Icon(
                icon,
                color: ElioColors.darkAccent,
                size: 32,
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ElioColors.darkPrimaryText,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ElioColors.darkPrimaryText.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: ElioColors.darkPrimaryText.withOpacity(0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
