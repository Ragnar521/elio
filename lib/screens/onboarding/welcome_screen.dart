import 'package:flutter/material.dart';

import '../../theme/elio_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(),
            FadeTransition(
              opacity: _logoOpacity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ElioColors.darkAccent.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'images/appicon.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _titleOpacity,
              child: Text(
                'Clarity in 2 minutes a day',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: ElioColors.darkPrimaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _subtitleOpacity,
              child: Text(
                "Connect how you feel to where you're going",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.7),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _buttonOpacity,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) {
                        if (states.contains(MaterialState.pressed)) {
                          return const Color(0xFFE5562E);
                        }
                        return ElioColors.darkAccent;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.all(ElioColors.darkPrimaryText),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    elevation: MaterialStateProperty.all(0),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
