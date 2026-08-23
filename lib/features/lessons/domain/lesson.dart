enum LessonType {
  regular,
  flex,
  makeup;

  static LessonType fromValue(String value) {
    return switch (value) {
      'flex' => LessonType.flex,
      'makeup' => LessonType.makeup,
      _ => LessonType.regular,
    };
  }

  String get label {
    return switch (this) {
      LessonType.regular => '정규 수업',
      LessonType.flex => '자율 예약 수업',
      LessonType.makeup => '보강 수업',
    };
  }
}

enum LessonStatus {
  scheduled,
  canceled;

  static LessonStatus fromValue(String value) {
    return value == 'canceled'
        ? LessonStatus.canceled
        : LessonStatus.scheduled;
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.teacherId,
    required this.startsAt,
    required this.endsAt,
    required this.durationMinutes,
    required this.type,
    required this.status,
    this.lessonRightId,
    this.occurrenceAt,
    this.rescheduledBy,
    this.teacherName,
  });

  final String id;
  final String teacherId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int durationMinutes;
  final LessonType type;
  final LessonStatus status;
  final String? lessonRightId;
  final DateTime? occurrenceAt;
  final String? rescheduledBy;
  final String? teacherName;

  bool get isCanceled => status == LessonStatus.canceled;

  bool get isRescheduled {
    if (rescheduledBy != null) {
      return true;
    }

    final original = occurrenceAt;
    if (original == null) {
      return false;
    }
    return original.toUtc().difference(startsAt.toUtc()).inMinutes != 0;
  }

  String get displayTypeLabel {
    if (isRescheduled) {
      return '재예약 수업';
    }
    return type.label;
  }

  Lesson copyWithTeacherName(String? name) {
    return Lesson(
      id: id,
      teacherId: teacherId,
      startsAt: startsAt,
      endsAt: endsAt,
      durationMinutes: durationMinutes,
      type: type,
      status: status,
      lessonRightId: lessonRightId,
      occurrenceAt: occurrenceAt,
      rescheduledBy: rescheduledBy,
      teacherName: name ?? teacherName,
    );
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      return DateTime.parse(value.toString()).toLocal();
    }

    return Lesson(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      startsAt: parseDate(json['starts_at']),
      endsAt: parseDate(json['ends_at']),
      durationMinutes: json['duration_minutes'] as int,
      type: LessonType.fromValue(json['lesson_type'] as String),
      status: LessonStatus.fromValue(json['status'] as String),
      lessonRightId: json['lesson_right_id'] as String?,
      occurrenceAt: json['occurrence_at'] == null
          ? null
          : parseDate(json['occurrence_at']),
      rescheduledBy: json['rescheduled_by'] as String?,
    );
  }
}

class LessonBookingWindow {
  const LessonBookingWindow({
    required this.startsOn,
    required this.endsOn,
  });

  final DateTime startsOn;
  final DateTime endsOn;
}

class LessonBookingOption {
  const LessonBookingOption({
    required this.startsAt,
    required this.endsAt,
    required this.teacherId,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final String teacherId;

  factory LessonBookingOption.fromJson(Map<String, dynamic> json) {
    return LessonBookingOption(
      startsAt: DateTime.parse(json['starts_at'].toString()).toLocal(),
      endsAt: DateTime.parse(json['ends_at'].toString()).toLocal(),
      teacherId: json['teacher_id'] as String,
    );
  }
}
