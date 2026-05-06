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

  Future<void> _editUserName() async {
    HapticFeedback.selectionClick();

    final newName = await showDialog<String>(
      context: context,
      builder: (_) =>
          _EditUserNameDialog(initialName: StorageService.instance.userName),
    );

    if (newName == null || newName == StorageService.instance.userName) {
      return;
    }

    await StorageService.instance.setUserName(newName);
    if (mounted) {
      setState(() {});
    }
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
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // User profile display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _editUserName,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: ElioColors.darkPrimaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: ElioColors.darkPrimaryText.withOpacity(0.55),
                        ),
                      ],
                    ),
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

class _EditUserNameDialog extends StatefulWidget {
  const _EditUserNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditUserNameDialog> createState() => _EditUserNameDialogState();
}

class _EditUserNameDialogState extends State<_EditUserNameDialog> {
  late final TextEditingController _controller;
  late bool _canSave;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _canSave = _controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    final canSave = value.trim().isNotEmpty;
    if (canSave != _canSave) {
      setState(() => _canSave = canSave);
    }
  }

  void _save() {
    if (_canSave) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ElioColors.darkSurface,
      title: Text(
        'Edit name',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: ElioColors.darkPrimaryText),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        keyboardAppearance: Brightness.dark,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: ElioColors.darkPrimaryText),
        decoration: InputDecoration(
          hintText: 'Your name',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ElioColors.darkPrimaryText.withOpacity(0.5),
          ),
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: ElioColors.darkPrimaryText.withOpacity(0.25),
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: ElioColors.darkAccent),
          ),
        ),
        textInputAction: TextInputAction.done,
        onChanged: _onNameChanged,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: ElioColors.darkPrimaryText.withOpacity(0.8),
            ),
          ),
        ),
        TextButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
