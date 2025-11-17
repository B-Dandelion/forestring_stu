import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../constant_data.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  DateTime now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        final studentName = studentProvider.name ?? "학생";
        final lessons = studentProvider.lessons;
        final bookedSlots = studentProvider.bookedSlots;

        return Scaffold(
          appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
          drawer: BaseDrawer(name : studentProvider.name!),
          body: SafeArea(
            child: Column(
              children: [
                // 캘린더 UI
                TableCalendar(
                  firstDay: DateTime(DateTime.now().year, DateTime.now().month - 1, 1), // 전달 1일
                  lastDay: DateTime(DateTime.now().year, DateTime.now().month + 1, 0), // 다음 달 말일
                  focusedDay: focusedDate,
                  onDaySelected: (DateTime selectedDate, DateTime focusedDate) {
                    setState(() {
                      this.selectedDate = selectedDate;
                      this.focusedDate = focusedDate;
                    });
                  },
                  selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                  eventLoader: (day) {
                    return _getEvents(day, lessons, bookedSlots);
                  },
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.E().format(day);
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: day.weekday == DateTime.sunday
                                ? Colors.red
                                : day.weekday == DateTime.saturday
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Column(
                          children: [
                            const SizedBox(height: 45),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: Color(0xff2E8B57),
                                  shape: BoxShape.circle),
                            ),
                          ],
                        );
                      }
                      return null;
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0),
                  ),
                  calendarStyle: const CalendarStyle(
                    isTodayHighlighted: true,
                    todayDecoration: BoxDecoration(
                      color: Color(0xff124736),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    selectedDecoration: BoxDecoration(
                      color: Color(0xff708C7A),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                  onPageChanged: (focusedDate) {
                    focusedDate = focusedDate;
                  },
                ),
                const SizedBox(height: 8),
                TodayBanner(
                    selectedDate: selectedDate),
                const SizedBox(height: 8),

                // 일정 리스트
                Expanded(
                  child: ListView.builder(
                    itemCount: _getEvents(selectedDate, lessons, bookedSlots).length,
                    itemBuilder: (context, index) {
                      final lesson = _getEvents(selectedDate, lessons, bookedSlots)[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: LessonCardS(
                          startTime: lesson['date'],
                          endTime: lesson['date'].add(Duration(minutes: lesson['duration'])),
                          month: lesson['date'].month,
                          date: lesson['date'].day,
                          student: studentName,
                          teacher: studentProvider.teacherName ?? "알 수 없음",
                          onEdit: () {
                            showCancelLessonDialog(context, lesson);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // 수정 -> 삭제로 기능 축소!

  void showCancelLessonDialog(BuildContext context, Map<String, dynamic> lesson) {
    DateTime selectedDate = lesson['date'];
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(lesson['date']);
    String teacherId = lesson['teacherId'];
    String studentId = lesson['studentId'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Container(
            child: Text(
              '예약 정보',
              style: style.copyWith(color: PRIMARY_COLOR),
            ),
          ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 날짜 선택
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("날짜: ${DateFormat('yy.MM.dd').format(selectedDate)}", style: style.copyWith(fontSize: 18)),
                  ],
                ),

                const SizedBox(height: 10),

                // 시간 선택
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("시간: ${selectedTime.format(context)}", style: style.copyWith(fontSize: 18)),
                  ],
                ),
              ],
            ),
            actions: [
              // 취소 버튼
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("취소", style: style.copyWith(color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? errorMessage = await canCancelLesson(lesson, teacherId, studentId);
                  if (errorMessage != null) {
                    // 취소 불가능한 경우 → 안내창 띄우기
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('취소 불가', style: style.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                          content: Text(errorMessage, style: style.copyWith(fontSize: 16)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('확인', style: style.copyWith(color: Colors.black)),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                  // 조건 통과 → 취소 가능
                  bool confirm = await _showCancelConfirmationDialog(context);
                  if (confirm) {
                    await cancelLesson(lesson['id'], teacherId, studentId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "수업이 취소 되었습니다!",
                          style: style.copyWith(color: Colors.black),
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
                  }
                },
                child: Text("수업 취소", style: style.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ],
          );
      },
    );
  }

  // 수업 삭제 다이얼로그
  Future<bool> _showCancelConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("수업 취소", style: style.copyWith(fontSize: 20)),
        content: Text("정말로 이 수업을 취소하시겠습니까?", style: style.copyWith(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("아니요", style: style),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("예", style: style),
          ),
        ],
      ),
    ) ?? false;
  }
  // ** 특정 날짜의 수업을 가져오는 함수**
  List<Map<String, dynamic>> _getEvents(
      DateTime day, List<Map<String, dynamic>> lessons, Map<String, Map<String, dynamic>> bookedSlots)
  {
    String formattedDay = DateFormat('yyyyMMdd').format(day);
    return lessons
        .where((lesson) =>
    DateFormat('yyyyMMdd').format(lesson['date']) == formattedDay &&
        lesson['status'] != 'canceled')
        .toList();
  }
  // 취소 조건을 확인하는 함수
  Future<String?> canCancelLesson(Map<String, dynamic> lesson, String teacherId, String studentId) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    try {
      // 1. Firebase 서버 시간 가져오기
      DateTime serverTime = await getServerTime();

      // 2. 현재 학기 시작/종료 날짜 가져오기
      DateTime semesterStart = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['startDate'];
      DateTime semesterEnd = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['endDate'];

      // 3. 해당 수업 정보 가져오기
      DateTime lessonStartTime = lesson['date'];

      // 1번 조건: 미래 학기 수업은 취소 불가
      if (lessonStartTime.isAfter(semesterEnd)) {
        return "미래 학기 수업은 취소할 수 없습니다.";
      }

      // 2번 조건: 수업 시작 5시간 이내면 취소 불가
      if (lessonStartTime.isBefore(serverTime.add(const Duration(hours: 5)))) {
        return "수업 시작 5시간 전까지만 취소할 수 있습니다.";
      }

      // 3번 조건: 한 학기 취소 횟수 2번 초과 시 취소 불가
      int maxCancellable = studentProvider.weeklySchedule.length * 2;
      int canceledLessonCount = studentProvider.lessons.where((lesson) =>
      lesson['status'] == 'canceled' &&
          lesson['canceledBy'] == studentProvider.studentId &&
          lesson['date'].isAfter(semesterStart) &&
          lesson['date'].isBefore(semesterEnd)
      ).length;

      if (canceledLessonCount >= maxCancellable) {
        return "취소 가능 횟수를 초과하였습니다.";
      }

      return null;
    } catch (e) {
      print("canCancelLesson 오류: $e");
      return '취소 처리 중 오류가 발생했습니다.';
    }
  }

  // 수업 삭제 함수
  Future<void> cancelLesson(String lessonId, String teacherId, String studentId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference lessonsRef = firestore.collection('lessons');
    final DocumentReference teacherSlotRef = firestore.collection('availableSlots').doc(teacherId);
    final CollectionReference studentLessonsCollection =
    firestore.collection('users').doc(studentId).collection('lessons');

    WriteBatch batch = firestore.batch();
    FieldValue serverTimestamp = FieldValue.serverTimestamp();

    try {

      // 1 lesson 컬렉션에서 해당 레슨 문서 상태 변경 (canceled)
      final lessonDocRef = lessonsRef.doc(lessonId);
      batch.update(lessonDocRef, {
        'status': 'canceled',
        'canceledBy': studentId,     // 누가 취소했는지 기록
        'updatedAt': serverTimestamp,
      });

      // 2 선생님 availableSlots - bookedSlots 맵 필드에서 해당 수업 삭제
      batch.update(teacherSlotRef, {
        'bookedSlots.$lessonId': FieldValue.delete(), // bookedSlots 맵에서 해당 레슨 ID 삭제
      });

      // 3 학생 레슨 컬렉션에서 해당 수업 상태 변경 (canceled)
      final studentLessonDocRef = studentLessonsCollection.doc(lessonId);
      batch.update(studentLessonDocRef, {
        'status': 'canceled',
        'canceledBy': studentId,     // 누가 취소했는지 기록
        'updatedAt': serverTimestamp,
      });

      // 변경 사항 적용
      await batch.commit();
      print("수업 취소 완료: lessonId: $lessonId");
    } catch (e) {
      print("수업 취소 실패: $e");
      throw Exception("수업 취소 중 오류 발생");
    }
  }

}
