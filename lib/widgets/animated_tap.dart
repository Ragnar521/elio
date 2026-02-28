import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable wrapper that adds subtle scale animation + optional haptic feedback to any widget.
///
/// Provides a press-and-release micro-interaction:
/// - Scale down on press (configurable via pressScale)
/// - Scale back up on release
/// - Optional haptic feedback on tap
///
/// Use cases:
/// - Buttons: pressScale = 0.97
/// - Cards: pressScale = 0.98
class AnimatedTap extends StatefulWidget {
  const AnimatedTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.97,
    this.enableHaptic = false,
  });

  /// The widget to wrap with the tap animation
  final Widget child;

  /// Callback when the widget is tapped
  final VoidCallback? onTap;

  /// The scale factor when pressed (0.97 for buttons, 0.98 for cards)
  final double pressScale;

  /// Whether to trigger haptic feedback on tap
  final bool enableHaptic;

  @override
  State<AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<AnimatedTap> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      // Trigger haptic feedback if enabled (wrapped in try-catch for platform safety)
      if (widget.enableHaptic) {
        try {
          HapticFeedback.lightImpact();
        } catch (e) {
          // Silently fail if haptic feedback not supported on platform
          debugPrint('Haptic feedback not supported: $e');
        }
      }
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressScale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
