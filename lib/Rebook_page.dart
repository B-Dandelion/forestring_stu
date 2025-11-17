import 'package:flutter/material.dart';
import 'package:forestring_student_1/Data/constant.dart';
import 'package:forestring_student_1/Data/schedule_model.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:ntp/ntp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Rebook_page extends StatefulWidget {
  const Rebook_page({super.key});

  @override
  State<Rebook_page> createState() => _Rebook_page();
}

class _Rebook_page extends State<Rebook_page> {
  DateTime selectedDate = DateTime.utc(
    //선택된 날짜를 관리할 변수
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime focusedDate = DateTime.now();
  DateTime tmp1 = DateTime(
      DateTime.now().year,
      DateTime.now().month, 1).subtract(const Duration(days: 10));
  DateTime tmp2 = DateTime(
      DateTime.now().year,
      DateTime.now().month, 20).add(const Duration(days: 55));

  String? _subjectText = '',
      _startTimeText = '',
      _endTimeText = '',
      _dateText = '',
      _timeDetails = '';

  DateTime _date = DateTime.now();

  TextStyle style = const TextStyle(
      color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
        drawer: const BaseDrawer(),
        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
              child: Column(
                children: [
                  Expanded(
                      child: SfCalendar(
                        minDate: DateTime(tmp1.year, tmp1.month, 1),
                        maxDate: DateTime(tmp2.year, tmp2.month, 1),
                        // timeZone: 'Korea Standard Time',
                        showCurrentTimeIndicator: false,
                        specialRegions: _getTimeRegions(),
                        onTap: calendarTapped,
                        view: CalendarView.week,
                        cellBorderColor: Colors.black12,
                        todayHighlightColor: PRIMARY_COLOR,
                        showNavigationArrow: true,
                        cellEndPadding: 0,
                        dataSource: MeetingDataSource(_getDataSource()),
                        scheduleViewSettings: const ScheduleViewSettings(
                          appointmentTextStyle: TextStyle(
                            fontFamily: 'ELAND',
                            fontWeight: FontWeight.w300,
                            fontSize: 1,
                            color: Color(0xff2E8B57),
                          ),),
                        viewHeaderStyle: const ViewHeaderStyle(
                          dateTextStyle: TextStyle(
                            color: Colors.black,
                            fontFamily: 'ELAND',
                            fontWeight: FontWeight.w500,
                          ),
                          dayTextStyle: TextStyle(
                            color: Colors.black,
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        headerStyle: const CalendarHeaderStyle(
                            backgroundColor: Colors.transparent,
                            textAlign: TextAlign.center,
                            textStyle: TextStyle(
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w500,
                              fontSize: 20.0,
                            )),
                        timeSlotViewSettings: const TimeSlotViewSettings(
                          dayFormat: 'EEE',
                          timeTextStyle: TextStyle(
                              fontFamily: 'openSans',
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                          timeInterval: Duration(minutes: 30),
                          timeFormat: 'h:mm',
                          startHour: 7,
                          endHour: 23,
                        ),
                      ))
                ],
              ),
            )));
  }

  List<Meeting> _getDataSource() {
    final List<Meeting> meetings = <Meeting>[];
    for (int i = 0; i < Schedules.length; i++) {
      final DateTime tmp = Schedules[i].date;
      final DateTime startTime =
      DateTime(tmp.year, tmp.month, tmp.day, tmp.hour, tmp.minute, 0);
      final DateTime endTime = startTime.add(const Duration(minutes: 30));
      meetings.add(Meeting(
          '정규수업', startTime, endTime, PRIMARY_COLOR.withOpacity(0.9), false));
    }

    for (int i = 0; i < Rebooked.length; i++) {
      final DateTime tmp = Rebooked[i].date;
      final DateTime startTime =
      DateTime(tmp.year, tmp.month, tmp.day, tmp.hour, tmp.minute, 0);
      final DateTime endTime = startTime.add(const Duration(minutes: 30));
      meetings.add(Meeting(
          '예약수업', startTime, endTime, PRIMARY_COLOR.withOpacity(0.9), false));
    }

    for (int i = 0; i < BanTime.length; i++) {
      meetings.add(Meeting('예약불가', BanTime[bantime[i]][0],
          BanTime[bantime[i]][1], Colors.black45.withOpacity(0.4), false));
    }
    for (int i = 0; i < BookedSchedules.length; i++) {
      meetings.add(Meeting(
          '예약불가',
          BookedSchedules[i],
          BookedSchedules[i].add(const Duration(minutes: 30)),
          PRIMARY_COLOR.withOpacity(0.4),
          false));
    }
    return meetings;
  }

  List<TimeRegion> _getTimeRegions() {
    final List<TimeRegion> regions = <TimeRegion>[];
    regions.add(TimeRegion(
        startTime: DateTime(
            2024, 1, 1, WorkTime['Mon'][0].hour, WorkTime['Mon'][0].minute),
        endTime: DateTime(
            2024, 1, 1, WorkTime['Mon'][1].hour, WorkTime['Mon'][1].minute),
        color: PRIMARY_COLOR.withOpacity(0.2),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=7'));
    regions.add(TimeRegion(
        startTime: DateTime(
            2024, 1, 2, WorkTime['Tue'][0].hour, WorkTime['Tue'][0].minute),
        endTime: DateTime(
            2024, 1, 2, WorkTime['Tue'][1].hour, WorkTime['Tue'][1].minute),
        recurrenceExceptionDates: const [],
        color: PRIMARY_COLOR.withOpacity(0.2),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=7'));
    regions.add(TimeRegion(
        startTime: DateTime(
            2024, 1, 3, WorkTime['Wed'][0].hour, WorkTime['Wed'][0].minute),
        endTime: DateTime(
            2024, 1, 3, WorkTime['Wed'][1].hour, WorkTime['Wed'][1].minute),
        recurrenceExceptionDates: const [],
        color: PRIMARY_COLOR.withOpacity(0.2),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=7'));
    regions.add(TimeRegion(
        startTime: DateTime(
            2024, 1, 4, WorkTime['Thu'][0].hour, WorkTime['Thu'][0].minute),
        endTime: DateTime(
            2024, 1, 4, WorkTime['Thu'][1].hour, WorkTime['Thu'][1].minute),
        recurrenceExceptionDates: const [],
        color: PRIMARY_COLOR.withOpacity(0.2),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=7'));
    regions.add(TimeRegion(
        startTime: DateTime(
            2024, 1, 5, WorkTime['Fri'][0].hour, WorkTime['Fri'][0].minute),
        endTime: DateTime(
            2024, 1, 5, WorkTime['Fri'][1].hour, WorkTime['Fri'][1].minute),
        recurrenceExceptionDates: const [],
        color: PRIMARY_COLOR.withOpacity(0.2),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=7'));
    regions.add(TimeRegion(
        startTime: DateTime(
            2024, 1, 6, WorkTime['Sat'][0].hour, WorkTime['Sat'][0].minute),
        endTime: DateTime(
            2024, 1, 6, WorkTime['Sat'][1].hour, WorkTime['Sat'][1].minute),
        recurrenceExceptionDates: const [],
        color: PRIMARY_COLOR.withOpacity(0.2),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=7'));
    return regions;
  }

  void onSavePressed(ScheduleModel newone) async {
    var TMP = [];
    Rebooked.add(newone);
    for (int i = 0; i < Rebooked.length; i++) {
      TMP.add(Rebooked[i].date);
    }
    await FirebaseFirestore.instance
        .collection('Class')
        .doc(UserID)
        .update({'rebooked': TMP});
    _getDataSource();
  }

  void calendarTapped(CalendarTapDetails details) async {
    DateTime currentTime = await NTP.now();
    DateTime userTime = await NTP.now();
    currentTime = currentTime.toUtc().add(const Duration(hours: 9));

    final semesterStart = semesterduration[thissemester[1]][0];
    final semesterEnd = semesterduration[thissemester[1]][1];

    List<ScheduleModel> filteredSchedules = Schedules.where((schedule) {
      return schedule.date.isAfter(semesterStart) && schedule.date.isBefore(semesterEnd);
    }).toList();

    if (Rebooked.length >= 2) {
      // 재 예약한 수업이 2개 이상인 경우 (이번 학기 기준)
      // 보강을 잡더라도 선생님과 협의가 필요하므로 일단 현재 학기 수업만 고려하기.
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                  child: Text('학기 예약 횟수를 전부 사용했습니다.\n 관리자에게 문의해주세요.',
                      style: style.copyWith(color: PRIMARY_COLOR, fontSize: 15))),
            );
          });
    }
    else if (userTime.hour != currentTime.hour) {
      print(currentTime);
      print(userTime);
      print(details.date);
      print('딱걸렷죠');
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                  child: Text('휴대폰 설정 시간이 한국 시간과 다릅니다.\n설정 변경 후 앱을 다시 실행시켜주세요.',
                      style:
                      style.copyWith(color: PRIMARY_COLOR, fontSize: 15))),
            );
          });
    }
    else if (details.targetElement == CalendarElement.appointment ||
        details.targetElement == CalendarElement.agenda) {
      final Meeting appointmentDetails = details.appointments![0];
      _subjectText = appointmentDetails.eventName;
      _dateText =
          DateFormat('yyyy년 M월 dd일').format(appointmentDetails.from).toString();
      _startTimeText =
          DateFormat('hh:mm').format(appointmentDetails.from).toString();
      _endTimeText =
          DateFormat('hh:mm').format(appointmentDetails.to).toString();
      _date = appointmentDetails.from;
      if (appointmentDetails.isAllDay) {
        _timeDetails = 'All day';
      } else {
        _timeDetails = '$_startTimeText - $_endTimeText';
      }
      if (_subjectText == '정규수업') {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('$_subjectText',
                        style:
                        style.copyWith(color: PRIMARY_COLOR, fontSize: 20))),
                content: SizedBox(
                  height: 80,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text('$_dateText', style: style.copyWith(
                              fontSize: 20)),
                        ],
                      ),
                      const Row(
                        children: <Widget>[
                          Text(''),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(_timeDetails!,
                              style: style.copyWith(fontSize: 15)),
                        ],
                      )
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            print(_date);
                            await onDeletePressed(context, _date);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                          },
                          child:
                          Text('수업 취소하기',
                              style: style.copyWith(color: Colors.red))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child:
                          Text('닫기',
                              style: style.copyWith(color: PRIMARY_COLOR)))
                    ],
                  ),

                ],
              );
            });
      } else {
        //다른 학생 예약 정보 띄우기
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('$_subjectText',
                        style:
                        style.copyWith(color: PRIMARY_COLOR, fontSize: 20))),
                content: SizedBox(
                  height: 80,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text('$_dateText', style: style.copyWith(
                              fontSize: 20)),
                        ],
                      ),
                      const Row(
                        children: <Widget>[
                          Text(''),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(_timeDetails!,
                              style: style.copyWith(fontSize: 15)),
                        ],
                      )
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child:
                      Text('닫기', style: style.copyWith(color: PRIMARY_COLOR)))
                ],
              );
            });
      }
    }
    else if (details.date!
        .isBefore(currentTime.subtract(const Duration(hours: 3)))) {
      //오늘보다 이전 날짜가 선택 된 경우
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                  child: Text(
                    '선택된 날짜에는 \n예약할 수 없습니다!',
                    style: style.copyWith(
                      color: PRIMARY_COLOR,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  )),
            );
          });
    }
    else if (details.date!
        .isAfter(semesterduration[thissemester[1]][1])) {
      //다음 학기가 선택된 경우
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                  child: Text('다음 학기 수업은\n 해당 학기에 예약할 수 있습니다.',
                      style: style.copyWith(color: PRIMARY_COLOR, fontSize: 15),
                      textAlign: TextAlign.center)),
            );
          });
    }
    else if (filteredSchedules.length >= 4) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                  child: Text('예약 가능한 수업권이 없습니다.',
                      style: style.copyWith(
                          color: PRIMARY_COLOR, fontSize: 15))),
            );
          });
    }
    else if (DateFormat.EEEE().format(details.date!).substring(0, 3) == 'Mon') {
      print('월요일이 선택되었습니다..');
      DateTime tmp1 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Mon'][0].hour,
          WorkTime['Mon'][0].minute);
      DateTime tmp2 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Mon'][1].hour,
          WorkTime['Mon'][1].minute);
      if ((details.date!.isAfter(tmp1) || details.date! == tmp1) &&
          details.date!.isBefore(tmp2)) {
        print('예약 가능한 시간대입니다');
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('예약 가능',
                        style: style.copyWith(color: PRIMARY_COLOR))),
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                              DateFormat('yyyy년 M월 dd일')
                                  .format(details.date!)
                                  .toString(),
                              style: style.copyWith(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                              '${details.date!.hour.toString().padLeft(
                                  2, '0')}:${details.date!.minute.toString()
                                  .padLeft(2, '0')} '
                                  '- ${details.date!.add(
                                  const Duration(minutes: 30)).hour.toString()
                                  .padLeft(2, '0')}:${details.date!.add(
                                  const Duration(minutes: 30)).minute.toString()
                                  .padLeft(2, '0')}',
                              style: style.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('예약 하시겠습니까?', style: style.copyWith(fontSize: 17))
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final newone = ScheduleModel(
                                id: UserName,
                                date: details.date!,
                                teacher: TeacherName,
                                rebook: true);
                            onSavePressed(newone);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                          },
                          child: Text('예',
                              style: style.copyWith(color: PRIMARY_COLOR))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('아니요',
                              style: style.copyWith(color: Colors.red)))
                    ],
                  ),
                ],
              );
            });
      }
    }
    else if (DateFormat.EEEE().format(details.date!).substring(0, 3) == 'Tue') {
      print('화요일이 선택되었습니다..');
      DateTime tmp1 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Tue'][0].hour,
          WorkTime['Tue'][0].minute);
      DateTime tmp2 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Tue'][1].hour,
          WorkTime['Tue'][1].minute);
      if ((details.date!.isAfter(tmp1) || details.date! == tmp1) &&
          details.date!.isBefore(tmp2)) {
        print('예약 가능한 시간대입니다');
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('예약 가능',
                        style: style.copyWith(color: PRIMARY_COLOR))),
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                              DateFormat('yyyy년 M월 dd일')
                                  .format(details.date!)
                                  .toString(),
                              style: style.copyWith(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                              '${details.date!.hour.toString().padLeft(
                                  2, '0')}:${details.date!.minute.toString()
                                  .padLeft(2, '0')} '
                                  '- ${details.date!.add(
                                  const Duration(minutes: 30)).hour.toString()
                                  .padLeft(2, '0')}:${details.date!.add(
                                  const Duration(minutes: 30)).minute.toString()
                                  .padLeft(2, '0')}',
                              style: style.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('예약 하시겠습니까?', style: style.copyWith(fontSize: 17))
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final newone = ScheduleModel(
                                id: UserName,
                                date: details.date!,
                                teacher: TeacherName,
                                rebook: true);
                            onSavePressed(newone);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                          },
                          child: Text('예',
                              style: style.copyWith(color: PRIMARY_COLOR))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('아니요',
                              style: style.copyWith(color: Colors.red)))
                    ],
                  ),
                ],
              );
            });
      }
    }
    else if (DateFormat.EEEE().format(details.date!).substring(0, 3) == 'Wed') {
      print('수요일이 선택되었습니다..');
      DateTime tmp1 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Wed'][0].hour,
          WorkTime['Wed'][0].minute);
      DateTime tmp2 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Wed'][1].hour,
          WorkTime['Wed'][1].minute);
      if ((details.date!.isAfter(tmp1) || details.date! == tmp1) &&
          details.date!.isBefore(tmp2)) {
        print('예약 가능한 시간대입니다');
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('예약 가능',
                        style: style.copyWith(color: PRIMARY_COLOR))),
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                              DateFormat('yyyy년 M월 dd일')
                                  .format(details.date!)
                                  .toString(),
                              style: style.copyWith(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                              '${details.date!.hour.toString().padLeft(
                                  2, '0')}:${details.date!.minute.toString()
                                  .padLeft(2, '0')} '
                                  '- ${details.date!.add(
                                  const Duration(minutes: 30)).hour.toString()
                                  .padLeft(2, '0')}:${details.date!.add(
                                  const Duration(minutes: 30)).minute.toString()
                                  .padLeft(2, '0')}',
                              style: style.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('예약 하시겠습니까?', style: style.copyWith(fontSize: 17))
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final newone = ScheduleModel(
                                id: UserName,
                                date: details.date!,
                                teacher: TeacherName,
                                rebook: true);
                            onSavePressed(newone);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                          },
                          child: Text('예',
                              style: style.copyWith(color: PRIMARY_COLOR))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('아니요',
                              style: style.copyWith(color: Colors.red)))
                    ],
                  ),
                ],
              );
            });
      }
    }
    else if (DateFormat.EEEE().format(details.date!).substring(0, 3) == 'Thu') {
      print('목요일이 선택되었습니다..');
      DateTime tmp1 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Thu'][0].hour,
          WorkTime['Thu'][0].minute);
      DateTime tmp2 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Thu'][1].hour,
          WorkTime['Thu'][1].minute);
      if ((details.date!.isAfter(tmp1) || details.date! == tmp1) &&
          details.date!.isBefore(tmp2)) {
        print('예약 가능한 시간대입니다');
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('예약 가능',
                        style: style.copyWith(color: PRIMARY_COLOR))),
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                              DateFormat('yyyy년 M월 dd일')
                                  .format(details.date!)
                                  .toString(),
                              style: style.copyWith(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                              '${details.date!.hour.toString().padLeft(
                                  2, '0')}:${details.date!.minute.toString()
                                  .padLeft(2, '0')} '
                                  '- ${details.date!.add(
                                  const Duration(minutes: 30)).hour.toString()
                                  .padLeft(2, '0')}:${details.date!.add(
                                  const Duration(minutes: 30)).minute.toString()
                                  .padLeft(2, '0')}',
                              style: style.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('예약 하시겠습니까?', style: style.copyWith(fontSize: 17))
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final newone = ScheduleModel(
                                id: UserName,
                                date: details.date!,
                                teacher: TeacherName,
                                rebook: true);
                            onSavePressed(newone);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                          },
                          child: Text('예',
                              style: style.copyWith(color: PRIMARY_COLOR))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('아니요',
                              style: style.copyWith(color: Colors.red)))
                    ],
                  ),
                ],
              );
            });
      }
    }
    else if (DateFormat.EEEE().format(details.date!).substring(0, 3) == 'Fri') {
      print('금요일이 선택되었습니다..');
      DateTime tmp1 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Fri'][0].hour,
          WorkTime['Fri'][0].minute);
      DateTime tmp2 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Fri'][1].hour,
          WorkTime['Fri'][1].minute);
      if ((details.date!.isAfter(tmp1) || details.date! == tmp1) &&
          details.date!.isBefore(tmp2)) {
        print('예약 가능한 시간대입니다');
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('예약 가능',
                        style: style.copyWith(color: PRIMARY_COLOR))),
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                              DateFormat('yyyy년 M월 dd일')
                                  .format(details.date!)
                                  .toString(),
                              style: style.copyWith(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                              '${details.date!.hour.toString().padLeft(
                                  2, '0')}:${details.date!.minute.toString()
                                  .padLeft(2, '0')} '
                                  '- ${details.date!.add(
                                  const Duration(minutes: 30)).hour.toString()
                                  .padLeft(2, '0')}:${details.date!.add(
                                  const Duration(minutes: 30)).minute.toString()
                                  .padLeft(2, '0')}',
                              style: style.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('예약 하시겠습니까?', style: style.copyWith(fontSize: 17))
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final newone = ScheduleModel(
                                id: UserName,
                                date: details.date!,
                                teacher: TeacherName,
                                rebook: true);
                            onSavePressed(newone);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                          },
                          child: Text('예',
                              style: style.copyWith(color: PRIMARY_COLOR))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('아니요',
                              style: style.copyWith(color: Colors.red)))
                    ],
                  ),
                ],
              );
            });
      }
    }
    else if (DateFormat.EEEE().format(details.date!).substring(0, 3) == 'Sat') {
      print('토요일이 선택되었습니다..');
      DateTime tmp1 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Sat'][0].hour,
          WorkTime['Sat'][0].minute);
      DateTime tmp2 = DateTime(
          details.date!.year,
          details.date!.month,
          details.date!.day,
          WorkTime['Sat'][1].hour,
          WorkTime['Sat'][1].minute);
      if ((details.date!.isAfter(tmp1) || details.date! == tmp1) &&
          details.date!.isBefore(tmp2)) {
        print('예약 가능한 시간대입니다');
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Container(
                    child: Text('예약 가능',
                        style: style.copyWith(color: PRIMARY_COLOR))),
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                              DateFormat('yyyy년 M월 dd일')
                                  .format(details.date!)
                                  .toString(),
                              style: style.copyWith(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                              '${details.date!.hour.toString().padLeft(
                                  2, '0')}:${details.date!.minute.toString()
                                  .padLeft(2, '0')} '
                                  '- ${details.date!.add(
                                  const Duration(minutes: 30)).hour.toString()
                                  .padLeft(2, '0')}:${details.date!.add(
                                  const Duration(minutes: 30)).minute.toString()
                                  .padLeft(2, '0')}',
                              style: style.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('예약 하시겠습니까?', style: style.copyWith(fontSize: 17))
                    ],
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final newone = ScheduleModel(
                                id: UserName,
                                date: details.date!,
                                teacher: TeacherName,
                                rebook: true);
                            onSavePressed(newone);
                            await myschedule(context);
                            Navigator.of(context).push(
                              _createRoute(const Rebook_page()),
                            );
                            // onSavePressed(newone);
                            // Navigator.of(context).pop();
                          },
                          child: Text('예',
                              style: style.copyWith(color: PRIMARY_COLOR))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('아니요',
                              style: style.copyWith(color: Colors.red)))
                    ],
                  ),
                ],
              );
            });
      }
    }
  }

  Future<void> onDeletePressed(BuildContext context, DateTime date) async {
    //삭제할 날짜의 데이터를 함수 인자로 받아옴.
    try {
      // 기존 수업 배열에 있던 것을 삭제
      var doc = await FirebaseFirestore.instance.collection('Class').doc(UserID).get();
      var tmp = doc.data()!['class'];
      var TMP = [];

      for (var sche in tmp) {
        TMP.add(DateTime(sche.toDate().year, sche.toDate().month, sche.toDate().day,
            sche.toDate().hour, sche.toDate().minute, 0));
      }
      print('삭제 전 $TMP');
      print(DateTime(date.year, date.month, date.day,
          date.hour, date.minute, 0));
      TMP.remove(DateTime(date.year, date.month, date.day,
          date.hour, date.minute, 0));
      print('삭제 후 $TMP');
      await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'class': TMP});

      //canceled에 취소된 수업 추가
      tmp = doc.data()!['canceled'];
      tmp.add(date);
      await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'canceled': tmp});

    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Container(
                  child: Text(
                    '오류',
                    style: style.copyWith(
                      color: PRIMARY_COLOR,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,)),
              content: Text('스케줄 정보를 수정하는 과정에서 오류가 발생했습니다',
                  style: style.copyWith(fontSize: 15)));
          });
    }
  }
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

class MeetingDataSource extends CalendarDataSource {
  /// Creates a meeting data source, which used to set the appointment
  /// collection to the calendar
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getMeetingData(index).from;
  }

  @override
  DateTime getEndTime(int index) {
    return _getMeetingData(index).to;
  }

  @override
  String getSubject(int index) {
    return _getMeetingData(index).eventName;
  }

  @override
  Color getColor(int index) {
    return _getMeetingData(index).background;
  }

  @override
  bool isAllDay(int index) {
    return _getMeetingData(index).isAllDay;
  }

  Meeting _getMeetingData(int index) {
    final dynamic meeting = appointments![index];
    late final Meeting meetingData;
    if (meeting is Meeting) {
      meetingData = meeting;
    }
    return meetingData;
  }
}

class Meeting {
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  /// Event name which is equivalent to subject property of [Appointment].
  String eventName;

  /// From which is equivalent to start time property of [Appointment].
  DateTime from;

  /// To which is equivalent to end time property of [Appointment].
  DateTime to;

  /// Background which is equivalent to color property of [Appointment].
  Color background;

  /// IsAllDay which is equivalent to isAllDay property of [Appointment].
  bool isAllDay;
}
