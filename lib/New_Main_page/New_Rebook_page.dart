import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forestring_student_1/Data/LessonClass.dart';
import 'package:forestring_student_1/Data/constant.dart';
import 'package:intl/intl.dart';
import 'package:ntp/ntp.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreen();
}

class _BookingScreen extends State<BookingScreen> {
  // 요일별 예약 가능 시간 (시작 시간과 끝나는 시간)
  Map<String, List<DateTime>> availableSlots = {
    'Mon': [UserTeacher.workTime[0], UserTeacher.workTime[1]],
    'Tue': [UserTeacher.workTime[2], UserTeacher.workTime[3]],
    'Wed': [UserTeacher.workTime[4], UserTeacher.workTime[5]],
    'Thu': [UserTeacher.workTime[6], UserTeacher.workTime[7]],
    'Fri': [UserTeacher.workTime[8], UserTeacher.workTime[9]],
    'Sat': [UserTeacher.workTime[10], UserTeacher.workTime[11]]
  };

  // 예약된 시간 리스트 (각 DateTime은 예약된 특정 시간)
  // List<DateTime> bookedSlots = [
  // //   DateTime(2024, 11, 11, 11, 30),
  // //   DateTime(2024, 11, 12, 12, 0),
  // //   // 예약된 시간들 추가
  // ];
  List<DateTime> bookedSlots = TeacherLessons.map((lesson) => lesson.time).toList();



  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  late final ValueNotifier<List<Lesson>> selectedEvents;

  DateTime tmp1 = DateTime(DateTime.now().year, DateTime.now().month - 1,1);
  DateTime tmp2 = DateTime(DateTime.now().year, DateTime.now().month + 1,31);

  // 30분 간격으로 시간 슬롯 생성 함수
  List<DateTime> generateTimeSlots(DateTime start, DateTime end) {
    List<DateTime> slots = [];
    DateTime current = start;

    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: 30));
    }

    return slots;
  }

  // 선택한 날짜의 예약 가능한 시간 슬롯 생성
  // Future<List<DateTime>> getAvailableTimes(DateTime selectedDate) async {
  //   // 휴일 기간을 가져옵니다.
  //   List<DateTime> holidayPeriods = await fetchHolidayPeriods();
  //
  //   String dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][selectedDate.weekday % 7];
  //   List<DateTime> slots = [];
  //
  //   // 선택된 날짜가 휴원 기간에 포함되어 있는지 확인
  //   if (holidayPeriods.any((holiday) =>
  //   holiday.year == selectedDate.year &&
  //       holiday.month == selectedDate.month &&
  //       holiday.day == selectedDate.day)) {
  //     // 휴원 기간이라면 빈 리스트 반환
  //     return slots;
  //   }
  //
  //   // 만약 선생님의 근무 시간이 없는 요일이면 빈 리스트를 반환한다.
  //   if (availableSlots.containsKey(dayOfWeek)) {
  //     DateTime start = availableSlots[dayOfWeek]![0];
  //     DateTime end = availableSlots[dayOfWeek]![1];
  //     if (start.hour == end.hour && start.minute == end.minute) {
  //       return slots;
  //     }
  //     // 선택된 날짜와 동일한 날짜의 예약된 시간을 필터링하여 제외
  //     slots = generateTimeSlots(start, end).where((time) {
  //       return !bookedSlots.any((bookedTime) =>
  //       bookedTime.year == selectedDate.year &&
  //           bookedTime.month == selectedDate.month &&
  //           bookedTime.day == selectedDate.day &&
  //           bookedTime.hour == time.hour &&
  //           bookedTime.minute == time.minute);
  //     }).toList();
  //   }
  //
  //   return slots;
  // }

  List<DateTime> getAvailableTimes() {
    String dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][selectedDate.weekday % 7];
    List<DateTime> slots = [];

    if (availableSlots.containsKey(dayOfWeek)) {
      DateTime start = availableSlots[dayOfWeek]![0];
      DateTime end = availableSlots[dayOfWeek]![1];
      if (start.hour == end.hour && start.minute == end.minute) {
        return slots;
      }
      // 선택된 날짜와 동일한 날짜의 예약된 시간을 필터링하여 제외
      slots = generateTimeSlots(start, end).where((time) {
        // 같은 날짜의 예약된 시간을 제외
        return !bookedSlots.any((bookedTime) =>
        bookedTime.year == selectedDate.year &&
            bookedTime.month == selectedDate.month &&
            bookedTime.day == selectedDate.day &&
            bookedTime.hour == time.hour &&
            bookedTime.minute == time.minute);
      }).toList();
    }

    return slots;
  }

  List<Lesson> _getEvents(DateTime day) {
    List<Map<DateTime, dynamic>> EVENTS = [{}];
    Map<DateTime, dynamic>? events;
    String Dayformat = DateFormat('yyyyMMdd').format(day);

    for (int i = 0; i<LessonList.length; i++){
      if (DateFormat('yyyyMMdd').format(DateTime.parse(LessonList[i].time.toString())) == Dayformat) {
        if(LessonList[i].isValid == true){
          //취소되지 않은 수업들만 달력에 표시하기
          if (events != null && events.containsKey(DateTime.utc(day.year, day.month, day.day))) {
            events[DateTime.utc(day.year, day.month, day.day)].add(LessonList[i]);
            EVENTS.add(events);
          } else {
            events = {
              DateTime.utc(day.year, day.month, day.day): [LessonList[i]]
            };
            EVENTS.add(events);
          }
        }
      }
    }
    EVENTS = List.from(EVENTS.reversed);
    return EVENTS[0][day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
      drawer: const NewDrawer(),
      body: SafeArea( child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(tmp1.year, tmp1.month, 1),
            lastDay: tmp2,
            focusedDay: focusedDate,
            onDaySelected: (DateTime selectedDate, DateTime focusedDate) {
              setState(() {
                this.selectedDate = selectedDate;
                this.focusedDate = focusedDate;
              });
            },
            selectedDayPredicate: (day) {
              return isSameDay(selectedDate, day);
            },
            calendarBuilders: CalendarBuilders(dowBuilder: (context, day) {
              final text = DateFormat.E().format(day);
              if (day.weekday == DateTime.sunday) {
                return Center(
                    child: Text(
                      text,
                      style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w500,
                          color: Colors.red),
                    ));
              } else if (day.weekday == DateTime.saturday) {
                return Center(
                    child: Text(text,
                        style: const TextStyle(
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w500,
                            color: Colors.blue)));
              } else {
                return Center(
                    child: Text(text,
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w500,
                        )));
              }
            },
                // 달력 속 날짜 숫자 색상 변경(요일에 맞게)
                defaultBuilder: (context, day, _) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                          color: day.weekday == 7
                              ? Colors.red
                              : day.weekday == 6
                              ? Colors.blue
                              : Colors.black),
                    ),
                  );
                }, markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Column(
                      children: [
                        const SizedBox(height: 45),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xff2E8B57), shape: BoxShape.circle),
                        ),
                      ],
                    );
                  }
                  return null;
                }),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.w500,
                fontSize: 20.0,
              ),
            ),

            calendarStyle: const CalendarStyle(
              isTodayHighlighted: true,
              todayDecoration: BoxDecoration(
                color: Color(0xff124736),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Colors.white,
                fontFamily: 'openSans',
                fontWeight: FontWeight.w500,
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(
                color: Colors.red,
                fontFamily: 'openSans',
                fontWeight: FontWeight.w300,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xff708C7A),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.black,
                fontFamily: 'openSans',
                fontWeight: FontWeight.w500,
              ),
              defaultTextStyle: TextStyle(
                fontFamily: 'openSans',
                fontWeight: FontWeight.w300,
              ),
            ),
            eventLoader: _getEvents,
            onPageChanged: (focusedDate) {
              // No need to call `setState()` here
              focusedDate = focusedDate;
            },
          ),
          SizedBox(height: 16),
          BookingBanner(),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
              ),
              itemCount: getAvailableTimes().length,
              itemBuilder: (context, index) {
                DateTime time = getAvailableTimes()[index];
                return Column(
                  mainAxisSize: MainAxisSize.min, // 버튼이 부모 위젯 크기에 맞게 확장되지 않도록 설정
                  children: [
                    SizedBox(
                      width: 95, // 버튼 너비
                      height: 45, // 버튼 높이
                      child: ElevatedButton(
                        onPressed: () {
                          // 예약 기능 추가
                          bookLesson(DateTime(selectedDate.year, selectedDate.month, selectedDate.day, time.hour, time.minute), context);
                          // print(DateTime(selectedDate.year, selectedDate.month, selectedDate.day, time.hour, time.minute));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // 버튼 배경색 (흰색)
                          foregroundColor: Colors.black, // 텍스트 색상 (검정색)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0), // 모서리를 둥글게
                            side: BorderSide(color: Colors.grey.shade300, width: 1), // 테두리 색상 및 두께 조정
                          ),
                          elevation: 0, // 그림자 제거
                          padding: EdgeInsets.zero, // padding을 제거해 버튼 크기와 맞춤
                        ),
                        child: Text(
                          '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontFamily: 'ELAND', fontSize: 16, fontWeight: FontWeight.w300),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      )
    );
  }
}
// 휴일 기간을 가져오는 함수
Future<List<DateTime>> fetchHolidayPeriods() async {
  // Firestore에서 휴일 정보를 가져옵니다.
  final holidaySnapshot = await FirebaseFirestore.instance
      .collection('Class')
      .doc(DateTime.now().year.toString())
      .get();
  final holidaySnapshot2 = await FirebaseFirestore.instance
      .collection('Class')
      .doc((DateTime.now().year + 1).toString())
      .get();

  List<DateTime> holidays = (holidaySnapshot.data()?['Holiday'] as List)
      .map((timestamp) => (timestamp as Timestamp).toDate())
      .toList();
  List<DateTime> additionalHolidays = (holidaySnapshot2.data()?['Holiday'] as List)
      .map((timestamp) => (timestamp as Timestamp).toDate())
      .toList();

  // 기존 holidays 리스트에 추가
  holidays.addAll(additionalHolidays);

  // 휴일 기간을 구합니다. 각 휴일 날짜부터 7일 동안을 범위로 설정.
  List<DateTime> holidayPeriods = [];
  for (var holiday in holidays) {
    DateTime startOfHoliday = holiday;
    DateTime endOfHoliday = holiday.add(const Duration(days: 6));
    for (var day = startOfHoliday;
    day.isBefore(endOfHoliday) || day.isAtSameMomentAs(endOfHoliday);
    day = day.add(const Duration(days: 1))) {
      holidayPeriods.add(day);
    }
  }

  // 중복을 제거하기 위해 정렬 후 `Set`으로 변환
  return holidayPeriods.toSet().toList()
    ..sort((a, b) => a.compareTo(b));
}

void bookLesson(DateTime bookingTime, BuildContext context) async {
  TextStyle Tstyle = const TextStyle(
      color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);

  // DateTime currentTime = DateTime.now().toUtc().add(const Duration(hours: 9)); // 현재 시간 (KST)
  DateTime currentTime = await NTP.now();
  currentTime = currentTime.toUtc().add(const Duration(hours: 9));
  final DateTime semesterStart = SemesterTerm[nowsemester.month]![0];
  final DateTime semesterEnd = SemesterTerm[nowsemester.month]![1];

  // 1. 현재 학기에서 유효한 수업 개수, 현재 학기 수업 개수를 확인함.
  int validLessonCount = LessonList.where((lesson) => lesson.time.isAfter(semesterStart)
      && lesson.time.isBefore(semesterEnd) && lesson.isValid).length;
  int LessonCount = LessonList.where((lesson) => lesson.time.isAfter(semesterStart)
      && lesson.time.isBefore(semesterEnd)).length;

  // 예약 ID 임시 생성
  String yearMonth = DateFormat('yyMM').format(nowsemester);
  String baseID = '${User.id}_$yearMonth';
  String ID1 = '${baseID}05';
  String ID2 = '${baseID}06';

  // id 값이 ID1과 ID2인 객체가 있는지 확인
  bool hasID1 = LessonList.any((lesson) => lesson.id == ID1);
  bool hasID2 = LessonList.any((lesson) => lesson.id == ID2);

  if (hasID1 && hasID2) {
    // 수업권이 4개가 없는 경우를 대비하여 쓴 코드.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 불가', style: Tstyle.copyWith(color: Colors.red)),
          content: Text(
            '예약 가능 수업권이 없습니다.',
            style: Tstyle,
          ),
        );
      },
    );
    return; // 함수 종료
  }

  // 2. 유효한 수업이 4개 이상인 경우
  if (validLessonCount >= 4) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 불가', style: Tstyle.copyWith(color: Colors.red)),
          content: Text(
            '예약 가능 수업권이 없습니다.',
            style: Tstyle,
          ),
        );
      },
    );
    return;
  }

  // 3. 예약 시간이 현재 시간 기준 6시간 이전인 경우
  if (bookingTime.isBefore(currentTime.add(const Duration(hours: 6)))) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 불가', style: Tstyle.copyWith(color: Colors.red)),
          content: Text(
            '예약 가능 시간이 아닙니다.',
            style: Tstyle,
          ),
        );
      },
    );
    return;
  }

  // 4. 예약 시간이 다음 학기인 경우
  if (bookingTime.isAfter(semesterEnd)) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 불가', style: Tstyle.copyWith(color: Colors.red)),
          content: Text(
            '다음 학기 수업은 해당 학기에 예약 가능합니다.',
            style: Tstyle,
          ),
        );
      },
    );
    return;
  }

  // 5. 예약 시간이 휴원 기간인 경우
  final holidayPeriods = await fetchHolidayPeriods();
  final isHoliday = holidayPeriods.any((holiday) =>
  holiday.year == bookingTime.year &&
      holiday.month == bookingTime.month &&
      holiday.day == bookingTime.day);

  if (isHoliday) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 불가', style: Tstyle.copyWith(color: Colors.red)),
          content: Text(
            '선택하신 날짜는 휴원 기간입니다.',
            style: Tstyle,
          ),
        );
      },
    );
    return;
  }

  // 만약 예약 조건에 위배되지 않는 경우 안내 창을 띄움
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '예약하기',
          style: Tstyle.copyWith(
            color: PRIMARY_COLOR,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '선택된 예약 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(bookingTime)}',
              style: Tstyle.copyWith(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              '이 시간에 수업을 예약하시겠습니까?',
              style: Tstyle.copyWith(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 예약 로직 실행
              // 페이지에서 머무르던 중 누군가 그 시간대에 예약을 한 경우를 대비하여
              // 다시 확인하는 코드.
              try{
                DocumentSnapshot teacherDoc = await FirebaseFirestore.instance.collection('User').doc(UserTeacher.id).get();
                // 선생님이 classList 가져오기
                List<dynamic> bookedLessons = teacherDoc.get('classList') ?? [];
                // 2. 예약된 수업 리스트로 Class 컬렉션의 문서 데이터 확인
                QuerySnapshot classSnapshot = await FirebaseFirestore.instance.collection('Class').get();

                // 예약 불가 시간 확인
                bool isAvailable = true; // 초기값: 예약 가능
                for (var doc in classSnapshot.docs) {
                  // bookedLessons에 해당 문서 ID가 존재하는 경우에만 진행
                  if (bookedLessons.contains(doc.id)) {
                    // 해당 수업의 시간 가져오기
                    DateTime lessonTime = (doc['time'] as Timestamp).toDate();

                    // 예약 시간과 비교
                    if (lessonTime.year == bookingTime.year &&
                        lessonTime.month == bookingTime.month &&
                        lessonTime.day == bookingTime.day &&
                        lessonTime.hour == bookingTime.hour &&
                        lessonTime.minute == bookingTime.minute) {
                      isAvailable = false; // 예약 불가능
                      break;
                    }
                  }

                }
                if(isAvailable == false){

                  //예약에 실패했을 경우
                  await MyModel();
                  await TeacherModel();
                  await GetLesson();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('예약 실패', style: Tstyle.copyWith(color: PRIMARY_COLOR)),
                        content: Text('잠시 후 다시 시도해주시기 바랍니다.', style: Tstyle),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // 팝업 두 개를 모두 닫기 위해 Navigator.pop()을 두 번 호출
                              Navigator.of(context).pop(); // 현재 팝업 닫기
                              Navigator.of(context).pop(); // 이전 팝업 닫기
                              Navigator.of(context).push(
                                _createRoute(const BookingScreen()),
                              ); // 예약이 모두 완료되었고, 업데이트도 끝났으므로 창을 업데이트
                            },
                            child: Text('확인', style: Tstyle.copyWith(color: PRIMARY_COLOR)),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }
              } catch (e){
                // 오류 안내
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        '오류',
                        style: TextStyle(color: Colors.red),
                      ),
                      content: Text('예약 중 오류가 발생했습니다: $e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('확인'),
                        ),
                      ],
                    );
                  },
                );
                return; // 예약 실패
              }

              // ID 생성 규칙에 따라 ID 생성
              String yearMonth = DateFormat('yyMM').format(nowsemester);
              String baseID = '${User.id}_$yearMonth';

              // 05와 06 중 결정
              String lessonSuffix = LessonList.any((lesson) => lesson.id.startsWith('${baseID}05')) ? '06' : '05';
              String lessonID = '${baseID}$lessonSuffix';
              // 4. 조건을 모두 만족하는 경우, 새 수업 추가
              Lesson newLesson = Lesson(
                id: lessonID, // 고유 ID 생성
                time: bookingTime,
                isValid: true,
              );

              // Firebase에 새 수업 추가
              await FirebaseFirestore.instance.collection('Class').doc(newLesson.id).set({
                'time': bookingTime,
                'valid': true,
              });
              await FirebaseFirestore.instance.collection('User').doc(User.id).update({
                'classList': FieldValue.arrayUnion([newLesson.id]),
              });
              await FirebaseFirestore.instance.collection('User').doc(UserTeacher.id).update({
                'classList': FieldValue.arrayUnion([newLesson.id]),
              });

              await MyModel();
              await TeacherModel();
              await GetLesson();
              // 예약 완료 팝업 띄우기
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('예약 완료', style: Tstyle.copyWith(color: PRIMARY_COLOR)),
                    content: Text('수업이 성공적으로 예약되었습니다.', style: Tstyle),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // 팝업 두 개를 모두 닫기 위해 Navigator.pop()을 두 번 호출
                          Navigator.of(context).pop(); // 현재 팝업 닫기
                          Navigator.of(context).pop(); // 이전 팝업 닫기
                          Navigator.of(context).push(
                            _createRoute(const BookingScreen()),
                          ); // 예약이 모두 완료되었고, 업데이트도 끝났으므로 창을 업데이트
                        },
                        child: Text('확인', style: Tstyle.copyWith(color: PRIMARY_COLOR)),
                      ),
                    ],
                  );
                },
              );

            },
            child: Text('예', style: Tstyle.copyWith(color: Colors.red),),
          ),
          TextButton(
            onPressed: () {
              // 취소
              Navigator.of(context).pop();
              return;
            },
            child: Text('아니오', style: Tstyle.copyWith(color: PRIMARY_COLOR),),
          ),
        ],
      );
    },
  );
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
