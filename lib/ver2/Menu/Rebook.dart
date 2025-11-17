import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constant_data.dart';

class Rebook extends StatefulWidget {
  const Rebook({super.key});

  @override
  State<Rebook> createState() => _RebookState();
}

class _RebookState extends State<Rebook> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  late Map<String, dynamic> selectedSchedule;
  late List<Map<String, dynamic>> weeklySchedule;
  late int duration; // 학생의 수업 시간 고정

  @override
  void initState() {
    super.initState();
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    weeklySchedule = studentProvider.weeklySchedule;

    // 선택된 스케줄을 첫 번째 수업으로 설정
    selectedSchedule = weeklySchedule.first;
    duration = selectedSchedule['duration'];
  }


  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    List<DateTime> availableTimes = _getAvailableTimes(studentProvider);

    // 현재 학기 필터링
    DateTime semesterStart = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['startDate'];
    DateTime semesterEnd = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['endDate'].add(const Duration(days: 1));

    // 현재 학기 수업 데이터 필터링
    List<Map<String, dynamic>> lessons = studentProvider.lessons.where((lesson) {
      DateTime lessonDate = lesson['date'];
      return lessonDate.isAfter(semesterStart) && lessonDate.isBefore(semesterEnd);
    }).toList()
      ..sort((a, b) => a['date'].compareTo(b['date'])); // 날짜 기준 오름차순 정렬

    // 선택된 스케줄에 대한 남은 수업권 계산 (MyPage 방식 통일)
    int totalLessons = lessons
        .where((lesson) => lesson['code'] == selectedSchedule['code'] && lesson['status'] == 'confirmed')
        .length;

    int totalAllowedLessons = 4; // 개별 수업은 무조건 4개로 고정
    int remainingLessons = totalAllowedLessons - totalLessons;

    return Scaffold(
      appBar: AppBar(
        title: weeklySchedule.length > 1
            ? DropdownButton<Map<String, dynamic>>(
          value: selectedSchedule,
          dropdownColor: const Color(0xff3E6F58),
          onChanged: (newSchedule) {
            setState(() {
              selectedSchedule = newSchedule!;
              duration = selectedSchedule['duration']; // 선택한 수업의 duration 업데이트
              availableTimes = _getAvailableTimes(studentProvider);
            });
          },
          items: weeklySchedule
              .map((schedule) => DropdownMenuItem<Map<String, dynamic>>(
            value: schedule,
            child: Text(_getScheduleLabel(schedule), style: style.copyWith(color: Colors.white)),
          ))
              .toList(),
        )
            : Text(_getScheduleLabel(selectedSchedule), style: style.copyWith(color: Colors.white)),
        centerTitle: true,
        backgroundColor: PRIMARY_COLOR,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0.0, //앱바 밑에 그림자
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  "남은 수업: $remainingLessons",
                  style: style.copyWith(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 5),
                Icon(
                  remainingLessons > 0 ? Icons.check_rounded : Icons.check_circle,
                  color: remainingLessons > 0 ? Colors.white : Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: BaseDrawer(name: studentProvider.name!),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(DateTime.now().year, DateTime.now().month - 1, 1), // 전달 1일
              lastDay: DateTime(DateTime.now().year, DateTime.now().month + 1, 0), // 다음 달 말일
              focusedDay: focusedDate,
              onDaySelected: (DateTime selectedDate, DateTime focusedDate) {
                setState(() {
                  this.selectedDate = selectedDate;
                  this.focusedDate = focusedDate;
                  availableTimes = _getAvailableTimes(studentProvider); // 날짜 변경 시 자동 갱신!
                });
              },
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
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
            const SizedBox(height: 10),
            BookingBanner(title: "${DateFormat('yyyy년 MM월 dd일').format(selectedDate)} 예약 가능 시간"),
            const SizedBox(height: 10),
            remainingLessons > 0
            ? Expanded( // 수업권이 있으면 예약 가능한 시간 표시
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.5,
                  mainAxisExtent: 50,
                ),
                itemCount: availableTimes.length,
                itemBuilder: (context, index) {
                  DateTime time = availableTimes[index];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () async {

                        // Firestore에서 서버 시간 가져오기
                        DocumentReference timeRef = FirebaseFirestore.instance.collection('serverTime').doc('now');
                        await timeRef.set({"timestamp": FieldValue.serverTimestamp()}); // 서버 타임스탬프 생성

                        DocumentSnapshot timeSnapshot = await timeRef.get();
                        Timestamp serverTimestamp = timeSnapshot["timestamp"];
                        DateTime serverTime = serverTimestamp.toDate(); // 서버 기준 현재 시간

                        // 선택한 날짜 + 예약할 시간 정보 합치기
                        DateTime selectedDateTime = DateTime(
                            selectedDate.year, selectedDate.month, selectedDate.day, // 선택한 날짜
                            time.hour, time.minute, 0, 0 // 예약할 시간 정보
                        );

                        // 서버 기준으로 5시간 이전인지 확인
                        if (selectedDateTime.isBefore(serverTime.add(const Duration(hours: 5)))) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "에약 가능한 시간대가 아닙니다.",
                                style: style.copyWith(color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                              backgroundColor: Colors.red.shade200,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return; // 예약 실행하지 않음
                        }
                        // 예약 전 확인 다이얼로그 표시
                        bool confirmBooking = await _showBookingConfirmationDialog(
                          context,
                          selectedDateTime,
                          studentProvider.teacherName!,
                          studentProvider.name!,
                        );

                        if (confirmBooking) {
                          await bookLesson(studentProvider, selectedDateTime, selectedSchedule);
                        }

                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          side:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            )
                : Padding( // 수업권이 없으면 문구 출력
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "예약 가능한 수업권이 없습니다.",
                style: style.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // 선택한 스케줄을 기반으로 예약 가능한 시간 가져오기
  List<DateTime> _getAvailableTimes(StudentProvider studentProvider) {

    // 선생님 근무 시간 가져오기
    String dayKey = _getDayCode(selectedDate.weekday);
    Map<String, dynamic> workSchedule = studentProvider.workSchedule[dayKey] ?? {};
    DateTime workStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        DateFormat('HH:mm').parse(workSchedule['startTime'] ?? '00:00').hour,
        DateFormat('HH:mm').parse(workSchedule['startTime'] ?? '00:00').minute);
    DateTime workEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        DateFormat('HH:mm').parse(workSchedule['endTime'] ?? '00:00').hour,
        DateFormat('HH:mm').parse(workSchedule['endTime'] ?? '00:00').minute);

    // 예약된 슬롯 가져오기
    List<Map<String, DateTime>> bookedTimes = studentProvider.bookedSlots.values
        .where((lessonData) => isSameDay(lessonData['date'] as DateTime, selectedDate))
        .map((lessonData) {
      DateTime start = lessonData['date'] as DateTime;
      int bookedDuration = lessonData['duration'] as int; // 해당 수업의 duration
      DateTime end = start.add(Duration(minutes: bookedDuration));
      return {"start": start, "end": end};
    }).toList();

    // 모든 가능한 시간 슬롯 생성 (근무시간 내에서 `15분 간격`으로 생성)
    List<DateTime> allSlots = [];
    DateTime current = workStart;

    while (current.isBefore(workEnd)) {
      allSlots.add(current);
      current = current.add(Duration(minutes: 15)); // 15분 간격으로 생성
    }

    // 예약된 시간대 제거
    List<DateTime> availableSlots = allSlots.where((slot) {
      return !bookedTimes.any((booked) {
        DateTime bookedStart = booked["start"]!;
        DateTime bookedEnd = booked["end"]!;

        return (slot.isAtSameMomentAs(bookedStart) || // 예약된 시간과 정확히 일치하는 경우
            slot.isAfter(bookedStart) && slot.isBefore(bookedEnd)); // 예약된 범위 내에 포함된 경우
      });
    }).toList();

    // 예약 가능한 시간대를 `duration` 단위로 묶음
    List<DateTime> finalAvailableSlots = [];
    for (int i = 0; i < availableSlots.length; i++) {
      DateTime slot = availableSlots[i];

      // duration 동안 연속된 슬롯이 가능한지 확인
      bool isValid = true;
      for (int j = 1; j < (duration / 15); j++) {
        if (!availableSlots.contains(slot.add(Duration(minutes: j * 15)))) {
          isValid = false;
          break;
        }
      }

      if (isValid) {
        finalAvailableSlots.add(slot);
      }
    }

    return finalAvailableSlots;
  }

  // **수업 예약 실행**
  Future<void> bookLesson(
      StudentProvider studentProvider, DateTime bookingTime, Map<String, dynamic> schedule) async
  {

    // 현재 학기 필터링
    DateTime semesterStart = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['startDate'];
    DateTime semesterEnd = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['endDate'].add(const Duration(days: 1));

    // 현재 학기 수업 데이터 필터링
    List<Map<String, dynamic>> lessons = studentProvider.lessons.where((lesson) {
      DateTime lessonDate = lesson['date'];
      return lessonDate.isAfter(semesterStart) && lessonDate.isBefore(semesterEnd);
    }).toList()
      ..sort((a, b) => a['date'].compareTo(b['date'])); // 날짜 기준 오름차순 정렬

    // 선택된 스케줄에 대한 남은 수업권 계산 (MyPage 방식 통일)
    int totalLessons = lessons
        .where((lesson) => lesson['code'] == selectedSchedule['code'] && lesson['status'] == 'confirmed')
        .length;

    int totalAllowedLessons = 4; // 개별 수업은 무조건 4개로 고정
    int remainingLessons = totalAllowedLessons - totalLessons;

    if (remainingLessons <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "예약 가능한 수업권이 없습니다.",
            style: style.copyWith(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red.shade200,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();

    // 공통 레슨 데이터 (한 번만 정의)
    Map<String, dynamic> lessonData = {
      "code": schedule['code'],
      "date": bookingTime, // 날짜 + 시간 통합 저장,
      "duration": schedule['duration'],
      "studentId": studentProvider.studentId,
      "teacherId": studentProvider.teacherId,
      "RescheduledBy": studentProvider.studentId,
      "isRescheduled": true,
      "status": "confirmed",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    try {
      CollectionReference lessonsRef = firestore.collection('lessons');
      CollectionReference studentLessonsRef = firestore.collection('users').doc(studentProvider.studentId).collection('lessons');
      DocumentReference teacherSlotRef = firestore.collection('availableSlots').doc(studentProvider.teacherId);

      DocumentReference lessonDocRef = lessonsRef.doc();
      String lessonId = lessonDocRef.id;

      // Firestore에 데이터 저장 (Batch 사용)
      batch.set(lessonDocRef, lessonData); // (1) `lessons` 컬렉션에 저장
      batch.set(studentLessonsRef.doc(lessonId), lessonData); // (2) 학생의 lessons 서브컬렉션에 저장
      batch.set(
        teacherSlotRef,
        {
          "bookedSlots": {
            lessonId: {  // lessonId가 "bookedSlots" 맵 안의 키 값으로 들어감
              "date": bookingTime, // 날짜 + 시간 통합 저장,
              "duration": schedule['duration'],
              "isRescheduled": true,
              "status": "confirmed",
              "studentId": studentProvider.studentId,
            }
          }
        },
        SetOptions(merge: true),
      ); // (3) 선생님 `availableSlots.bookedSlots`에 추가

      await batch.commit();
      print(" Firestore 저장 완료: $lessonData"); // 성공 로그 추가

      studentProvider.fetchStudentData(studentProvider.studentId!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "수업 저장이 완료 되었습니다.",
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

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "예약 실패: 네트워크 오류 발생.",
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

  }

  Future<bool> _showBookingConfirmationDialog(
      BuildContext context, DateTime bookingTime, String teacherName, String studentName) async
  {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("예약 확인", style: style.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          "${DateFormat('MM월 dd일 HH:mm').format(bookingTime)}\n"
              "선생님: $teacherName\n"
              "학생: $studentName\n\n"
              "위 정보로 예약하시겠습니까?",
          style: style.copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // 취소
            child: Text("취소", style: style.copyWith(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // 확인
            child: Text("확인", style: style.copyWith(color: PRIMARY_COLOR)),
          ),
        ],
      ),
    ) ?? false;
  }


  // 요일 코드 -> 저장 형태로 변경
  String _getDayCode(int weekday) {
    Map<int, String> dayMap = {
      1: "MO", // 월요일
      2: "TU", // 화요일
      3: "WE", // 수요일
      4: "TH", // 목요일
      5: "FR", // 금요일
      6: "SA", // 토요일
      7: "SU", // 일요일
    };
    return dayMap[weekday] ?? "MO"; // 기본값은 "MO" (예외 방지)
  }

  // 요일 코드 -> 한국어 변환
  String _dayToKorean(String day) {
    Map<String, String> dayMap = {
      'MO': '월요일',
      'TU': '화요일',
      'WE': '수요일',
      'TH': '목요일',
      'FR': '금요일',
      'SA': '토요일',
      'SU': '일요일',
    };
    return dayMap[day] ?? '알 수 없음';
  }
  // weeklySchedule 항목을 "요일 HH:mm 수업" 형식으로 변환
  String _getScheduleLabel(Map<String, dynamic> schedule) {
    return "${_dayToKorean(schedule['day'])} ${schedule['startTime']} 수업";
  }
}