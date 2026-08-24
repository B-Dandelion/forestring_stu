import 'package:flutter/foundation.dart';

import '../data/lesson_repository.dart';
import '../domain/lesson.dart';
import '../domain/lesson_history.dart';

class LessonController extends ChangeNotifier {
  LessonController(this._repository);

  final LessonRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Lesson> _lessons = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Lesson> get lessons => _lessons;

  List<Lesson> get canceledLessons => _lessons
      .where(
        (lesson) => lesson.isCanceled && lesson.lessonRightId != null,
      )
      .toList();

  Future<void> initialize() async {
    await reload();
  }

  Future<void> reload() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month - 2, 1);
      final to = DateTime(now.year, now.month + 4, 1);

      _lessons = await _repository.fetchMyLessons(
        from: from,
        to: to,
      );
    } on LessonFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '수업 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LessonHistoryData> fetchLessonHistory() {
    return _repository.fetchMyLessonHistory();
  }

  Future<List<LessonRightHistory>> fetchAvailableBookingRights() async {
    final history = await _repository.fetchMyLessonHistory();
    final semester = history.currentSemester;
    if (semester == null) {
      return const [];
    }

    return semester.rights
        .where((right) => right.status == 'available')
        .toList();
  }

  List<Lesson> lessonsOn(DateTime date) {
    return _lessons.where((lesson) {
      if (lesson.isCanceled) {
        return false;
      }

      final local = lesson.startsAt;
      return local.year == date.year &&
          local.month == date.month &&
          local.day == date.day;
    }).toList();
  }

  Future<bool> cancelLesson(Lesson lesson) async {
    try {
      await _repository.cancelLesson(
        lessonId: lesson.id,
        reason: '학생 앱에서 수업 취소',
      );
      await reload();
      return true;
    } on LessonFailure catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<LessonBookingWindow> getBookingWindow(String rightId) async {
    return _repository.getBookingWindow(rightId: rightId);
  }

  Future<List<LessonBookingOption>> getBookingOptions({
    required String rightId,
    required DateTime selectedDate,
  }) async {
    return _repository.getBookingOptions(
      rightId: rightId,
      selectedDate: selectedDate,
    );
  }

  Future<bool> bookLessonRight({
    required String rightId,
    required LessonBookingOption option,
  }) async {
    try {
      await _repository.bookLessonRight(
        rightId: rightId,
        startsAt: option.startsAt,
      );
      await reload();
      return true;
    } on LessonFailure catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }
}
