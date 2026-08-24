import 'lesson.dart';

class LessonHistoryData {
  const LessonHistoryData({
    required this.studentId,
    required this.studentType,
    required this.semesters,
  });

  final String studentId;
  final String studentType;
  final List<SemesterLessonHistory> semesters;

  bool get isRegular => studentType == 'regular';
  bool get isFlex => studentType == 'flex';

  String get studentTypeLabel => isFlex ? '비정규 수강생' : '정규 수강생';

  SemesterLessonHistory? get currentSemester {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final semester in semesters) {
      if (!today.isBefore(semester.startsOn) &&
          !today.isAfter(semester.endsOn)) {
        return semester;
      }
    }
    return null;
  }

  List<SemesterLessonHistory> get pastSemesters {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return semesters
        .where((semester) => semester.endsOn.isBefore(today))
        .toList();
  }
}

class SemesterLessonHistory {
  const SemesterLessonHistory({
    required this.id,
    required this.code,
    required this.startsOn,
    required this.endsOn,
    required this.rights,
  });

  final String id;
  final String code;
  final DateTime startsOn;
  final DateTime endsOn;
  final List<LessonRightHistory> rights;

  int get totalRights => rights.length;
  int get reservedRights =>
      rights.where((right) => right.status == 'reserved').length;
  int get availableRights =>
      rights.where((right) => right.status == 'available').length;
  int get consumedRights =>
      rights.where((right) => right.status == 'consumed').length;
  int get studentCancellationCount => rights.fold(
        0,
        (sum, right) => sum + right.studentCancellationCount,
      );
}

class LessonRightHistory {
  const LessonRightHistory({
    required this.id,
    required this.origin,
    required this.status,
    required this.sequenceNo,
    required this.durationMinutes,
    required this.cancellations,
    this.reservedAt,
    this.lesson,
  });

  final String id;
  final String origin;
  final String status;
  final int sequenceNo;
  final int durationMinutes;
  final DateTime? reservedAt;
  final Lesson? lesson;
  final List<LessonCancellationHistory> cancellations;

  int get cancellationCount => cancellations.length;
  int get studentCancellationCount =>
      cancellations.where((event) => event.origin == 'student').length;
  int get academyCancellationCount =>
      cancellations.where((event) => event.origin == 'academy').length;

  bool get wasCanceled => cancellations.isNotEmpty;

  bool get isRebooked =>
      wasCanceled &&
      status == 'reserved' &&
      lesson != null &&
      !lesson!.isCanceled &&
      lesson!.rescheduledBy != null;

  LessonCancellationHistory? get latestCancellation {
    if (cancellations.isEmpty) {
      return null;
    }
    final sorted = [...cancellations]
      ..sort((a, b) => b.canceledAt.compareTo(a.canceledAt));
    return sorted.first;
  }

  DateTime? get originalStartsAt {
    final value = lesson;
    if (value == null) {
      return null;
    }
    return value.occurrenceAt ?? value.startsAt;
  }

  DateTime? get currentStartsAt => lesson?.startsAt;
  DateTime? get currentEndsAt => lesson?.endsAt;

  String bookingActorLabel(String studentId) {
    final actorId = lesson?.rescheduledBy;
    if (actorId == null) {
      return '';
    }
    return actorId == studentId ? '본인' : '학원 관리자';
  }

  String get statusLabel {
    if (isRebooked) {
      return '재예약 완료';
    }

    return switch (status) {
      'available' => wasCanceled ? '재예약 대기' : '사용 가능',
      'reserved' => '예약됨',
      'consumed' => '사용 완료',
      'expired' => '기간 종료',
      'revoked' => '회수됨',
      _ => status,
    };
  }

  String get originLabel {
    return switch (origin) {
      'regular_base' => '정규 수강권',
      'flex_base' => '예약 수업권',
      'carryover' => '보강 수업권',
      _ => '수강권',
    };
  }
}

class LessonCancellationHistory {
  const LessonCancellationHistory({
    required this.origin,
    required this.actorId,
    required this.canceledAt,
    required this.countsTowardLimit,
    this.lessonStartsAt,
    this.lessonDurationMinutes,
  });

  final String origin;
  final String actorId;
  final DateTime canceledAt;
  final bool countsTowardLimit;
  final DateTime? lessonStartsAt;
  final int? lessonDurationMinutes;

  String actorLabel(String studentId) {
    if (actorId == studentId || origin == 'student') {
      return '본인';
    }
    return '학원 관리자';
  }
}
