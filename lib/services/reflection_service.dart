import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/reflection_answer.dart';
import '../models/reflection_question.dart';

class ReflectionService {
  ReflectionService._();

  static final ReflectionService instance = ReflectionService._();

  static const _questionsBoxName = 'reflectionQuestions';
  static const _answersBoxName = 'reflectionAnswers';
  static const _uuid = Uuid();

  Box<ReflectionQuestion>? _questionsBox;
  Box<ReflectionAnswer>? _answersBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(ReflectionQuestionAdapter().typeId)) {
      Hive.registerAdapter(ReflectionQuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(ReflectionAnswerAdapter().typeId)) {
      Hive.registerAdapter(ReflectionAnswerAdapter());
    }
    _questionsBox = await Hive.openBox<ReflectionQuestion>(_questionsBoxName);
    _answersBox = await Hive.openBox<ReflectionAnswer>(_answersBoxName);

    await _initializeQuestions();
  }

  Future<void> _initializeQuestions() async {
    if (_questions.isEmpty) {
      await _seedQuestionLibrary();
    }
  }

  Future<void> _seedQuestionLibrary() async {
    final now = DateTime.now();
    final questions = [
      // ELIO ESSENTIALS (isSelected: true)
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What are you grateful for today?",
        category: "gratitude",
        isCustom: false,
        isFavorite: false,
        isSelected: true,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What's one thing you're proud of today?",
        category: "pride",
        isCustom: false,
        isFavorite: false,
        isSelected: true,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What gave you energy today?",
        category: "energy",
        isCustom: false,
        isFavorite: false,
        isSelected: true,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What did you learn today?",
        category: "learning",
        isCustom: false,
        isFavorite: false,
        isSelected: true,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What are you looking forward to?",
        category: "tomorrow",
        isCustom: false,
        isFavorite: false,
        isSelected: true,
        createdAt: now,
      ),

      // REST OF LIBRARY (isSelected: false)
      // Gratitude
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What good thing happened today?",
        category: "gratitude",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "Who helped you today?",
        category: "gratitude",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Pride & Wins
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What went well today?",
        category: "pride",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What small win did you have today?",
        category: "pride",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Learning & Growth
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What surprised you today?",
        category: "learning",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What insight did you gain today?",
        category: "learning",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Energy & Awareness
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What drained your energy today?",
        category: "energy",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "When did you feel your best today?",
        category: "energy",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Tomorrow & Forward
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What would you do differently tomorrow?",
        category: "tomorrow",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What's your intention for tomorrow?",
        category: "tomorrow",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Connection
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "Who made you smile today?",
        category: "connection",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "Who would you like to thank today?",
        category: "connection",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "Did you have a meaningful conversation today?",
        category: "connection",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Self-care
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "Did you do something for yourself today?",
        category: "selfcare",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "How did you take care of yourself today?",
        category: "selfcare",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "Did you allow yourself to rest today?",
        category: "selfcare",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Reflection
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What would you do differently today?",
        category: "reflection",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What frustrated you today?",
        category: "reflection",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What lesson are you taking from today?",
        category: "reflection",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),

      // Presence
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What moment do you want to remember?",
        category: "presence",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "When were you fully present today?",
        category: "presence",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
      ReflectionQuestion(
        id: _uuid.v4(),
        text: "What made today unique?",
        category: "presence",
        isCustom: false,
        isFavorite: false,
        isSelected: false,
        createdAt: now,
      ),
    ];

    for (final question in questions) {
      await _questions.put(question.id, question);
    }
  }

  ReflectionQuestion? getNextQuestion(List<String> alreadyAnsweredIds) {
    final pool = _questions.values.where((q) => q.isSelected).toList();

    if (pool.isEmpty) return null;

    // 1. Get favorites first (not already answered)
    final favorites = pool
        .where((q) => q.isFavorite && !alreadyAnsweredIds.contains(q.id))
        .toList();

    if (favorites.isNotEmpty) {
      return favorites.first;
    }

    // 2. Get rotating questions
    final rotating = pool
        .where((q) => !q.isFavorite && !alreadyAnsweredIds.contains(q.id))
        .toList();

    if (rotating.isEmpty) return null;

    // 3. Pick based on day (deterministic rotation)
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % rotating.length;

    return rotating[index];
  }

  Future<ReflectionAnswer> saveAnswer({
    required String entryId,
    required String questionId,
    required String questionText,
    required String answer,
  }) async {
    final reflectionAnswer = ReflectionAnswer(
      id: _uuid.v4(),
      entryId: entryId,
      questionId: questionId,
      questionText: questionText,
      answer: answer,
      createdAt: DateTime.now(),
    );

    await _answers.put(reflectionAnswer.id, reflectionAnswer);
    return reflectionAnswer;
  }

  List<ReflectionQuestion> getAllQuestions() {
    return _questions.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<ReflectionQuestion> getSelectedQuestions() {
    return _questions.values.where((q) => q.isSelected).toList()
      ..sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  List<ReflectionQuestion> getFavoriteQuestions() {
    return _questions.values.where((q) => q.isFavorite).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Map<String, List<ReflectionQuestion>> getQuestionsByCategory() {
    final Map<String, List<ReflectionQuestion>> grouped = {};

    for (final question in _questions.values) {
      if (!grouped.containsKey(question.category)) {
        grouped[question.category] = [];
      }
      grouped[question.category]!.add(question);
    }

    return grouped;
  }

  Future<void> toggleFavorite(String questionId) async {
    final question = _questions.get(questionId);
    if (question == null) return;

    final favorites = getFavoriteQuestions();

    // If trying to favorite and already have 2 favorites, don't allow
    if (!question.isFavorite && favorites.length >= 2) {
      return;
    }

    final updated = question.copyWith(isFavorite: !question.isFavorite);
    await _questions.put(questionId, updated);
  }

  Future<void> toggleSelected(String questionId) async {
    final question = _questions.get(questionId);
    if (question == null) return;

    final updated = question.copyWith(isSelected: !question.isSelected);
    await _questions.put(questionId, updated);

    // If deselecting a favorite, also unfavorite it
    if (!updated.isSelected && updated.isFavorite) {
      final unfavorited = updated.copyWith(isFavorite: false);
      await _questions.put(questionId, unfavorited);
    }
  }

  Future<void> addCustomQuestion({
    required String text,
    required String category,
  }) async {
    final question = ReflectionQuestion(
      id: _uuid.v4(),
      text: text,
      category: category,
      isCustom: true,
      isFavorite: false,
      isSelected: true,
      createdAt: DateTime.now(),
    );

    await _questions.put(question.id, question);
  }

  Future<void> deleteQuestion(String questionId) async {
    final question = _questions.get(questionId);
    if (question == null || !question.isCustom) return;

    await _questions.delete(questionId);
  }

  List<ReflectionAnswer> getAnswersByIds(List<String> answerIds) {
    final answers = <ReflectionAnswer>[];
    for (final id in answerIds) {
      final answer = _answers.get(id);
      if (answer != null) {
        answers.add(answer);
      }
    }
    return answers;
  }

  Box<ReflectionQuestion> get _questions {
    final box = _questionsBox;
    if (box == null) {
      throw StateError('ReflectionService not initialized. Call init() first.');
    }
    return box;
  }

  Box<ReflectionAnswer> get _answers {
    final box = _answersBox;
    if (box == null) {
      throw StateError('ReflectionService not initialized. Call init() first.');
    }
    return box;
  }
}
