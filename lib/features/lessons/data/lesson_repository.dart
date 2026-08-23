import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/lesson.dart';

class LessonFailure implements Exception {
  const LessonFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class LessonRepository {
  LessonRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Lesson>> fetchMyLessons({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LessonFailure('로그인이 필요합니다.');
    }

    try {
      final rows = await _client
          .from('lessons')
          .select(
            'id, teacher_id, occurrence_at, starts_at, duration_minutes, '
            'ends_at, lesson_type, status, lesson_right_id',
          )
          .eq('student_id', user.id)
          .gte('starts_at', from.toUtc().toIso8601String())
          .lt('starts_at', to.toUtc().toIso8601String())
          .order('starts_at');

      final lessons = (rows as List)
          .map(
            (row) => Lesson.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      final names = await _fetchVisibleProfileNames();

      return lessons
          .map(
            (lesson) => lesson.copyWithTeacherName(
              names[lesson.teacherId],
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    } catch (error) {
      throw LessonFailure('수업 정보를 불러오지 못했습니다.\n$error');
    }
  }

  Future<void> cancelLesson({
    required String lessonId,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'cancel_lesson',
        params: {
          'p_lesson_id': lessonId,
          'p_reason': _nullIfBlank(reason),
        },
      );
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    }
  }

  Future<List<LessonBookingOption>> getBookingOptions({
    required String rightId,
    required DateTime selectedDate,
  }) async {
    try {
      final data = await _client.rpc(
        'get_lesson_right_booking_options',
        params: {
          'p_right_id': rightId,
          'p_selected_date': _dateText(selectedDate),
        },
      );

      return (data as List)
          .map(
            (row) => LessonBookingOption.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    }
  }

  Future<void> bookLessonRight({
    required String rightId,
    required DateTime startsAt,
  }) async {
    try {
      await _client.rpc(
        'book_lesson_right',
        params: {
          'p_right_id': rightId,
          'p_new_starts_at': startsAt.toUtc().toIso8601String(),
        },
      );
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    }
  }

  Future<Map<String, String>> _fetchVisibleProfileNames() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id, display_name');

      return {
        for (final row in rows as List)
          row['id'] as String: row['display_name'] as String,
      };
    } on PostgrestException {
      return const {};
    }
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _dateText(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _friendlyMessage(String message) {
    if (message.contains('FORESTRING_EFFECTIVE_ACCESS_REQUIRED')) {
      return '현재 계정은 더 이상 사용할 수 없습니다.';
    }
    if (message.contains('FORESTRING_LESSON_NOT_FOUND')) {
      return '수업을 찾을 수 없습니다.';
    }
    if (message.contains('FORESTRING_CANCEL') ||
        message.contains('QUOTA') ||
        message.contains('CANCELLATION')) {
      return '현재 정책상 이 수업을 취소할 수 없습니다.';
    }
    if (message.contains('FORESTRING_')) {
      return '요청을 처리할 수 없습니다. ($message)';
    }
    return '요청 처리 중 오류가 발생했습니다.';
  }
}
