import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forestring_student_1/Data/constant.dart';
import 'package:flutter/material.dart';
import 'package:forestring_student_1/New_Main_page/New_My_page.dart';
import 'package:intl/intl.dart';
import 'package:ntp/ntp.dart';

class LessonCard extends StatelessWidget {
  final DateTime startTime;
  final String lessonID;
  final int month;
  final int date;
  final String student;
  final String teacher;

  const LessonCard({
    required this.startTime,
    required this.lessonID,
    required this.month,
    required this.date,
    required this.student,
    required this.teacher,
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
            padding: const EdgeInsets.all(13.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Date(month: month, date: date),
                  const SizedBox(width: 16.0),
                  _Time(startTime: startTime),
                  const SizedBox(width: 15.0),
                  // Expanded(child: _Content(studentID: student, teacher: teacher)),
                  _Content(studentID: student, teacher: teacher),
                  TextButton(
                    onPressed: () {
                      // 취소 버튼 클릭 시 실행할 코드
                      cancelLesson(startTime, lessonID, context);
                    },
                    child: const Text(
                      '취소하기',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'ELAND',
                        fontWeight: FontWeight.w300,
                        fontSize: 10.0,
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}

class _Date extends StatelessWidget {
  final int month;
  final int date;

  const _Date({
    required this.month,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w500,
      color: PRIMARY_COLOR,
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
          const Text(
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

  const _Time({
    required this.startTime,
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
          '~ ${startTime.add(Duration(minutes: 30)).hour.toString().padLeft(2, '0')}:${startTime.add(Duration(minutes: 30)).minute.toString().padLeft(2, '0')}',
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
      fontSize: 15.0,
    );

    return Expanded(
      child: Text(
        '$studentID / $teacher 선생님',
        style: textStyle,
      ),
    );
  }
}

void cancelLesson(DateTime lessonDate, String lessonID, BuildContext context) async {
  TextStyle Tstyle = const TextStyle(
      color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);
  DateTime currentTime = await NTP.now();
  DateTime userTime = DateTime.now();
  currentTime = currentTime.toUtc().add(const Duration(hours: 9));

  final DateTime semesterStart = SemesterTerm[nowsemester.month]![0];
  final DateTime semesterEnd = SemesterTerm[nowsemester.month]![1];

  String? errorMessage;
  print('현재 한국 시간 (currentTime): $currentTime');
  print('유저 시간 (userTime): $userTime');
  print('수업 날짜 (lessonDate): ${lessonDate.toLocal()}');
  // 0. 휴대폰 설정 시간이 한국 표준시간(KST)과 다를 경우
  if (userTime.hour != currentTime.hour) {
    errorMessage = '현재 휴대폰 시간 설정이 한국 표준시간과 다릅니다.\n시간 설정을 확인 후 다시 시도해주세요.';
  }
  // 1. 취소하려는 수업 날짜가 현재 시간에서 6시간 후보다 과거인 경우
  else if (lessonDate.toLocal().isBefore(userTime.add(const Duration(hours: 6)))) {
    errorMessage = '수업 취소 가능 시간이 아닙니다.';
  }
  // 2. 현재 학기에서 최대 취소 횟수 초과 확인
  else {
    int currentSemesterLessons = 0;
    int invalidLessonsCount = 0;

    for (var lesson in LessonList) {
      if (lesson.time.isAfter(semesterStart) && lesson.time.isBefore(semesterEnd)) {
        currentSemesterLessons++;
        if (!lesson.isValid) {
          invalidLessonsCount++;
        }
      }
    }

    if (invalidLessonsCount >= 2) {
      errorMessage = '최대 취소 횟수를 초과했습니다.';
    }
    // 3. 다음 학기 수업인 경우
    else if (lessonDate.isAfter(semesterEnd)) {
      errorMessage = '다음 학기 수업은 다음 학기 기간에 취소 가능합니다.';
    }
  }

  // 오류 메시지가 있으면 안내문 띄우고 종료
  if (errorMessage != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '취소 불가',
            style: Tstyle.copyWith(color: Colors.red)
          ),
          content: Text(errorMessage!, style: Tstyle,),
        );
      },
    );
    return;
  }

  // 만약 취소 조건에 위배되지 않는 경우 안내 창을 띄움
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '취소하기',
          style: Tstyle.copyWith(
            color: PRIMARY_COLOR,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '선택된 수업 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(lessonDate)}',
              style: Tstyle.copyWith(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              '이 수업을 취소하시겠습니까?',
              style: Tstyle.copyWith(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 실제 취소 로직 실행
              // Navigator.of(context).pop();

              // 취소 로직 실행
              try {
                LessonList.firstWhere((lesson) => lesson.id == lessonID).isValid = false;

                // Firebase에 반영
                await FirebaseFirestore.instance
                    .collection('Class')
                    .doc(lessonID)
                    .update({'valid': false});

                //취소한 시간을 기록합니다
                await FirebaseFirestore.instance
                    .collection('Class')
                    .doc(lessonID)
                    .update({'cancelledAt': DateTime.now()});

                // TeacherLesson 함수 호출 (새로고침)
                await GetLesson();

                // 취소 완료 다이얼로그 띄우기 전에 mounted 체크

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('취소 완료', style: Tstyle.copyWith(color: PRIMARY_COLOR)),
                      content: Text('수업이 성공적으로 취소되었습니다.', style: Tstyle.copyWith(color: Colors.black)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // 팝업 두 개를 모두 닫기 위해 Navigator.pop()을 두 번 호출
                            Navigator.of(context).pop(); // 현재 팝업 닫기
                            Navigator.of(context).pop(); // 이전 팝업 닫기
                            Navigator.of(context).push(
                              _createRoute(const New_My_page()),
                            ); // 취소가 모두 완료되었고, 업데이트도 끝났으므로 창을 업데이트
                          },
                          child: Text('확인', style: Tstyle.copyWith(color: PRIMARY_COLOR)),
                        ),
                      ],
                    );
                  },
                );
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        '오류',
                        style: Tstyle.copyWith(color: Colors.red),
                      ),
                      content: Text('취소 중 오류가 발생했습니다: $e', style: Tstyle,),
                    );
                  },
                );
              }
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


