import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/direction_check_in.dart';
import '../models/reflection_question.dart';
import '../services/reflection_service.dart';
import '../theme/elio_colors.dart';
import '../widgets/answered_question_chip.dart';
import 'confirmation_screen.dart';

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

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({
    super.key,
    required this.moodValue,
    required this.moodWord,
    required this.intention,
    this.directionCheckIns = const [],
  });

  final double moodValue;
  final String moodWord;
  final String intention;
  final List<DirectionCheckInDraft> directionCheckIns;

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<_AnsweredQuestion> _answeredQuestions = [];
  final List<String> _answeredQuestionIds = [];

  ReflectionQuestion? _currentQuestion;
  bool _hasText = false;
  int _currentGoalIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    if (!_isGoalReflection) {
      try {
        _loadNextQuestion();
      } catch (e) {
        debugPrint('Error loading reflection questions: $e');
        // If there's an error loading questions, skip to confirmation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToConfirmation();
          }
        });
        return;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _loadNextQuestion() {
    final question = ReflectionService.instance.getNextQuestion(
      _answeredQuestionIds,
    );
    setState(() {
      _currentQuestion = question;
    });
  }

  bool get _canAddMore => _answeredQuestions.length < 3;
  bool get _canAddAnotherAfterCurrent => _answeredQuestions.length < 2;
  bool get _hasAnsweredThree => _answeredQuestions.length >= 3;
  bool get _isGoalReflection => _goalReflectionDrafts.isNotEmpty;
  List<DirectionCheckInDraft> get _goalReflectionDrafts =>
      widget.directionCheckIns.where((draft) => draft.wantsReflection).toList();
  DirectionCheckInDraft? get _currentGoalDraft {
    if (!_isGoalReflection ||
        _currentGoalIndex >= _goalReflectionDrafts.length) {
      return null;
    }
    return _goalReflectionDrafts[_currentGoalIndex];
  }

  Future<void> _answerQuestion() async {
    if (_isGoalReflection) {
      await _answerGoalQuestion();
      return;
    }

    if (_currentQuestion == null || !_hasText) return;

    HapticFeedback.selectionClick();

    final answer = _controller.text.trim();
    final question = _currentQuestion!;

    setState(() {
      _answeredQuestions.add(
        _AnsweredQuestion(
          questionId: question.id,
          questionText: question.text,
          answer: answer,
        ),
      );
      _answeredQuestionIds.add(question.id);
      _controller.clear();
    });

    if (_canAddMore) {
      _loadNextQuestion();
    } else {
      setState(() => _currentQuestion = null);
    }
  }

  Future<void> _continue() async {
    HapticFeedback.selectionClick();

    if (_isGoalReflection) {
      if (_hasText) {
        await _answerGoalQuestion();
      } else {
        _navigateToConfirmation();
      }
      return;
    }

    // Save current answer if there's text in the field
    if (_currentQuestion != null && _hasText) {
      final answer = _controller.text.trim();
      final question = _currentQuestion!;

      setState(() {
        _answeredQuestions.add(
          _AnsweredQuestion(
            questionId: question.id,
            questionText: question.text,
            answer: answer,
          ),
        );
        _answeredQuestionIds.add(question.id);
      });
    }

    _navigateToConfirmation();
  }

  Future<void> _answerGoalQuestion() async {
    final draft = _currentGoalDraft;
    if (draft == null || !_hasText) return;

    HapticFeedback.selectionClick();

    final questionText = _goalQuestionText(draft);
    setState(() {
      _answeredQuestions.add(
        _AnsweredQuestion(
          questionId: _goalQuestionId(draft.directionId),
          questionText: questionText,
          answer: _controller.text.trim(),
          directionId: draft.directionId,
        ),
      );
      _controller.clear();
    });

    if (_currentGoalIndex < _goalReflectionDrafts.length - 1) {
      setState(() => _currentGoalIndex++);
    } else {
      _navigateToConfirmation();
    }
  }

  void _skipCurrentGoalQuestion() {
    HapticFeedback.lightImpact();
    if (_currentGoalIndex < _goalReflectionDrafts.length - 1) {
      setState(() {
        _currentGoalIndex++;
        _controller.clear();
      });
    } else {
      _navigateToConfirmation();
    }
  }

  void _navigateToConfirmation() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _checkInRoute(
        ConfirmationScreen(
          moodWord: widget.moodWord,
          moodValue: widget.moodValue,
          intentionText: widget.intention,
          directionCheckIns: widget.directionCheckIns,
          answeredQuestions: _answeredQuestions
              .map(
                (aq) => _TempAnswer(
                  questionId: aq.questionId,
                  questionText: aq.questionText,
                  answer: aq.answer,
                  directionId: aq.directionId,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _skipForNow() {
    if (_isGoalReflection) {
      _skipCurrentGoalQuestion();
    } else {
      HapticFeedback.lightImpact();
      _navigateToConfirmation();
    }
  }

  String _goalQuestionId(String directionId) => 'direction_goal:$directionId';

  String _goalQuestionText(DirectionCheckInDraft draft) {
    if (draft.hasBlocker) {
      return 'What would make ${draft.directionTitle} feel 10% easier?';
    }
    return 'What did this step teach you about ${draft.directionTitle}?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Previous answers (collapsed)
            if (_answeredQuestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (final answered in _answeredQuestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnsweredQuestionChip(
                          questionText: answered.questionText,
                          answer: answered.answer,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // Current question
            if (_isGoalReflection && _currentGoalDraft != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Reflecting on ${_currentGoalDraft!.directionTitle}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ElioColors.darkPrimaryText.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _goalQuestionText(_currentGoalDraft!),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildAnswerField(),
            ] else if (_currentQuestion != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _currentQuestion!.text,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildAnswerField(),
            ],

            const Spacer(),

            _buildActions(),

            // Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Center(
                child: TextButton(
                  onPressed: _skipForNow,
                  child: Text(
                    'Skip for now',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ElioColors.darkPrimaryText.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _ReflectionScreenState {
  Widget _buildActions() {
    final canContinue = _isGoalReflection
        ? _hasText
        : (_hasAnsweredThree || _answeredQuestions.isNotEmpty || _hasText);
    final canAddAnother =
        !_isGoalReflection &&
        _canAddAnotherAfterCurrent &&
        _currentQuestion != null &&
        _hasText;

    if (canAddAnother) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                label: 'Continue',
                onPressed: canContinue ? _continue : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPrimaryButton(
                label: '+ Another question',
                onPressed: _answerQuestion,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: _buildPrimaryButton(
        label: _isGoalReflection ? 'Save answer' : 'Continue',
        onPressed: canContinue ? _continue : null,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return ElioColors.darkAccent.withOpacity(0.4);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE5562E);
            }
            return ElioColors.darkAccent;
          }),
          foregroundColor: WidgetStateProperty.all(ElioColors.darkPrimaryText),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          elevation: WidgetStateProperty.all(0),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ElioColors.darkPrimaryText,
          disabledForegroundColor: ElioColors.darkPrimaryText.withOpacity(0.35),
          side: BorderSide(color: ElioColors.darkPrimaryText.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildAnswerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: ElioColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: 3,
          maxLength: 200,
          keyboardAppearance: Brightness.dark,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: ElioColors.darkPrimaryText),
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ElioColors.darkPrimaryText.withOpacity(0.5),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: ElioColors.darkAccent,
                width: 1,
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _hasText ? _answerQuestion() : null,
        ),
      ),
    );
  }
}

class _AnsweredQuestion {
  _AnsweredQuestion({
    required this.questionId,
    required this.questionText,
    required this.answer,
    this.directionId,
  });

  final String questionId;
  final String questionText;
  final String answer;
  final String? directionId;
}

class _TempAnswer {
  _TempAnswer({
    required this.questionId,
    required this.questionText,
    required this.answer,
    this.directionId,
  });

  final String questionId;
  final String questionText;
  final String answer;
  final String? directionId;
}
