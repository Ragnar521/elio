import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/notification_service.dart';
import 'services/reflection_service.dart';
import 'services/storage_service.dart';
import 'services/direction_service.dart';
import 'services/weekly_summary_service.dart';
import 'theme/elio_theme.dart';
import 'theme/elio_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary — replaces red error screen with user-friendly fallback
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: ElioColors.darkBackground,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: ElioColors.darkAccent.withOpacity(0.6),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ElioColors.darkPrimaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We couldn\'t load this screen. Try restarting the app.',
                  style: TextStyle(
                    fontSize: 16,
                    color: ElioColors.darkPrimaryText.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                // Show exception details in debug mode
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Text(
                    details.exception.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: ElioColors.darkPrimaryText.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  };

  await StorageService.instance.init();
  await ReflectionService.instance.init();
  await DirectionService.instance.init();
  await WeeklySummaryService.instance.init();
  await NotificationService.instance.init();
  runApp(const ElioApp());
}

class ElioApp extends StatelessWidget {
  const ElioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elio',
      theme: ElioTheme.light(),
      darkTheme: ElioTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const OnboardingGate(),
    );
  }
}

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool _isComplete;

  @override
  void initState() {
    super.initState();
    _isComplete = StorageService.instance.onboardingCompleted;
  }

  void _handleOnboardingFinished() {
    setState(() => _isComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return const HomeShell(initialIndex: 1);
    }

    return OnboardingFlow(onFinished: _handleOnboardingFinished);
  }
}
