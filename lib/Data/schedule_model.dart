class ScheduleModel {
  final String id;
  DateTime date;
  final String teacher;
  final bool rebook;

  ScheduleModel({
    required this.id,
    required this.date,
    required this.teacher,
    required this.rebook,
  });

  ScheduleModel copyWith({
    String? id,
    DateTime? date,
    String? teacher,
    bool? rebook,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      date: date ?? this.date,
      teacher: teacher ?? this.teacher,
      rebook: rebook ?? this.rebook,
    );
  }
}

