import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/storage_service.dart';
import '../theme/elio_colors.dart';
import 'reflection_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _reflectionEnabled;

  @override
  void initState() {
    super.initState();
    _reflectionEnabled = StorageService.instance.reflectionEnabled;
  }

  Future<void> _toggleReflection(bool value) async {
    HapticFeedback.selectionClick();
    await StorageService.instance.setReflectionEnabled(value);
    setState(() {
      _reflectionEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = StorageService.instance.userName;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            // Settings title
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // User name display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ElioColors.darkPrimaryText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: ElioColors.darkSurface),
            const SizedBox(height: 24),

            // Daily Reflection toggle
            Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reflection',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: ElioColors.darkPrimaryText,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Answer reflection questions during check-ins',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ElioColors.darkPrimaryText.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _reflectionEnabled,
                    onChanged: _toggleReflection,
                    activeColor: ElioColors.darkAccent,
                    activeTrackColor: ElioColors.darkAccent.withOpacity(0.4),
                  ),
                ],
              ),

            // Manage questions button (only show if enabled)
            if (_reflectionEnabled) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReflectionSettingsScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ElioColors.darkPrimaryText,
                  side: BorderSide(
                    color: ElioColors.darkPrimaryText.withOpacity(0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Manage reflection questions'),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(color: ElioColors.darkSurface),
          ],
        ),
      ),
    );
  }
}
