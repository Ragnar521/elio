import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hive/hive.dart';

import '../models/entry.dart';
import '../services/reflection_service.dart';
import '../services/storage_service.dart';
import '../services/nudge_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/answered_question_chip.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({
    super.key,
    required this.moodValue,
    required this.moodWord,
    required this.intentionText,
    this.streakCount,
    this.answeredQuestions,
  });

  final double moodValue;
  final String moodWord;
  final String intentionText;
  final int? streakCount;
  final List<dynamic>? answeredQuestions;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _affirmOpacity;
  late final Animation<double> _summaryOpacity;
  late final Animation<double> _buttonOpacity;

  bool _canDismiss = false;
  int? _streakCount;

  static const _affirmations = [
    'You checked in.',
    'Noted.',
    'Clarity captured.',
    'You showed up.',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glowScale = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );
    _glowOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic)),
    );
    _affirmOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic)),
    );
    _summaryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic)),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic)),
    );

    _saveEntryAndStart();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 1)}…';
  }

  String get _affirmation {
    final index = DateTime.now().millisecond % _affirmations.length;
    return _affirmations[index];
  }

  String get _streakLabel {
    final count = _streakCount ?? widget.streakCount ?? 1;
    if (count <= 1) return 'Day 1 — here we go';
    if (count == 2) return '2 day streak';
    return '$count day streak';
  }

  void _closeFlow() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _saveEntryAndStart() async {
    List<String>? reflectionAnswerIds;

    try {
      // Save the entry first to get its ID
      final entry = await StorageService.instance.saveEntry(
        moodValue: widget.moodValue,
        moodWord: widget.moodWord,
        intention: widget.intentionText,
      );

      // Save reflection answers if any, using the entry ID
      if (widget.answeredQuestions != null && widget.answeredQuestions!.isNotEmpty) {
        final answerIds = <String>[];
        for (final aq in widget.answeredQuestions!) {
          final answer = await ReflectionService.instance.saveAnswer(
            entryId: entry.id,
            questionId: aq.questionId as String,
            questionText: aq.questionText as String,
            answer: aq.answer as String,
          );
          answerIds.add(answer.id);
        }
        reflectionAnswerIds = answerIds;

        // Update the entry with reflection answer IDs
        final updatedEntry = Entry(
          id: entry.id,
          moodValue: entry.moodValue,
          moodWord: entry.moodWord,
          intention: entry.intention,
          createdAt: entry.createdAt,
          reflectionAnswerIds: reflectionAnswerIds,
        );

        // Save the updated entry
        await Hive.box<Entry>('entries').put(entry.id, updatedEntry);
      }
    } catch (e) {
      debugPrint('Error saving entry: $e');
    }

    try {
      _streakCount = await StorageService.instance.getCurrentStreak();
    } catch (_) {}

    // Evaluate post-check-in nudges (non-blocking)
    _evaluatePostCheckInNudges();

    if (!mounted) return;
    setState(() {});

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) HapticFeedback.selectionClick();
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _canDismiss = true);
    });
  }

  Future<void> _evaluatePostCheckInNudges() async {
    try {
      final currentStreak = _streakCount ?? await StorageService.instance.getCurrentStreak();
      final nudge = await NudgeService.instance.checkPostCheckIn(currentStreak);
      if (nudge != null) {
        NudgeService.instance.setPendingNudge(nudge);
      }
    } catch (e) {
      debugPrint('Error evaluating post-check-in nudges: $e');
      // Non-critical, don't block confirmation flow
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _canDismiss ? _closeFlow : null,
          child: Column(
            children: [
              const SizedBox(height: 40),
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
                opacity: _affirmOpacity,
                child: Text(
                  _affirmation,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ElioColors.darkPrimaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _summaryOpacity,
                child: Column(
                  children: [
                    Text(
                      'Feeling ${widget.moodWord}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _truncate(widget.intentionText, 50),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.answeredQuestions != null &&
                        widget.answeredQuestions!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: widget.answeredQuestions!
                              .map((aq) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AnsweredQuestionChip(
                                      questionText: aq.questionText as String,
                                      answer: aq.answer as String,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _streakLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: ElioColors.darkPrimaryText.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _buttonOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _closeFlow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ElioColors.darkPrimaryText,
                        side: BorderSide(color: ElioColors.darkPrimaryText.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
