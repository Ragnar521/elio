import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../models/reflection_answer.dart';
import '../models/reflection_question.dart';
import '../services/reflection_service.dart';
import '../services/storage_service.dart';
import '../theme/elio_colors.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.entry,
    required this.timeLabel,
    required this.dateLabel,
    required this.moodColor,
    this.onUndoDelete,
  });

  final Entry entry;
  final String timeLabel;
  final String dateLabel;
  final Color moodColor;
  final VoidCallback? onUndoDelete;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _isEditMode = false;
  late TextEditingController _intentionController;
  late double _editedMoodValue;
  late String _editedMoodWord;
  late List<ReflectionAnswer> _reflectionAnswers;
  late Entry _currentEntry;
  bool _hasChanges = false;

  // Controllers for existing reflection answers
  final Map<String, TextEditingController> _answerControllers = {};

  // Newly added answers (not yet saved)
  final List<_NewAnswer> _newAnswers = [];

  static const _moodWords = [
    'Heavy',
    'Tired',
    'Flat',
    'Okay',
    'Calm',
    'Good',
    'Energized',
    'Great',
  ];

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _intentionController = TextEditingController(text: _currentEntry.intention);
    _editedMoodValue = _currentEntry.moodValue;
    _editedMoodWord = _currentEntry.moodWord;
    _loadReflectionAnswers();
  }

  void _loadReflectionAnswers() {
    _reflectionAnswers = _currentEntry.reflectionAnswerIds != null
        ? ReflectionService.instance.getAnswersByIds(_currentEntry.reflectionAnswerIds!)
        : <ReflectionAnswer>[];

    // Create controllers for each existing answer
    for (final answer in _reflectionAnswers) {
      _answerControllers[answer.id] = TextEditingController(text: answer.answer);
    }
  }

  @override
  void dispose() {
    _intentionController.dispose();
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    for (final newAnswer in _newAnswers) {
      newAnswer.controller.dispose();
    }
    super.dispose();
  }

  String _moodWordFor(double value) {
    final moodWordIndex = (value * (_moodWords.length - 1)).round();
    return _moodWords[moodWordIndex];
  }

  Color _moodGlow(double value) {
    const low = Color(0xFF4B5A68);
    const high = ElioColors.darkAccent;
    return Color.lerp(low, high, value) ?? high;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _cancelEdit() {
    setState(() {
      // Reset all values to current entry
      _intentionController.text = _currentEntry.intention;
      _editedMoodValue = _currentEntry.moodValue;
      _editedMoodWord = _currentEntry.moodWord;

      // Reset reflection answer controllers to original values
      for (var i = 0; i < _reflectionAnswers.length; i++) {
        final answer = _reflectionAnswers[i];
        _answerControllers[answer.id]?.text = answer.answer;
      }

      // Remove any newly added (unsaved) answers
      for (final newAnswer in _newAnswers) {
        newAnswer.controller.dispose();
      }
      _newAnswers.clear();

      _isEditMode = false;
    });
  }

  Future<void> _saveChanges() async {
    // Create updated Entry with edited values
    final updatedEntry = Entry(
      id: _currentEntry.id,
      moodValue: _editedMoodValue,
      moodWord: _editedMoodWord,
      intention: _intentionController.text,
      createdAt: _currentEntry.createdAt,
      reflectionAnswerIds: _currentEntry.reflectionAnswerIds,
      isDeleted: _currentEntry.isDeleted,
      deletedAt: _currentEntry.deletedAt,
      updatedAt: DateTime.now(),
    );

    // Save the entry
    await StorageService.instance.updateEntry(updatedEntry);

    // Update existing answers if modified
    for (var i = 0; i < _reflectionAnswers.length; i++) {
      final answer = _reflectionAnswers[i];
      final controller = _answerControllers[answer.id];
      if (controller != null && controller.text != answer.answer) {
        await ReflectionService.instance.updateAnswer(
          answerId: answer.id,
          newAnswerText: controller.text,
        );
      }
    }

    // Save new answers and add their IDs to entry
    final List<String> answerIds = List.from(_currentEntry.reflectionAnswerIds ?? []);
    for (final newAnswer in _newAnswers) {
      final savedAnswer = await ReflectionService.instance.saveAnswer(
        entryId: _currentEntry.id,
        questionId: newAnswer.question.id,
        questionText: newAnswer.question.text,
        answer: newAnswer.controller.text,
      );
      answerIds.add(savedAnswer.id);
    }

    // If we added new answers, update the entry again with new answer IDs
    if (_newAnswers.isNotEmpty) {
      final entryWithAnswers = Entry(
        id: updatedEntry.id,
        moodValue: updatedEntry.moodValue,
        moodWord: updatedEntry.moodWord,
        intention: updatedEntry.intention,
        createdAt: updatedEntry.createdAt,
        reflectionAnswerIds: answerIds,
        isDeleted: updatedEntry.isDeleted,
        deletedAt: updatedEntry.deletedAt,
        updatedAt: updatedEntry.updatedAt,
      );
      await StorageService.instance.updateEntry(entryWithAnswers);
      setState(() {
        _currentEntry = entryWithAnswers;
      });
    } else {
      setState(() {
        _currentEntry = updatedEntry;
      });
    }

    // Reload reflection answers to show updated data
    _loadReflectionAnswers();

    // Clear new answers list
    for (final newAnswer in _newAnswers) {
      newAnswer.controller.dispose();
    }
    _newAnswers.clear();

    setState(() {
      _isEditMode = false;
      _hasChanges = true;
    });
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ElioColors.darkSurface,
        title: Text(
          'Delete entry?',
          style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                color: ElioColors.darkPrimaryText,
              ),
        ),
        content: Text(
          'Are you sure you want to delete this entry?',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                color: ElioColors.darkPrimaryText.withOpacity(0.8),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ElioColors.darkPrimaryText.withOpacity(0.8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: ElioColors.darkAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Soft delete the entry
      await StorageService.instance.softDeleteEntry(_currentEntry.id);

      // Capture the messenger and navigator before popping
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Pop the detail screen with result true
      navigator.pop(true);

      // Show undo snackbar
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          duration: const Duration(seconds: 5),
          backgroundColor: ElioColors.darkSurface,
          action: SnackBarAction(
            label: 'Undo',
            textColor: ElioColors.darkAccent,
            onPressed: () async {
              await StorageService.instance.restoreEntry(_currentEntry.id);
              widget.onUndoDelete?.call();
            },
          ),
        ),
      );
    }
  }

  void _addReflection() async {
    // Get already answered question IDs
    final answeredIds = [
      ..._reflectionAnswers.map((a) => a.questionId),
      ..._newAnswers.map((a) => a.question.id),
    ];

    // Get next available question
    final question = ReflectionService.instance.getNextQuestion(answeredIds);
    if (question == null) {
      // No more questions available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more questions available'),
          backgroundColor: ElioColors.darkSurface,
        ),
      );
      return;
    }

    setState(() {
      _newAnswers.add(_NewAnswer(
        question: question,
        controller: TextEditingController(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _isEditMode ? _moodGlow(_editedMoodValue) : widget.moodColor;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) {
        // If there are changes and we're popping, signal refresh
        if (!didPop && _hasChanges) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ElioColors.darkBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: ElioColors.darkPrimaryText),
            onPressed: () {
              if (_hasChanges) {
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _isEditMode ? 'Edit Entry' : 'Entry Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ElioColors.darkPrimaryText,
                ),
          ),
          actions: _isEditMode
              ? [
                  // Cancel icon
                  IconButton(
                    icon: const Icon(Icons.close, color: ElioColors.darkPrimaryText),
                    onPressed: _cancelEdit,
                  ),
                  // Save icon
                  IconButton(
                    icon: const Icon(Icons.check, color: ElioColors.darkAccent),
                    onPressed: _saveChanges,
                  ),
                ]
              : [
                  // Edit icon
                  IconButton(
                    icon: const Icon(Icons.edit, color: ElioColors.darkPrimaryText),
                    onPressed: _toggleEditMode,
                  ),
                  // Delete icon
                  IconButton(
                    icon: const Icon(Icons.delete, color: ElioColors.darkPrimaryText),
                    onPressed: _showDeleteDialog,
                  ),
                ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and time
                Text(
                  '${widget.dateLabel} • ${widget.timeLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 24),

                // Mood section
                _isEditMode ? _buildEditMoodSection() : _buildViewMoodSection(moodColor),

                const SizedBox(height: 24),

                // Intention section
                Text(
                  'INTENTION',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                _isEditMode ? _buildEditIntentionSection() : _buildViewIntentionSection(),

                // Reflections section
                if (_reflectionAnswers.isNotEmpty || _newAnswers.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'REFLECTIONS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ElioColors.darkPrimaryText.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _isEditMode ? _buildEditReflectionsSection() : _buildViewReflectionsSection(),
                ],

                // Add reflection button (only in edit mode and if < 3 total)
                if (_isEditMode &&
                    (_reflectionAnswers.length + _newAnswers.length) < 3) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addReflection,
                      icon: const Icon(Icons.add, color: ElioColors.darkAccent),
                      label: const Text(
                        'Add reflection',
                        style: TextStyle(color: ElioColors.darkAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ElioColors.darkAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewMoodSection(Color moodColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: moodColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Feeling ${_currentEntry.moodWord}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ElioColors.darkPrimaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mood intensity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentEntry.moodValue,
              backgroundColor: ElioColors.darkBackground,
              valueColor: AlwaysStoppedAnimation<Color>(moodColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMoodSection() {
    final glow = _moodGlow(_editedMoodValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: glow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Feeling $_editedMoodWord',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ElioColors.darkPrimaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: glow,
              inactiveTrackColor: ElioColors.darkPrimaryText.withOpacity(0.15),
              thumbColor: ElioColors.darkPrimaryText,
              overlayColor: glow.withOpacity(0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _editedMoodValue,
              onChanged: (value) {
                setState(() {
                  _editedMoodValue = value;
                  _editedMoodWord = _moodWordFor(value);
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Heavy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.5),
                      ),
                ),
                Text(
                  'Great',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ElioColors.darkPrimaryText.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewIntentionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _currentEntry.intention,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ElioColors.darkPrimaryText,
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildEditIntentionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _intentionController,
        maxLength: 100,
        maxLines: 3,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ElioColors.darkPrimaryText,
            ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: 'What do you want to focus on?',
          hintStyle: TextStyle(
            color: Color(0x99F9DFC1),
          ),
        ),
      ),
    );
  }

  Widget _buildViewReflectionsSection() {
    return Column(
      children: [
        for (final answer in _reflectionAnswers)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ElioColors.darkSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.question_answer,
                      size: 18,
                      color: ElioColors.darkAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        answer.questionText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ElioColors.darkPrimaryText.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    answer.answer,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ElioColors.darkPrimaryText,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditReflectionsSection() {
    return Column(
      children: [
        // Existing answers (editable)
        for (final answer in _reflectionAnswers)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ElioColors.darkSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.question_answer,
                      size: 18,
                      color: ElioColors.darkAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        answer.questionText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ElioColors.darkPrimaryText.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: TextField(
                    controller: _answerControllers[answer.id],
                    maxLength: 200,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ElioColors.darkPrimaryText,
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'Your reflection...',
                      hintStyle: TextStyle(
                        color: Color(0x99F9DFC1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // New answers (not yet saved)
        for (final newAnswer in _newAnswers)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ElioColors.darkSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.question_answer,
                      size: 18,
                      color: ElioColors.darkAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        newAnswer.question.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ElioColors.darkPrimaryText.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: TextField(
                    controller: newAnswer.controller,
                    maxLength: 200,
                    maxLines: 3,
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ElioColors.darkPrimaryText,
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'Your reflection...',
                      hintStyle: TextStyle(
                        color: Color(0x99F9DFC1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NewAnswer {
  _NewAnswer({required this.question, required this.controller});

  final ReflectionQuestion question;
  final TextEditingController controller;
}
