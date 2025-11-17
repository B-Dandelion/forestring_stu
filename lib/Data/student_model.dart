class Student{
  //학생 클래스(이름,수업 시작 시간, 수업 요일)

  final String id;
  final String name;
  final DateTime startTime;
  final String teacherID;

  Student({required this.id, required this.name, required this.teacherID, required this.startTime});

  Student.fromJson({
    required Map<String, dynamic> json,
  }) : id = json['id'],
        name = json['name'],
        teacherID = json['teacher'],
        startTime = json['startTime'].toDate();


  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'name' : name,
      'teacherID' : teacherID,
      'startTime' : startTime,
    };
  }
}