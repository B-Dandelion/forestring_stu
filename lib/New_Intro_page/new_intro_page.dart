import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forestring_student_1/Data/constant.dart';
import 'package:forestring_student_1/New_Intro_page/new_Auth_page.dart';
import 'package:forestring_student_1/New_Main_page/New_Home_page.dart';

class New_Intro_page extends StatefulWidget {
  const New_Intro_page({super.key});

  @override
  State<StatefulWidget> createState() {
    return _New_Intro_page();
  }
}

class _New_Intro_page extends State<New_Intro_page> {
  String? userid; // 사용자 이름(로그인용 id)를 저장하기 위한 변수
  String? userpw;
  static const storage = FlutterSecureStorage();
  bool logincheck = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _asyncMethod();
  }

  Future<void> _asyncMethod() async {
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
      await login();
    } catch (e) {
      print('async 함수에서 발생한 에러 \n $e \n ---------------------');
    }
    _checkInternetConnection();
  }

  Future<void> login() async {
    print('login 함수 실행됨');
    try{
      await MyModel();
      await TeacherModel();
      await fetchSemesterInfo();
      await GetLesson();
    } catch (e) {
      print('login 함수에서 발생한 에러 \n $e \n --------------------');
    }
    print('로그인 함수 종료됨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PRIMARY_COLOR,
      body: Stack(
        children: [
          Center(
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
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PRIMARY_COLOR), // 녹색 원 모양
              ),
            ),
        ],
      )
    );
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    // 연결된 상태라면 기본 화면을 2초 동안 보여준 후 다른 페이지로 이동
    if (connectivityResult != ConnectivityResult.none) {
      setState(() {
        _isLoading = false; // 로딩 화면을 종료
      });
      // 2초간 기본 화면을 띄운 후 다른 페이지로 이동
      await Future.delayed(Duration(seconds: 2));
      if(logincheck) {
        Navigator.of(context).push(
            _createRoute(New_Home_page()));
      } else {
        Navigator.of(context).push(
            _createRoute(New_Auth_page()));
      }
    } else {
      // 인터넷 연결이 안 됐을 때 안내 팝업
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('인터넷 연결 오류'),
          content: Text('인터넷에 연결되지 않았습니다. 연결을 확인하고 다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
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