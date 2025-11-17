import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forestring_student_1/main.dart';
import 'package:forestring_student_1/ver2/Login.dart';
import 'package:forestring_student_1/ver2/Menu/Home.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Menu/Rebook.dart';
import 'Menu/Schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

const PRIMARY_COLOR = Color(0xff003717);
const SECONDARY_COLOR = Color(0xff708C7A);
const IBORY = Color(0xffFDF8E7);

TextStyle style = const TextStyle(
    color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);

Future<DateTime> getServerTime() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    DocumentReference serverTimeRef =
    firestore.collection('serverTime').doc('currentTime');

    // 서버 타임스탬프를 설정하는 필드
    await serverTimeRef.set({'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    // 문서를 다시 가져와서 서버 시간을 읽음
    DocumentSnapshot snapshot = await serverTimeRef.get();

    Timestamp serverTimestamp = snapshot['timestamp'] as Timestamp;
    DateTime serverTime = serverTimestamp.toDate(); // Firestore에서 가져오면 자동으로 로컬 시간대 적용됨

    print("서버에서 가져온 시간: $serverTime");
    return serverTime;

  } catch (e) {
    print("서버 시간 가져오기 실패: $e");
    return DateTime.now(); // 실패 시 로컬 시간 반환
  }
}

// 학기별 시작일과 종료일 저장 (key: "YYYY-MM", value: [시작일, 종료일, 휴일리스트])
Map<String, Map<String, dynamic>> SemesterTerm = {};

// 현재 학기, 이전 학기, 다음 학기
DateTime now = DateTime.now();
DateTime nowsemester = now;
DateTime previoussemester = DateTime(now.year, now.month - 1, 1);
DateTime nextsemester = DateTime(now.year, now.month + 1, 1);

// 전년도 부터 내년도 학기 정보 불러오기
Future<void> fetchSemesterInfo() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Firebase 서버에서 정확한 현재 시간 가져오기
    DateTime now = await getServerTime();
    print('현재 서버 시간: ${now}');
    String currentYear = now.year.toString();
    String previousYear = (now.year - 1).toString();
    String nextYear = (now.year + 1).toString();

    List<String> yearRange = [
      "$previousYear-01", "$previousYear-12",
      "$currentYear-01", "$currentYear-12",
      "$nextYear-01", "$nextYear-12"
    ];

    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('semesters')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: yearRange[0]) // 이전 년도 1월부터
        .where(FieldPath.documentId, isLessThanOrEqualTo: yearRange[5]) // 내년 12월까지
        .get();

    // Map<String, List<DateTime>> semesterData = {};
    Map<String, Map<String, dynamic>> semesterData = {}; // 학기 정보 저장


    for (var doc in snapshot.docs) {
      String semesterId = doc.id;  // 예: "2024-01"
      DateTime startDate = (doc['startDate'] as Timestamp).toDate();
      DateTime endDate = (doc['endDate'] as Timestamp).toDate();
      List<Map<String, DateTime>> holidayList = [];
      if (doc.data().containsKey('holidayPeriods') && doc['holidayPeriods'] != null) {
        for (var holiday in List.from(doc['holidayPeriods'])) {
          holidayList.add({
            "startDate": (holiday['startDate'] as Timestamp).toDate(),
            "endDate": (holiday['endDate'] as Timestamp).toDate(),
          });
        }
      }
      semesterData[semesterId] = {"startDate": startDate, "endDate": endDate, "holidays": holidayList};
    }

    // 기존 데이터 초기화 후 업데이트
    SemesterTerm.clear();
    SemesterTerm.addAll(semesterData);
    // 현재 학기 설정
    nowsemester = now;
    for (String semesterId in semesterData.keys) {
      DateTime start = semesterData[semesterId]!['startDate'];  // Map으로 저장했으므로 키를 직접 사용
      DateTime end = semesterData[semesterId]!['endDate'];
      if (start.isBefore(now) && end.isAfter(now)) {
        nowsemester = DateTime(now.year, int.parse(semesterId.split('-')[1]), 1);
        break;
      }
    }
    // 이전 학기, 다음 학기 설정
    previoussemester = DateTime(nowsemester.year, nowsemester.month - 1, 1);
    nextsemester = DateTime(nowsemester.year, nowsemester.month + 1, 1);
    print("학기 정보 불러오기 완료!");

  } catch (e) {
    print("학기 정보 불러오기 중 오류 발생: $e");
  }
}

class LessonCardS extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final int month;
  final int date;
  final String student;
  final String teacher;
  final VoidCallback onEdit; // "취소" 버튼 클릭 시 실행할 콜백 함수

  const LessonCardS({
    required this.startTime,
    required this.endTime,
    required this.month,
    required this.date,
    required this.student,
    required this.teacher,
    required this.onEdit, // onEdit 파라미터 추가
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.5,
            color: PRIMARY_COLOR,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 55, // 날짜 영역 고정 크기
                    child: _Date(month: month, date: date, color: PRIMARY_COLOR),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    width: 40, // 시간 영역 고정 크기
                    child: _Time(startTime: startTime, endTime: endTime),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 내용과 버튼을 양쪽으로 정렬
                      children: [
                        _Content(studentID: student, teacher: teacher),
                        TextButton(
                          onPressed: onEdit, // 수정 버튼 클릭 시 실행할 콜백
                          child: const Text(
                            "취소",
                            style: TextStyle(
                              fontFamily: 'ELAND',
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}

class LessonCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final int month;
  final int date;
  final String student;
  final String teacher;
  final VoidCallback onEdit;
  final Color color; // 추가: 태두리 인자

  const LessonCard({
    required this.startTime,
    required this.endTime,
    required this.month,
    required this.date,
    required this.student,
    required this.teacher,
    required this.onEdit,
    required this.color, // 기본값: 우선 색상 (일반 수업)
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 텍스트 색상 자동 변경 (배경이 연한 초록이면 진한 초록색 적용)

    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.5,
            color: color,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 55,
                    child: _Date(month: month, date: date, color: color) // 텍스트 색상 반영
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    width: 40,
                    child: _Time(startTime: startTime, endTime: endTime),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Content(studentID: student, teacher: teacher),
                        TextButton(
                          onPressed: onEdit,
                          child: const Text(
                            "취소",
                            style: TextStyle(
                              fontFamily: 'ELAND',
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}
class CanceledLessonCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final String student;
  final String teacher;
  final String canceledBy; // 취소자 정보 추가
  final String code;
  final Color color; // 태두리 색상

  const CanceledLessonCard({
    required this.startTime,
    required this.endTime,
    required this.student,
    required this.teacher,
    required this.canceledBy,
    required this.code,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String formattedStartTime = DateFormat('M/d (E) HH:mm').format(startTime);
    String formattedEndTime = DateFormat('HH:mm').format(endTime);
    String lessonType = (code == '-1') ? "보강 수업" : "일반 수업";

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, color: color),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수업 시간
          Text(
            "$formattedStartTime ~ $formattedEndTime",
            style: style.copyWith(
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 4.0),

          // 학생 / 선생님 정보
          Text(
            "$student / $teacher / $lessonType",
            style: style.copyWith(
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 4.0),

          // 취소자 정보
          Text(
            "취소자: $canceledBy",
            style: style.copyWith(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
class MakeupLessonCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final String student;
  final String teacher;
  final VoidCallback onEdit;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const MakeupLessonCard({
    required this.startTime,
    required this.endTime,
    required this.student,
    required this.teacher,
    required this.onEdit,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String formattedStartTime = DateFormat('M/d (E) HH:mm').format(startTime);
    String formattedEndTime = DateFormat('HH:mm').format(endTime);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(width: 1.5, color: borderColor),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "보강 수업",
                  style: style.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white, // 배경색
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 여백 추가
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // 버튼 모서리 둥글게
                  ),
                ),
                child: Text(
                  "취소",
                  style: style.copyWith(
                    fontFamily: 'ELAND',
                    color: Colors.red,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            "$formattedStartTime ~ $formattedEndTime",
            style: style.copyWith(
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            "$student / $teacher",
            style: style.copyWith(
              fontSize: 15,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Date extends StatelessWidget {
  final int month;
  final int date;
  final Color color;

  const _Date({
    required this.month,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w500,
      color: color,
      fontSize: 20.0,
    );

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month.toString(),
            style: textStyle,
          ),
          Text(
            '/',
            style: textStyle,
          ),
          Text(
            date.toString(),
            style: textStyle,
          ),
        ]);
  }
}
class _Time extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;

  const _Time({
    required this.startTime,
    required this.endTime
  });

  @override
  Widget build(BuildContext context) {

    const textStyle = TextStyle(
      fontFamily: 'ELAND',
      fontWeight: FontWeight.w300,
      color: Colors.black,
      fontSize: 13.0,
    );

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        style: textStyle,
      ),
      Text(
          '~ ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
          style: textStyle.copyWith(fontSize: 10.0))
    ]);
  }
}
class _Content extends StatelessWidget {
  final String studentID;
  final String teacher;

  const _Content({
    required this.studentID,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'ELAND',
      fontWeight: FontWeight.w300,
      color: Colors.black,
      fontSize: 16.0,
    );

    return Expanded(
      child: Text(
        '$studentID / $teacher 선생님',
        style: textStyle,
      ),
    );
  }
}

class TodayBanner extends StatelessWidget {
  final DateTime selectedDate;
  // final int count;

  const TodayBanner({
    required this.selectedDate,
    // required this.count,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
        fontFamily: 'ELAND',
        fontWeight: FontWeight.w300,
        color: Colors.white
    );

    return Container(
        color: PRIMARY_COLOR,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                  style: textStyle,
                )
              ],
            )
        )
    );
  }
}
class BookingBanner extends StatelessWidget {

  final String title;

  const BookingBanner({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
        fontFamily: 'ELAND',
        fontWeight: FontWeight.w300,
        color: Colors.white
    );

    return Container(
        color: PRIMARY_COLOR,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  title,
                  style: textStyle,
                )
              ],
            )
        )
    );
  }
}

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BaseAppBar({super.key,
    required this.appBar,
    required this.title,
    this.center = true});

  final AppBar appBar;
  final String title;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: PRIMARY_COLOR,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white,
            fontFamily: 'OpenSans',
            fontWeight: FontWeight.w500,
            fontSize: 20),
      ),
      centerTitle: true,
      elevation: 0.0, //앱바 밑에 그림자
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(appBar.preferredSize.height);
}
class BaseDrawer extends StatelessWidget {
  BaseDrawer({super.key,
  required this.name});

  String name = '';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              '${name} 님',
              style: const TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            accountEmail: const Text(
              '환영합니다',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'ELAND',
                  fontWeight: FontWeight.w300,
                  fontSize: 15
              ),
            ),
            decoration: const BoxDecoration(
                color: PRIMARY_COLOR,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                )),
          ),
          ListTile(
            leading: const Icon(Icons.home_filled),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '메인 페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext context) => const Home()),
                      (route) => false);
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '마이 페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                _createRoute(const MyPage()),
              );
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '예약 페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                _createRoute(const Rebook()),
              );
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '로그아웃',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              const FlutterSecureStorage().delete(key: "id");
              const FlutterSecureStorage().delete(key: "pw");
              final studentProvider = Provider.of<StudentProvider>(context, listen: false);
              studentProvider.resetStudentData();
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext context) => const Login()),
                      (route) => false);
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          )
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 학생용 User Provider
class StudentProvider with ChangeNotifier {
  String? studentId;
  String? name;
  String? password;
  String? role;
  String? teacherId;
  String? teacherName;
  // String? fcmToken;

  List<Map<String, dynamic>> weeklySchedule = [];
  List<Map<String, dynamic>> lessons = [];
  Map<String, Map<String, dynamic>> bookedSlots = {}; // {lessonId: {lessonData}}
  Map<String, dynamic> workSchedule = {}; // 선생님별 근무 일정

  // 실시간 감지 리스너 추적용 변수
  StreamSubscription? _lessonsSubscription;
  StreamSubscription? _studentSubscription;
  StreamSubscription? _teacherSlotsSubscription;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // **Firestore에서 학생 데이터 불러오기**
  Future<void> fetchStudentData(String studentId) async {
    try {
      DocumentSnapshot studentSnapshot =
      await firestore.collection('users').doc(studentId).get();

      if (!studentSnapshot.exists) {
        debugPrint("학생 데이터 없음: $studentId");
        return;
      }

      Map<String, dynamic> studentData = studentSnapshot.data() as Map<String, dynamic>;

      this.studentId = studentId;
      name = studentData['name'];
      password = studentData['password'];
      role = studentData['role'];
      // fcmToken = studentData['fcmToken'];

      weeklySchedule =
      List<Map<String, dynamic>>.from(studentData['weeklySchedule'] ?? []);
      lessons = await fetchStudentLessons(studentId);

      // teacherId 가져온 후 바로 선생님 정보 조회하여 teacherName 설정
      String? newTeacherId = studentData['teacherId'];
      if (newTeacherId != teacherId) {
        teacherId = newTeacherId;
        await fetchTeacherName(); // 같은 컬렉션에서 조회하여 이름 업데이트
        await fetchTeacherSlots(); // 슬롯 데이터 초기 로드 추가
        listenToTeacherSlotsUpdates();
      }

      // 실시간 감지 시작
      listenToStudentDataUpdates();
      listenToStudentLessonsUpdates(studentId);

      notifyListeners(); // UI 갱신

      debugPrint("학생 데이터 및 선생님 정보 업데이트 완료");
    } catch (e) {
      debugPrint("학생 데이터 불러오기 오류: $e");
    }
  }

  Future<void> fetchTeacherName() async {
    if (teacherId == null) return;

    try {
      DocumentSnapshot teacherSnapshot =
      await firestore.collection('users').doc(teacherId).get();

      if (teacherSnapshot.exists) {
        Map<String, dynamic> teacherData =
        teacherSnapshot.data() as Map<String, dynamic>;
        teacherName = teacherData['name'] ?? "알 수 없음";
        notifyListeners();
        debugPrint("선생님 이름 업데이트 완료: $teacherName");
      }
    } catch (e) {
      debugPrint("선생님 이름 가져오기 오류: $e");
    }
  }

  // 학생의 lessons 서브컬렉션을 가져오는 함수
  Future<List<Map<String, dynamic>>> fetchStudentLessons(String studentId) async {
    try {
      QuerySnapshot lessonSnapshot = await firestore
          .collection('users')
          .doc(studentId)
          .collection('lessons')
          .get();

      List<Map<String, dynamic>> lessons = lessonSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'date': (data['date'] as Timestamp).toDate(),
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
        };
      }).toList();

      return lessons;
    } catch (e) {
      print("학생 ($studentId) 수업 데이터 불러오기 실패: $e");
      return [];
    }
  }

  Future<void> fetchTeacherSlots() async {
    if (teacherId == null) return;

    try {
      DocumentSnapshot doc = await firestore.collection('availableSlots').doc(teacherId).get();
      if (!doc.exists) {
        debugPrint("선생님 ID($teacherId)의 데이터 없음.");
        return;
      }

      var data = doc.data() as Map<String, dynamic>;

      // 예약된 슬롯 업데이트
      bookedSlots.clear();
      if (data.containsKey('bookedSlots') && data['bookedSlots'] != null) {
        bookedSlots = (data['bookedSlots'] as Map<String, dynamic>).map(
              (lessonId, lessonData) {
            final entry = lessonData as Map<String, dynamic>;
            return MapEntry(lessonId, {
              "date": (entry["date"] as Timestamp).toDate(),
              "duration": entry["duration"],
              "studentId": entry["studentId"],
              "status": entry["status"],
              "isRescheduled": entry["isRescheduled"],
            });
          },
        );
      }

      // 근무 일정 업데이트
      workSchedule = data.containsKey('workSchedule')
          ? Map<String, dynamic>.from(data['workSchedule'])
          : {};

      notifyListeners();
      debugPrint("선생님 예약 슬롯 & 근무 일정 초기 로드 완료");
    } catch (e) {
      debugPrint("availableSlots 데이터 불러오기 실패: $e");
    }
  }

  // 학생 데이터 자동 업데이트
  Future<void> listenToStudentDataUpdates() async {
    if (studentId == null) return;

    _studentSubscription?.cancel(); // 기존 리스너 해제

    _studentSubscription = firestore
        .collection('users')
        .doc(studentId)
        .snapshots()
        .listen((studentSnapshot) async {
      if (!studentSnapshot.exists) return;

      var studentData = studentSnapshot.data() as Map<String, dynamic>;

      // 토큰 변경 감지 처리
      final updatedToken = studentData['fcmToken'];
      final currentToken = await FirebaseMessaging.instance.getToken();

      if (currentToken != null &&
          updatedToken != null &&
          currentToken != updatedToken) {
        print("다른 기기에서 로그인 감지됨: 토큰 불일치");

        // 자동 로그인 정보 삭제
        await FlutterSecureStorage().deleteAll();

        // context 사용 가능할 때만 UI 처리
        if (navigatorKey.currentContext != null) {
          final context = navigatorKey.currentContext!;

          // 안내 스낵바
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "로그인 토큰이 만료되었습니다. 재 로그인 바랍니다.",
                style: style.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              backgroundColor: IBORY,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: Duration(seconds: 2),
            ),
          );

          // 로그인 페이지로 이동 (모든 스택 제거)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
          );
        }

        return;
      }

      name = studentData['name'];
      password = studentData['password'];
      role = studentData['role'];
      weeklySchedule = List<Map<String, dynamic>>.from(studentData['weeklySchedule'] ?? []);

      // teacherId 변경 감지 후 업데이트
      String? newTeacherId = studentData['teacherId'];
      if (newTeacherId != teacherId) {
        teacherId = newTeacherId;
        fetchTeacherName().then((_) => fetchTeacherSlots().then((_) {
          listenToTeacherSlotsUpdates(); // 새로운 teacherId로 다시 구독
        }));
      }

      notifyListeners();
      print("학생($studentId) 정보 실시간 업데이트 감지됨");
    });
  }

  // 학생 lessons 서브 컬렉션 자동 업데이트
  void listenToStudentLessonsUpdates(String studentId) {
    if (studentId == null) return;

    _lessonsSubscription?.cancel(); // 기존 구독 해제

    _lessonsSubscription = firestore
        .collection('users')
        .doc(studentId)
        .collection('lessons')
        .snapshots()
        .listen((lessonSnapshot) {
      lessons = lessonSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'date': (data['date'] as Timestamp).toDate(),
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
        };
      }).toList();

      notifyListeners();
      print("학생($studentId)의 수업 데이터 실시간 업데이트 감지됨");
    });
  }

  void listenToTeacherSlotsUpdates() {
    if (teacherId == null) return;

    _teacherSlotsSubscription?.cancel(); // 기존 리스너 해제

    _teacherSlotsSubscription = firestore
        .collection('availableSlots')
        .doc(teacherId)
        .snapshots()
        .listen((docSnapshot) async {
      if (!docSnapshot.exists) {
        debugPrint("선생님 ID($teacherId) 데이터 없음.");
        return;
      }

      var data = docSnapshot.data() as Map<String, dynamic>;

      // 예약된 슬롯 업데이트
      bookedSlots.clear();
      if (data.containsKey('bookedSlots') && data['bookedSlots'] != null) {
        bookedSlots = (data['bookedSlots'] as Map<String, dynamic>).map(
              (lessonId, lessonData) {
            final entry = lessonData as Map<String, dynamic>;
            return MapEntry(lessonId, {
              "date": (entry["date"] as Timestamp).toDate(),
              "duration": entry["duration"],
              "studentId": entry["studentId"],
              "status": entry["status"],
              "isRescheduled": entry["isRescheduled"],
            });
          },
        );
      }

      // 근무 일정 업데이트
      workSchedule = data.containsKey('workSchedule')
          ? Map<String, dynamic>.from(data['workSchedule'])
          : {};

      notifyListeners();
      debugPrint("선생님 예약 슬롯 & 근무 일정 업데이트 완료");
    });
  }

  // **특정 수업 취소**
  Future<void> cancelLesson(String lessonId) async {
    if (studentId == null) return;
    final CollectionReference lessonsRef = firestore.collection('lessons');
    final DocumentReference teacherSlotRef = firestore.collection('availableSlots').doc(teacherId);
    final CollectionReference studentLessonsCollection =
    firestore.collection('users').doc(studentId).collection('lessons');

    WriteBatch batch = firestore.batch();
    FieldValue serverTimestamp = FieldValue.serverTimestamp();

    try {

      // 1) "lessons" 컬렉션에서 해당 레슨 문서 상태 변경
      final lessonDocRef = lessonsRef.doc(lessonId);
      batch.update(lessonDocRef, {
        'status': 'canceled',
        'canceledBy': studentId,     // 누가 취소했는지 기록
        'updatedAt': serverTimestamp,
      });

      // 2) 선생님 "availableSlots" 문서에서 해당 bookedSlots 항목 삭제
      //    → 선생님 일정 상에서 이 레슨이 완전히 사라지므로, 그 시간대가 비게 됨
      batch.update(teacherSlotRef, {
        'bookedSlots.$lessonId': FieldValue.delete(),
      });

      // 3) 학생 "users/{studentId}/lessons/{lessonId}" 문서 상태 변경
      //    → 그 학생의 레슨 목록에도 canceled 상태 기록
      final studentLessonDocRef = studentLessonsCollection.doc(lessonId);
      batch.update(studentLessonDocRef, {
        'status': 'canceled',
        'canceledBy': studentId,     // 누가 취소했는지 기록
        'updatedAt': serverTimestamp,
      });

      // 변경 사항 적용
      await batch.commit();

      notifyListeners();
      debugPrint("수업 취소 완료: $lessonId");
    } catch (e) {
      debugPrint("수업 취소 오류: $e");
    }
  }

  // **학생 데이터 초기화 (로그아웃 시)**
  void resetStudentData() {
    // 실시간 감지 리스너 해제
    cancelAllListeners();

    // 모든 데이터 초기화
    studentId = null;
    name = null;
    password = null;
    role = null;
    teacherId = null;
    teacherName = null;
    weeklySchedule = [];
    lessons = [];
    bookedSlots = {};
    workSchedule = {};

    notifyListeners(); // UI 갱신
    debugPrint("학생 데이터가 초기화되었습니다. (로그아웃)");
  }

  void cancelAllListeners() {
    _lessonsSubscription?.cancel();
    _studentSubscription?.cancel();
    _teacherSlotsSubscription?.cancel();

    _lessonsSubscription = null;
    _studentSubscription = null;
    _teacherSlotsSubscription = null;

    notifyListeners(); // UI 갱신 추가
    print("모든 실시간 감지 리스너 종료됨 (로그아웃)");
  }
  // Provider 해제 시 리스너 정리
  @override
  void dispose() {
    cancelAllListeners();
    super.dispose();
  }
}

// 휴일 검사 함수 (1일 추가해서 작동함)
bool isHoliday(DateTime date, List<Map<String, DateTime>> holidays) {
  for (var holiday in holidays) {
    DateTime holidayStart = holiday["startDate"]!;
    DateTime holidayEnd = holiday["endDate"]!.add(const Duration(days: 1));

    if (date.isAfter(holidayStart) && date.isBefore(holidayEnd)) {
      return true;
    }
  }
  return false;
}

Route _createRoute(Page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final offsetAnimation = animation.drive(tween);
      return child;
    },
  );
}

// 로딩창 보여주기
void showLoadingDialog(BuildContext context, String content) {
  showDialog(
    context: context,
    barrierDismissible: false, // 로딩 중 다이얼로그 닫기 방지
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '로딩 중...',
          style: style.copyWith(color: PRIMARY_COLOR, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(PRIMARY_COLOR)),
            const SizedBox(height: 10),
            Text(
              content,
              style: style.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  );
}

// 알람 동의 팝업창
Future<void> showNotificationPermissionDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  bool? alreadyAsked = prefs.getBool("notification_permission_requested");

  if (alreadyAsked == true) return;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(
          "알림을 허용하시겠어요?",
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "수업 일정, 변경 사항 등을 실시간으로 받아보시려면\n"
              "알림을 켜 주세요.\n\n"
              "설정에서 언제든지 변경 가능합니다.",
          style: style, // 폰트 두께 건드리지 않음
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(
              "다음에",
              style: style.copyWith(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PRIMARY_COLOR,
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text("허용", style: style.copyWith(color: Colors.white)),
          ),
        ],
      );
    },
  );

  prefs.setBool("notification_permission_requested", true);

  final studentProvider = Provider.of<StudentProvider>(context, listen: false);
  final studentId = studentProvider.studentId;

  if (studentId != null) {
    await FirebaseFirestore.instance.collection('users')
        .doc(studentId)
        .update({'notificationPermission': result == true});
  }

  if (result == true) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      sound: true,
    );
  }
}
