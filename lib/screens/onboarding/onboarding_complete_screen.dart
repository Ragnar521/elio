import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../theme/elio_colors.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _buttonOpacity;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _glowScale = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic)),
    );
    _glowOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.75, curve: Curves.easeOutCubic)),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool notificationsEnabled}) async {
    await StorageService.instance.setNotificationsEnabled(notificationsEnabled);
    await StorageService.instance.setOnboardingCompleted(true);
    widget.onFinished();
  }

  Future<void> _handleEnableNotifications() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    final granted = await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily reminder enabled')),
      );
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
    }
    await _finish(notificationsEnabled: granted);
  }

  Future<void> _handleMaybeLater() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    await _finish(notificationsEnabled: false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _glowOpacity.value,
                child: Transform.scale(
                  scale: _glowScale.value,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ElioColors.darkAccent.withOpacity(0.35),
                      boxShadow: [
                        BoxShadow(
                          color: ElioColors.darkAccent.withOpacity(0.6),
                          blurRadius: 26,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _textOpacity,
            child: Column(
              children: [
                Text(
                  'You just checked in.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ElioColors.darkPrimaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Day 1 — this is your start',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.75)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Come back tomorrow. We'll keep it short.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          FadeTransition(
            opacity: _buttonOpacity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isWorking ? null : _handleEnableNotifications,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.disabled)) {
                              return ElioColors.darkAccent.withOpacity(0.4);
                            }
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
                      child: const Text('Enable daily reminder'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isWorking ? null : _handleMaybeLater,
                    style: TextButton.styleFrom(
                      foregroundColor: ElioColors.darkPrimaryText.withOpacity(0.7),
                    ),
                    child: const Text('Maybe later'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
