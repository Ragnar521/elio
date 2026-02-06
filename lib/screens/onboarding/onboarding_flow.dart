import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import 'first_checkin_screen.dart';
import 'name_screen.dart';
import 'onboarding_complete_screen.dart';
import 'welcome_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int index) async {
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleNameContinue(String name) async {
    await StorageService.instance.setUserName(name);
    await _goToPage(2);
  }

  Future<void> _handleNameSkip() async {
    await StorageService.instance.setUserName('there');
    await _goToPage(2);
  }

  Future<void> _handleComplete() async {
    await _goToPage(3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WelcomeScreen(onNext: () => _goToPage(1)),
          NameScreen(
            onContinue: _handleNameContinue,
            onSkip: _handleNameSkip,
          ),
          FirstCheckinScreen(onComplete: _handleComplete),
          OnboardingCompleteScreen(onFinished: widget.onFinished),
        ],
      ),
    );
  }
}
