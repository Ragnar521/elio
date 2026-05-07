import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
import '../theme/elio_colors.dart';
import 'reflection_settings_screen.dart';

const _supportEmail = 'support@elio.app';

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

  Future<void> _showHelpAndFeedbackSheet() async {
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ElioColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    color: ElioColors.darkPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Send a message about an issue, question, or idea. Your email app will open with a few details filled in.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openSupportEmail();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ElioColors.darkAccent,
                      foregroundColor: ElioColors.darkBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Open email'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: ElioColors.darkPrimaryText.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSupportEmail() async {
    HapticFeedback.selectionClick();

    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: const {
        'subject': 'Elio feedback',
        'body': '''
What happened?

What did you expect?

Anything else that might help?

App: Elio 1.0.0+1
''',
      },
    );

    bool didLaunch = false;
    try {
      didLaunch = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      didLaunch = false;
    }

    if (!mounted || didLaunch) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open your email app.')),
    );
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
                  'Your name',
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
            const SizedBox(height: 24),

            Text(
              'Help & feedback',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ElioColors.darkPrimaryText.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showHelpAndFeedbackSheet,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: ElioColors.darkPrimaryText.withOpacity(0.7),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send feedback or ask for help',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: ElioColors.darkPrimaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Report an issue, share an idea, or ask a question.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ElioColors.darkPrimaryText.withOpacity(
                                    0.6,
                                  ),
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chevron_right,
                      color: ElioColors.darkPrimaryText.withOpacity(0.45),
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
