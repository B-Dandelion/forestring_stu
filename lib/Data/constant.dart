import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forestring_student_1/Class_page.dart';
import 'package:forestring_student_1/Data/LessonClass.dart';
import 'package:forestring_student_1/Data/StudentClass.dart';
import 'package:forestring_student_1/Data/TeacherClass.dart';
import 'package:forestring_student_1/Data/schedule_model.dart';
import 'package:forestring_student_1/Data/student_model.dart';
import 'package:forestring_student_1/Home_page.dart';
import 'package:forestring_student_1/Intro/Auth_page.dart';
import 'package:forestring_student_1/New_Intro_page/new_Auth_page.dart';
import 'package:forestring_student_1/New_Main_page/New_Home_page.dart';
import 'package:forestring_student_1/New_Main_page/New_My_page.dart';
import 'package:forestring_student_1/New_Main_page/New_Rebook_page.dart';
import 'package:forestring_student_1/Rebook_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

const PRIMARY_COLOR = Color(0xff003717);
const SECONDARY_COLOR = Color(0xff708C7A);
const IBORY = Color(0xffFDF8E7);
const ERROR_COLOR = Colors.red;
const TEXT_FIELD_FILL_COLOR = Colors.black;

const APP_TYPE = 'STU';

List<int> thissemester = [0,0,0];
Map<int, dynamic> semesterduration = {};

Map<String, dynamic> BanTime = {};
List<String> bantime = [];
Map<String, dynamic> WorkTime = {};

//선생님의 예약 정보 불러오기
List<DateTime> BookedSchedules = [];

//내 스케쥴 정보와 바뀐 스케쥴, 취소한 스케쥴 리스트
List<ScheduleModel> Schedules = [];
List<ScheduleModel> Rebooked = [];
List<ScheduleModel> Canceled = [];


//모든 학생들의 정보가 저장된 리스트. id, pw, 수업 요일, 시작 시간, 선생님
List<dynamic> StudentList = [];

// 12월 수정 모델을 여기부터

StudentClass User = StudentClass(id: '' , name: '', role: 'student',
    classDay: DateTime(2024,1,1), password: '', teacherID: '', teacherName: '', classList: []);
TeacherClass UserTeacher = TeacherClass(id: 'id', name: 'name', role: 'teacher', password: 'password1111',
    studentList: [], workTime: [], classList: []);

//현실 날짜
DateTime now = DateTime.now();
DateTime previousMonth = DateTime(now.year, now.month - 1, now.day);
DateTime nextMonth = DateTime(now.year, now.month + 1, now.day);

//학기 날짜
DateTime nowsemester = now;
DateTime previoussemester = previousMonth;
DateTime nextsemester = nextMonth;

Map<int, dynamic> SemesterTerm = {};

List<Lesson> LessonList = [];
// 나의 수업 리스트를 저장하고 있는 리스트입니다.
List<Lesson> TeacherLessons = [];
// 선생님의 수업 리스트를 저장하고 있는 리스트입니다. (내 스케줄을 포함)

//여기 이후는 기존 모델 코드

String UserID = '';
String UserName = '';
String Userpw = '';
String TeacherName = '';
Student UserModel = Student(id:UserID, name: '', startTime: DateTime.now(), teacherID: '');

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

  const BookingBanner({
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
        child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '예약 가능 시간',
                  style: textStyle,
                )
              ],
            )
        )
    );
  }
}

class MainCalendar extends StatelessWidget {
  final OnDaySelected onDaySelected;
  final DateTime selectedDate;

  const MainCalendar({super.key,
    required this.onDaySelected,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      onDaySelected: onDaySelected,
      selectedDayPredicate: (date) =>
      date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,

      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
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
        },
      ),

      focusedDay: DateTime.now(),
      //화면에 보여지는 날짜
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2059, 12, 31),
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
          color: PRIMARY_COLOR,
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
    );
  }
}

class BaseDrawer extends StatelessWidget {
  const BaseDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              '${UserModel.name} 님',
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
              '메인페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext context) => const Home_page()),
                      (route) => false);
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '마이페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                _createRoute(const Class_page()),
              );
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '예약 변경하기',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () async {
              Navigator.of(context).push(
                _createRoute(const Rebook_page()),
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

              UserID = '';
              Userpw = '';
              UserModel = Student(id:UserID, name: '', startTime: DateTime.now(), teacherID: '');
              Schedules = [];
              StudentList = [];
              Rebooked = [];
              WorkTime = {};
              bantime = [];
              BanTime = {};

              // Navigator.of(context).push(
              //   _createRoute(const Auth_page()),
              // );
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext context) => const Auth_page()),
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
class NewDrawer extends StatelessWidget {
  const NewDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              '${User.name} 님',
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
              '메인페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext context) => const New_Home_page()),
                      (route) => false);
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '마이페이지',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                _createRoute(const New_My_page()),
              );
            },
            trailing: const Icon(Icons.navigate_next_rounded),
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            iconColor: PRIMARY_COLOR,
            focusColor: IBORY,
            title: const Text(
              '예약 변경하기',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
              ),
            ),
            onTap: () async {
              // 예약 페이지에 들어가기 전에 수업 리스트를 한 번 업데이트 해줍니다.
              await TeacherModel();
              await GetLesson();
              Navigator.of(context).push(
                _createRoute(const BookingScreen()),
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

              UserName = '';
              TeacherName = '';
              UserID = '';
              Userpw = '';
              LessonList = [];
              TeacherLessons = [];

              User = StudentClass(id: '' , name: '', role: 'student',
                  classDay: DateTime(2024,1,1), password: '', teacherID: '', teacherName: '', classList: []);

              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext context) => const New_Auth_page()),
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

//이전 버전 함수

Future<void> getMyModel() async {
  //내 학생 정보를 불러와 Student 모델로 UserModel에 저장하는 함수.

  CollectionReference<Map<String, dynamic>> collectionReference =
  FirebaseFirestore.instance.collection('student');
  QuerySnapshot<Map<String, dynamic>> querySnapshot = await collectionReference.get();
  // 모든 학생 리스트가 불러와 진 상태.

  // 내 정보만 저장하기
  for (var doc in querySnapshot.docs) {
    if (UserID == doc.id) {
      UserModel = Student.fromJson(json: doc.data());
    }
    //일치하는 아이디를 찾아서 mymodel에 저장하기.
  }
  print(UserModel.id);
  collectionReference = FirebaseFirestore.instance.collection('teacher');
  querySnapshot = await collectionReference.get();
  for (var doc in querySnapshot.docs) {
    if (UserModel.teacherID == doc.id) {
      TeacherName = doc.data()['name'];
    }
  }
  print(TeacherName);
  print('-- 메인 페이지 UserModel, 선생님 성함까지 잘 저장됨 -- ');
}

Future<void> getWorkHour(String teacherID) async {
  //선생님의 근무 시간을 불러와 저장해 주는 함수.
  DocumentReference<Map<String, dynamic>> DocumentRef =
  FirebaseFirestore.instance.collection('teacher').doc(teacherID);
  DocumentSnapshot<Map<String, dynamic>> DocumentSnap = await DocumentRef.get();

  var tmp = await FirebaseFirestore.instance
      .collection('teacher')
      .doc(teacherID)
      .collection('BanTime')
      .get();
  for (var doc in tmp.docs) {
    //벤타임 업데이트
    bantime.add(doc.id);
    BanTime.addAll({
      doc.id: [
        doc.data()['0'].toDate(),
        doc.data()['1'].toDate()
      ]
    });
    print(BanTime);
  }
  Map<String, dynamic>? doc = DocumentSnap.data();
  if (doc != null) {
    WorkTime = {
      'Mon': [
        doc['Mon'][0].toDate(),
        doc['Mon'][1].toDate()
      ],
      'Tue': [
        doc['Tue'][0].toDate(),
        doc['Tue'][1].toDate()
      ],
      'Wed': [
        doc['Wed'][0].toDate(),
        doc['Wed'][1].toDate()
      ],
      'Thu': [
        doc['Thu'][0].toDate(),
        doc['Thu'][1].toDate()
      ],
      'Fri': [
        doc['Fri'][0].toDate(),
        doc['Fri'][1].toDate()
      ],
      'Sat': [
        doc['Sat'][0].toDate(),
        doc['Sat'][1].toDate()
      ],
    };
    print(WorkTime);
  }
}

Future<void> semester() async {
  DateTime tmp1 = DateTime(DateTime.now().year, DateTime.now().month, 1)
      .subtract(const Duration(days: 15));
  DateTime tmp2 = DateTime(DateTime.now().year, DateTime.now().month, 28)
      .add(const Duration(days: 15));
  DateTime now = DateTime.now();

  //12월, 1월 사이에 걸친 경우를 위한 변수 선언
  DocumentSnapshot<Map<String, dynamic>> tmp = await FirebaseFirestore.instance
      .collection('Class')
      .doc(DateTime.now().year.toString())
      .get();
  DateTime TMP1 = tmp[DateTime.now().month.toString()][0].toDate();
  DateTime TMP2 = tmp[DateTime.now().month.toString()][1].toDate();
  int year = DateTime.now().year;

  //지금 시간 기준 이번 달 이 이번 학기인지 확인하기
  if (TMP2.isAfter(DateTime.now()) && TMP1.isBefore(DateTime.now())) {
    //이번 학기가 맞다
    thissemester[1] = DateTime.now().month;
  } else if (TMP1.isAfter(DateTime.now())) {
    //만약 지금 10월인데 아직 10월 학기가 아니다
    thissemester[1] = tmp1.month;
    now = tmp1;
    tmp1 = now.subtract(const Duration(days: 30));
    tmp2 = now.add(const Duration(days: 30));
  } else {
    //만약 지금 10월인데 10월 학기가 끝났다
    thissemester[1] = tmp2.month;
    now = tmp2;
    tmp1 = now.subtract(const Duration(days: 30));
    tmp2 = now.add(const Duration(days: 30));
  }
  thissemester[0] = tmp1.month;
  thissemester[2] = tmp2.month;

  tmp = await FirebaseFirestore.instance
      .collection('Class')
      .doc(now.year.toString())
      .get();
  semesterduration[thissemester[1]] = [
    tmp[thissemester[1].toString()][0].toDate(),
    tmp[thissemester[1].toString()][1].toDate(),
  ];

  tmp = await FirebaseFirestore.instance
      .collection('Class')
      .doc(tmp1.year.toString())
      .get();
  semesterduration[thissemester[0]] = [
    tmp[thissemester[0].toString()][0].toDate(),
    tmp[thissemester[0].toString()][1].toDate(),
  ];

  tmp = await FirebaseFirestore.instance
      .collection('Class')
      .doc(tmp2.year.toString())
      .get();
  semesterduration[thissemester[2]] = [
    tmp[thissemester[2].toString()][0].toDate(),
    tmp[thissemester[2].toString()][1].toDate(),
  ];
  print('---------$thissemester------------');
  print(
      '---------${semesterduration[thissemester[0]][0]}------------');
}

Future<void> myschedule(BuildContext context) async {
  Rebooked = [];
  Canceled = [];

  //rebook 리스트와 canceled 리스트에는 이번 달 정보만 저장합니다.

  List<ScheduleModel> myclass = [];
  List<DateTime> TmpClass = [];
  TextStyle style = const TextStyle(
      color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);
  try {
    DocumentReference<Map<String, dynamic>> DocRef =
    FirebaseFirestore.instance.collection('Class').doc(UserID);
    DocumentSnapshot<Map<String, dynamic>> tmp = await DocRef.get();
    for (var sche in tmp.data()!['class']) {
      if(sche.toDate().isBefore(semesterduration[thissemester[0]][0])){
        print(sche.toDate());
      } else {
        ScheduleModel schedule = ScheduleModel(
            id: UserID,
            date: sche.toDate(),
            teacher: UserModel.teacherID.toString(),
            rebook: false);
        myclass.add(schedule);
        TmpClass.add(sche.toDate());
      }
    }
    TmpClass.sort((a,b) => a.compareTo(b));
    myclass.sort((a,b) => a.date.compareTo(b.date));
    await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'class': TmpClass});

    TmpClass = [];

    for (var sche in tmp.data()!['rebooked']) {
      if(sche.toDate().isAfter(semesterduration[thissemester[1]][0]) &&
          sche.toDate().isBefore(semesterduration[thissemester[1]][1])){
        //이번 달 정보만 가져옵니다. (다른 정보는 필요 없어서)
        ScheduleModel schedule = ScheduleModel(
            id: UserID,
            date: sche.toDate(),
            teacher: UserModel.teacherID.toString(),
            rebook: true);
        Rebooked.add(schedule);
        TmpClass.add(sche.toDate());
      }
    }
    TmpClass.sort((a,b) => a.compareTo(b));
    Rebooked.sort((a,b) => a.date.compareTo(b.date));
    await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'rebooked': TmpClass});

    TmpClass = [];

    for (var sche in tmp.data()!['canceled']) {
      if(sche.toDate().isAfter(semesterduration[thissemester[1]][0]) &&
          sche.toDate().isBefore(semesterduration[thissemester[1]][1])){
        //이번 달 정보만 가져옵니다. (다른 정보는 필요 없어서)
        ScheduleModel schedule = ScheduleModel(
            id: UserID,
            date: sche.toDate(),
            teacher: UserModel.teacherID.toString(),
            rebook: true);
        Canceled.add(schedule);
        TmpClass.add(sche.toDate());
      }
    }
    TmpClass.sort((a,b) => a.compareTo(b));
    Canceled.sort((a,b) => a.date.compareTo(b.date));
    await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'canceled': TmpClass});

    Schedules = myclass;
  } catch (e) {
    print(e);
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
                  textAlign: TextAlign.center,
                )),
            content: Text('스케쥴을 불러오는데 오류가 발생했습니다',
                style: style.copyWith(fontSize: 15)),
          );
        });
  }
}

Future<void> otherstudent(BuildContext context) async {
  // 선생님의 다른 학생들을 불러옵니다.
  TextStyle style = const TextStyle(
      color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);
  try {
    StudentList = [];
    DocumentReference<Map<String, dynamic>> DocumentRef = FirebaseFirestore
        .instance
        .collection('teacher')
        .doc(UserModel.teacherID);
    DocumentSnapshot<Map<String, dynamic>> tmp = await DocumentRef.get();
    StudentList = tmp.data()!['students'];
  } catch (e) {
    print(e);
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
                  textAlign: TextAlign.center,
                )),
            content: Text('학생 정보를 불러오는 과정에서 오류가 발생했습니다',
                style: style.copyWith(fontSize: 15)),
          );
        });
  }
}

Future<void> othersshcedule(BuildContext context) async {
  //선생님의 다른 학생들의 스케줄을 불러옵니다
  BookedSchedules = [];
  List<DateTime> TmpClass = [];

  TextStyle style = const TextStyle(
      color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);

  try {
    for (int i =0; i < StudentList.length; i ++ ){
      if(StudentList[i] != UserID) {
        DocumentReference<Map<String, dynamic>> DocRef =
        FirebaseFirestore.instance.collection('Class').doc(StudentList[i]);
        DocumentSnapshot<Map<String, dynamic>> tmp = await DocRef.get();
        for (var sche in tmp.data()!['class']){
          TmpClass.add(sche.toDate());
        }
        for (var shce in tmp.data()!['rebooked']) {
          TmpClass.add(shce.toDate());
        }
      }
    }
  } catch (e) {
    print(e);
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
                  textAlign: TextAlign.center,
                )),
            content: Text('스케쥴을 불러오는데 오류가 발생했습니다',
                style: style.copyWith(fontSize: 15)),
          );
        });
  }
  BookedSchedules = TmpClass;
}

//12월 수정 후 함수

Future<void> MyModel() async    {
  //내 정보 불러 오기 (User)에 저장할 정보 불러오기
  CollectionReference<Map<String, dynamic>> collectionReference =
  FirebaseFirestore.instance.collection('User');
  QuerySnapshot<Map<String, dynamic>> querySnapshot = await collectionReference.get();
  // 모든 유저 ID 리스트가 불러와 진 상태.
  for (var doc in querySnapshot.docs) {
    if (UserID == doc.id) {
      User = StudentClass.fromJson(json: doc.data());
    }
    //일치하는 아이디를 찾아서 User에 저장하기.
  }
  print('MyModel function done');
}
Future<void> TeacherModel() async {
  DocumentReference<Map<String, dynamic>> DocumentRef =
  FirebaseFirestore.instance.collection('User').doc(User.teacherID);
  DocumentSnapshot<Map<String, dynamic>> DocumentSnap = await DocumentRef.get();

  if (DocumentSnap.exists) {
    // 데이터를 JSON으로 가져와서 User 객체로 변환
    UserTeacher = TeacherClass.fromJson(json: DocumentSnap.data()!);
  } else {
    print('선생님 문서가 존재하지 않거나 형식이 잘못되었습니다');
  }
  print('TeacherModel function done');
}
Future<void> Semester() async {
  DocumentSnapshot<Map<String, dynamic>> tmp = await FirebaseFirestore.instance.collection('Class').doc(now.year.toString()).get();
  DateTime TMP1 = tmp[now.month.toString()][0].toDate();
  DateTime TMP2 = tmp[now.month.toString()][1].toDate();
  int year = now.year;
  //현재 날짜 기준 학기 정보 가져오기

  //현재 날짜와 학기 날짜를 대조하여 현재 학기를 구함
  if (TMP2.isAfter(now) && TMP1.isBefore(now)) {
    //이번 학기가 맞다
    //따로 고칠 것 없음 (변수 초기 설정값을 그대로 유지)
  } else if (TMP1.isAfter(DateTime.now())) {
    //Ex) 만약 지금 10월인데 아직 10월 학기가 아니다
    nowsemester = previousMonth;
    previoussemester = DateTime(previousMonth.year, previousMonth.month -1);
    nextsemester = now;
  } else {
    //Ex) 만약 지금 10월인데 10월 학기가 끝났다
    nowsemester = nextMonth;
    previoussemester = now;
    nextsemester = DateTime(nextsemester.year, nextMonth.month +1);
  }
  tmp = await FirebaseFirestore.instance.collection('Class').doc(nowsemester.year.toString()).get();
  SemesterTerm[nowsemester.month] = [
    tmp[nowsemester.month.toString()][0].toDate(),
    tmp[nowsemester.month.toString()][1].toDate(),
  ];
  tmp = await FirebaseFirestore.instance.collection('Class').doc(previoussemester.year.toString()).get();
  SemesterTerm[previoussemester.month] = [
    tmp[previoussemester.month.toString()][0].toDate(),
    tmp[previoussemester.month.toString()][1].toDate(),
  ];
  tmp = await FirebaseFirestore.instance.collection('Class').doc(nextsemester.year.toString()).get();
  SemesterTerm[nextsemester.month] = [
    tmp[nextsemester.month.toString()][0].toDate(),
    tmp[nextsemester.month.toString()][1].toDate(),
  ];
}
Future<void> fetchSemesterInfo() async {
  // 현재 학기 데이터 가져오기
  var currentData = await _getSemesterData(now.year, now.month);
  if (currentData != null) {
    SemesterTerm[now.month] = [currentData[0], currentData[1]];
  }
  // 현재 학기 판별
  if (SemesterTerm[now.month][0] != null &&
      SemesterTerm[now.month][1] != null &&
      SemesterTerm[now.month][0].isBefore(now) &&
      SemesterTerm[now.month][1].isAfter(now)) {
    // 현재 학기 유지
  } else if (SemesterTerm[now.month][0] != null && now.isBefore(SemesterTerm[now.month][0])) {
    previoussemester = DateTime(previousMonth.year, previousMonth.month - 1);
    nowsemester = previousMonth;
    nextsemester = now;
  } else {
    nextsemester = DateTime(nextMonth.year, nextMonth.month + 1);
    nowsemester = nextMonth;
    previoussemester = now;
  }
  var nowData = await _getSemesterData(nowsemester.year, nowsemester.month);
  if (nowData != null) {
    SemesterTerm[nowsemester.month] = [nowData[0], nowData[1]];
  }
  var previousData = await _getSemesterData(previoussemester.year, previoussemester.month);
  if (previousData != null) {
    SemesterTerm[previoussemester.month] = [previousData[0], previousData[1]];
  }
  var nextData = await _getSemesterData(nextsemester.year, nextsemester.month);
  if (nextData != null) {
    SemesterTerm[nextsemester.month] = [nextData[0], nextData[1]];
  }
  print('Semester function Completed');
}
Future<List<DateTime>?> _getSemesterData(int year, int month) async {
  try {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('Class').doc(year.toString()).get();

    if (snapshot.exists && snapshot.data()?[month.toString()] != null) {
      var dates = snapshot.data()![month.toString()];
      return [dates[0].toDate(), dates[1].toDate()];
    }
  } catch (e) {
    print("Error fetching semester data: $e");
  }
  return null;
}
Future<void> GetLesson() async {
  // 내 수업 포함, 선생님의 모든 수업을 불러오는 리스트.
  LessonList = [];
  TeacherLessons = [];
  QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance.collection('Class').get();
  for (var doc in snapshot.docs){
    if (UserTeacher.classList.contains(doc.id)) {
      // 수업 ID가 classList에 포함되어 있으면, 해당 수업의 데이터를 Lesson 객체로 변환하여 추가
      Lesson lesson = Lesson.fromJson(
        json: doc.data(), // Firestore에서 가져온 데이터
        id: doc.id, // 외부에서 doc.id를 id로 지정
      );
      if (doc.id.startsWith(User.id)){
        // 내 수업은 LessonList 리스트에 따로 저장. (유효한 수업만!)
        LessonList.add(lesson);
        if(lesson.isValid == true){
          TeacherLessons.add(lesson);
        }
      } else{
        if(lesson.isValid == true){
          TeacherLessons.add(lesson);
        }
      }
    }
  }
  print('Length of my Lesson List : ${LessonList.length}');
  print('Length of Teacher\'s LessonList : ${TeacherLessons.length}');
  print('GetLesson function completed');
}