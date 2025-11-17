import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forestring_student_1/Data/constant.dart';
import 'package:forestring_student_1/Home_page.dart';
import 'package:forestring_student_1/Intro/Auth_page.dart';

class Intro_page extends StatefulWidget {
  const Intro_page({super.key});

  @override
  State<StatefulWidget> createState() {
    return _Intro_page();
  }
}

class _Intro_page extends State<Intro_page> {
  String? userid; // 사용자 이름(로그인용 id)를 저장하기 위한 변수
  String? userpw;
  static const storage = FlutterSecureStorage();
  bool logincheck = false;

  @override
  void initState() {
    super.initState();
    _asyncMethod();
  }

  void _asyncMethod() async {
    //read 함수를 통하여 key 값에 맞는 정보를 불러옴. (자료형은 Striing)
    //당연히 데이터 없을 땐 null 반영
    try {
      userid = (await storage.read(key: "id"))!;
      userpw = (await storage.read(key: "pw"))!;
      if(userid!= null) {
        setState(() {
          logincheck = true;
        });
      }
      UserID = userid!;
      Userpw = userpw!;
      await getMyModel();
    } catch (e) {
      print('async 함수에서 발생한 에러 \n $e \n ---------------------');
    }
  }

  Future<void> login() async {
    print('login 함수 실행됨');
    try{
      await semester();
      await myschedule(context);
      await getWorkHour(UserModel.teacherID);
      await otherstudent(context);
      await othersshcedule(context);
    } catch (e) {
      print('login 함수에서 발생한 에러 \n $e \n --------------------');
    }
    print('로그인 함수 종료됨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PRIMARY_COLOR,
      body: FutureBuilder(
        future: connectCheck(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              print('activating');
              return const Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.done:
              print('done');
              if (snapshot.data != null) {
                if (snapshot.data!) {
                  if(logincheck == true) {
                    Future.delayed(const Duration(seconds: 2), () async {
                      await login();
                      Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(builder: (context) {
                            return const Home_page();
                          }));
                    });
                  } else {
                    Future.delayed(const Duration(seconds: 2), () async {
                      Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(builder: (context) {
                        return const Auth_page();
                      }));
                    });
                  }
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset('assets/img/FORESTRING_Logo.png',
                            fit: BoxFit.contain),
                      ),
                    ],
                  ),
                );
              } else {
                return const AlertDialog(
                    title: Text('포레스트링 수강생'),
                    content: Text('지금 인터넷에 연결되지 않아 포레스트링 앱을 실행할 수 없습니다.'
                        '네트워크 연결 후 다시 실행 해 주십시오.'));
              }
            case ConnectionState.none:
              return const Center(
                child: Text('데이터가 없습니다'),
              );
            case ConnectionState.waiting:
              print('waiting');
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }

  Future<bool> connectCheck() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty) return false;
    if (connectivityResult.first == ConnectivityResult.mobile ||
        connectivityResult.first == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }
}

// Future<void> getMyModel() async {
//   //내 학생 정보를 불러와 Student 모델로 UserModel에 저장하는 함수.
//   CollectionReference<Map<String, dynamic>> collectionReference =
//   FirebaseFirestore.instance.collection('student');
//   QuerySnapshot<Map<String, dynamic>> querySnapshot =
//   await collectionReference.get();
//   // 모든 학생 리스트가 불러와 진 상태.
//   // 나 이외의 다른 학생들은 Student
//   for (var doc in querySnapshot.docs) {
//     if (UserID == doc.id) {
//       UserModel = Student.fromJson(json: doc.data());
//     }
//     //일치하는 아이디를 찾아서 mymodel에 저장하기.
//   }
//   print(UserModel.id);
//   collectionReference = FirebaseFirestore.instance.collection('teacher');
//   querySnapshot = await collectionReference.get();
//   for (var doc in querySnapshot.docs) {
//     if (UserModel.teacherID == doc.id) {
//       TeacherName = doc.data()['name'];
//     }
//   }
//   print(TeacherName);
//   print('-- 메인 페이지 UserModel, 선생님 성함까지 잘 저장됨 -- ');
// }
//
// Future<void> getWorkHour(String teacherID) async {
//   //선생님의 근무 시간을 불러와 저장해 주는 함수.
//   DocumentReference<Map<String, dynamic>> DocumentRef =
//   FirebaseFirestore.instance.collection('teacher').doc(teacherID);
//   DocumentSnapshot<Map<String, dynamic>> DocumentSnap = await DocumentRef.get();
//
//   var tmp = await FirebaseFirestore.instance
//       .collection('teacher')
//       .doc(teacherID)
//       .collection('BanTime')
//       .get();
//   for (var doc in tmp.docs) {
//     //벤타임 업데이트
//     bantime.add(doc.id);
//     BanTime.addAll({
//       doc.id: [
//         doc.data()['0'].toDate(),
//         doc.data()['1'].toDate()
//       ]
//     });
//     print(BanTime);
//   }
//   Map<String, dynamic>? doc = DocumentSnap.data();
//   if (doc != null) {
//     WorkTime = {
//       'Mon': [
//         doc['Mon'][0].toDate(),
//         doc['Mon'][1].toDate()
//       ],
//       'Tue': [
//         doc['Tue'][0].toDate(),
//         doc['Tue'][1].toDate()
//       ],
//       'Wed': [
//         doc['Wed'][0].toDate(),
//         doc['Wed'][1].toDate()
//       ],
//       'Thu': [
//         doc['Thu'][0].toDate(),
//         doc['Thu'][1].toDate()
//       ],
//       'Fri': [
//         doc['Fri'][0].toDate(),
//         doc['Fri'][1].toDate()
//       ],
//       'Sat': [
//         doc['Sat'][0].toDate(),
//         doc['Sat'][1].toDate()
//       ],
//     };
//     print(WorkTime);
//   }
// }
//
// Future<void> semester() async {
//   DateTime tmp1 = DateTime(DateTime.now().year, DateTime.now().month, 1)
//       .subtract(const Duration(days: 15));
//   DateTime tmp2 = DateTime(DateTime.now().year, DateTime.now().month, 28)
//       .add(const Duration(days: 15));
//   DateTime now = DateTime.now();
//
//   //12월, 1월 사이에 걸친 경우를 위한 변수 선언
//   DocumentSnapshot<Map<String, dynamic>> tmp = await FirebaseFirestore.instance
//       .collection('Class')
//       .doc(DateTime.now().year.toString())
//       .get();
//   DateTime TMP1 = tmp[DateTime.now().month.toString()][0].toDate();
//   DateTime TMP2 = tmp[DateTime.now().month.toString()][1].toDate();
//   int year = DateTime.now().year;
//
//   //지금 시간 기준 이번 달 이 이번 학기인지 확인하기
//   if (TMP2.isAfter(DateTime.now()) && TMP1.isBefore(DateTime.now())) {
//     //이번 학기가 맞다
//     thissemester[1] = DateTime.now().month;
//   } else if (TMP1.isAfter(DateTime.now())) {
//     //만약 지금 10월인데 아직 10월 학기가 아니다
//     thissemester[1] = tmp1.month;
//     now = tmp1;
//     tmp1 = now.subtract(const Duration(days: 30));
//     tmp2 = now.add(const Duration(days: 30));
//   } else {
//     //만약 지금 10월인데 10월 학기가 끝났다
//     thissemester[1] = tmp2.month;
//     now = tmp2;
//     tmp1 = now.subtract(const Duration(days: 30));
//     tmp2 = now.add(const Duration(days: 30));
//   }
//   thissemester[0] = tmp1.month;
//   thissemester[2] = tmp2.month;
//
//   tmp = await FirebaseFirestore.instance
//       .collection('Class')
//       .doc(now.year.toString())
//       .get();
//   semesterduration[thissemester[1]] = [
//     tmp[thissemester[1].toString()][0].toDate(),
//     tmp[thissemester[1].toString()][1].toDate(),
//   ];
//
//   tmp = await FirebaseFirestore.instance
//       .collection('Class')
//       .doc(tmp1.year.toString())
//       .get();
//   semesterduration[thissemester[0]] = [
//     tmp[thissemester[0].toString()][0].toDate(),
//     tmp[thissemester[0].toString()][1].toDate(),
//   ];
//
//   tmp = await FirebaseFirestore.instance
//       .collection('Class')
//       .doc(tmp2.year.toString())
//       .get();
//   semesterduration[thissemester[2]] = [
//     tmp[thissemester[2].toString()][0].toDate(),
//     tmp[thissemester[2].toString()][1].toDate(),
//   ];
//   print('---------$thissemester------------');
//   print(
//       '---------${semesterduration[thissemester[0]][0]}------------');
// }
//
// Future<void> myschedule(BuildContext context) async {
//   Rebooked = [];
//   Canceled = [];
//   List<ScheduleModel> myclass = [];
//   List<DateTime> TmpClass = [];
//   TextStyle style = const TextStyle(
//       color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);
//   try {
//     DocumentReference<Map<String, dynamic>> DocRef =
//     FirebaseFirestore.instance.collection('Class').doc(UserID);
//     DocumentSnapshot<Map<String, dynamic>> tmp = await DocRef.get();
//     int i = 0;
//     for (var sche in tmp.data()!['class']) {
//       if(sche.toDate().isBefore(semesterduration[thissemester[0]][0])){
//         print(sche.toDate());
//       } else {
//         ScheduleModel schedule = ScheduleModel(
//             id: UserID,
//             date: sche.toDate(),
//             teacher: UserModel.teacherID.toString(),
//             rebook: false,
//             num: i);
//         myclass.add(schedule);
//         TmpClass.add(sche.toDate());
//         i++;
//       }
//     }
//     i = 0;
//     await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'class': TmpClass});
//     myclass.sort((a,b) => a.date.compareTo(b.date));
//     TmpClass = [];
//
//     for (var sche in tmp.data()!['rebooked']) {
//       if(sche.toDate().isBefore(semesterduration[thissemester[0]][0])){
//         print(sche.toDate());
//       } else {
//         ScheduleModel schedule = ScheduleModel(
//             id: UserID,
//             date: sche.toDate(),
//             teacher: UserModel.teacherID.toString(),
//             rebook: true,
//             num: i);
//         Rebooked.add(schedule);
//         TmpClass.add(sche.toDate());
//         i++;
//       }
//     }
//     i = 0;
//     await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'rebooked': TmpClass});
//     Rebooked.sort((a,b) => a.date.compareTo(b.date));
//     TmpClass = [];
//
//     for (var sche in tmp.data()!['canceled']) {
//       if(sche.toDate().isBefore(semesterduration[thissemester[0]][0])){
//         print(sche.toDate());
//       }else{
//         ScheduleModel schedule = ScheduleModel(
//             id: UserID,
//             date: sche.toDate(),
//             teacher: UserModel.teacherID.toString(),
//             rebook: true,
//             num: i);
//         Canceled.add(schedule);
//         TmpClass.add(sche.toDate());
//         i++;
//       }
//     }
//     await FirebaseFirestore.instance.collection('Class').doc(UserID).update({'canceled': TmpClass});
//     Canceled.sort((a,b) => a.date.compareTo(b.date));
//
//     Schedules = myclass;
//   } catch (e) {
//     print(e);
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Container(
//                 child: Text(
//                   '오류',
//                   style: style.copyWith(
//                     color: PRIMARY_COLOR,
//                     fontSize: 17,
//                   ),
//                   textAlign: TextAlign.center,
//                 )),
//             content: Text('스케쥴을 불러오는데 오류가 발생했습니다',
//                 style: style.copyWith(fontSize: 15)),
//           );
//         });
//   }
// }
//
// Future<void> otherstudent(BuildContext context) async {
//   TextStyle style = const TextStyle(
//       color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);
//   try {
//     StudentList = [];
//     DocumentReference<Map<String, dynamic>> DocumentRef = FirebaseFirestore
//         .instance
//         .collection('teacher')
//         .doc(UserModel.teacherID);
//     DocumentSnapshot<Map<String, dynamic>> tmp = await DocumentRef.get();
//     StudentList = tmp.data()!['students'];
//   } catch (e) {
//     print(e);
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Container(
//                 child: Text(
//                   '오류',
//                   style: style.copyWith(
//                     color: PRIMARY_COLOR,
//                     fontSize: 17,
//                   ),
//                   textAlign: TextAlign.center,
//                 )),
//             content: Text('학생 정보를 불러오는 과정에서 오류가 발생했습니다',
//                 style: style.copyWith(fontSize: 15)),
//           );
//         });
//   }
// }
//
// Future<void> othersshcedule(BuildContext context) async {
//   BookedSchedules = [];
//   List<DateTime> TmpClass = [];
//
//   TextStyle style = const TextStyle(
//       color: Colors.black, fontFamily: 'ELAND', fontWeight: FontWeight.w300);
//
//   try {
//     for (int i =0; i < StudentList.length; i ++ ){
//       if(StudentList[i] != UserID) {
//         DocumentReference<Map<String, dynamic>> DocRef =
//         FirebaseFirestore.instance.collection('Class').doc(StudentList[i]);
//         DocumentSnapshot<Map<String, dynamic>> tmp = await DocRef.get();
//         for (var sche in tmp.data()!['class']){
//           TmpClass.add(sche.toDate());
//         }
//         for (var shce in tmp.data()!['rebooked']) {
//           TmpClass.add(shce.toDate());
//         }
//       }
//     }
//   } catch (e) {
//     print(e);
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Container(
//                 child: Text(
//                   '오류',
//                   style: style.copyWith(
//                     color: PRIMARY_COLOR,
//                     fontSize: 17,
//                   ),
//                   textAlign: TextAlign.center,
//                 )),
//             content: Text('스케쥴을 불러오는데 오류가 발생했습니다',
//                 style: style.copyWith(fontSize: 15)),
//           );
//         });
//   }
//   BookedSchedules = TmpClass;
//   print(BookedSchedules.length);
//   print(BookedSchedules[0]);
// }