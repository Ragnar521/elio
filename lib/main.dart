import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/elio_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
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
