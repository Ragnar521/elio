import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/direction.dart';
import '../models/direction_check_in.dart';
import '../services/direction_service.dart';
import '../services/storage_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/direction_icon.dart';
import 'confirmation_screen.dart';
import 'reflection_screen.dart';

Route _checkInRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(0.0, 0.15),
        end: Offset.zero,
      );
      final slideAnimation = animation.drive(
        slideTween.chain(CurveTween(curve: Curves.easeInOut)),
      );
      final fadeAnimation = animation.drive(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      );
      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(opacity: fadeAnimation, child: child),
      );
    },
  );
}

class DirectionCheckInScreen extends StatefulWidget {
  const DirectionCheckInScreen({
    super.key,
    required this.moodValue,
    required this.moodWord,
    required this.intention,
  });

  final double moodValue;
  final String moodWord;
  final String intention;

  @override
  State<DirectionCheckInScreen> createState() => _DirectionCheckInScreenState();
}

class _DirectionCheckInScreenState extends State<DirectionCheckInScreen> {
  late final List<Direction> _directions;
  final Set<String> _selectedIds = {};
  final Set<String> _reflectionIds = {};
  final Map<String, TextEditingController> _stepControllers = {};
  final Map<String, TextEditingController> _blockerControllers = {};
  final Map<String, TextEditingController> _supportControllers = {};

  @override
  void initState() {
    super.initState();
    _directions = DirectionService.instance.getActiveDirections();
  }

  @override
  void dispose() {
    for (final controller in [
      ..._stepControllers.values,
      ..._blockerControllers.values,
      ..._supportControllers.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Did any goal show up today?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Pick what was present. Details are optional.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ElioColors.darkPrimaryText.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _directions.map(_buildDirectionChip).toList(),
                  ),
                  const SizedBox(height: 20),
                  ..._selectedDirections.map(_buildSelectedDirectionCard),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      ElioColors.darkAccent,
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      ElioColors.darkPrimaryText,
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Direction> get _selectedDirections {
    return _directions.where((d) => _selectedIds.contains(d.id)).toList();
  }

  Widget _buildDirectionChip(Direction direction) {
    final isSelected = _selectedIds.contains(direction.id);

    return FilterChip(
      selected: isSelected,
      avatar: DirectionIcon(type: direction.type, size: 20),
      label: Text(direction.title),
      onSelected: (_) => _toggleDirection(direction),
      selectedColor: ElioColors.darkAccent.withOpacity(0.25),
      checkmarkColor: ElioColors.darkAccent,
      labelStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: ElioColors.darkPrimaryText),
    );
  }

  Widget _buildSelectedDirectionCard(Direction direction) {
    final wantsReflection = _reflectionIds.contains(direction.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DirectionIcon(type: direction.type, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    direction.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _toggleDirection(direction),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _controllerFor(_stepControllers, direction.id),
              label: 'One small step',
              hint: 'What moved this forward?',
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _controllerFor(_blockerControllers, direction.id),
              label: 'What blocked or scared me',
              hint: 'Friction, fear, uncertainty...',
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _controllerFor(_supportControllers, direction.id),
              label: 'What might help',
              hint: 'A person, resource, reminder, or smaller step',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: wantsReflection,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (value) {
                    _reflectionIds.add(direction.id);
                  } else {
                    _reflectionIds.remove(direction.id);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Reflect on this goal'),
              subtitle: const Text('Ask one gentle goal-specific question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      maxLength: 160,
      keyboardAppearance: Brightness.dark,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }

  TextEditingController _controllerFor(
    Map<String, TextEditingController> map,
    String directionId,
  ) {
    return map.putIfAbsent(directionId, TextEditingController.new);
  }

  void _toggleDirection(Direction direction) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(direction.id)) {
        _selectedIds.remove(direction.id);
        _reflectionIds.remove(direction.id);
      } else {
        _selectedIds.add(direction.id);
      }
    });
  }

  List<DirectionCheckInDraft> _drafts() {
    return _selectedDirections.map((direction) {
      return DirectionCheckInDraft(
        directionId: direction.id,
        directionTitle: direction.title,
        stepText: _stepControllers[direction.id]?.text.trim(),
        blockerText: _blockerControllers[direction.id]?.text.trim(),
        supportText: _supportControllers[direction.id]?.text.trim(),
        wantsReflection: _reflectionIds.contains(direction.id),
      );
    }).toList();
  }

  void _continue() {
    _navigateNext(_drafts());
  }

  void _navigateNext(List<DirectionCheckInDraft> drafts) {
    final hasGoalReflections = drafts.any((draft) => draft.wantsReflection);

    if (hasGoalReflections) {
      Navigator.of(context).push(
        _checkInRoute(
          ReflectionScreen(
            moodWord: widget.moodWord,
            moodValue: widget.moodValue,
            intention: widget.intention,
            directionCheckIns: drafts,
          ),
        ),
      );
      return;
    }

    if (StorageService.instance.reflectionEnabled) {
      Navigator.of(context).push(
        _checkInRoute(
          ReflectionScreen(
            moodWord: widget.moodWord,
            moodValue: widget.moodValue,
            intention: widget.intention,
            directionCheckIns: drafts,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      _checkInRoute(
        ConfirmationScreen(
          moodWord: widget.moodWord,
          moodValue: widget.moodValue,
          intentionText: widget.intention,
          directionCheckIns: drafts,
        ),
      ),
    );
  }
}
