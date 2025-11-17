import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forestring_student_1/ver2/constant_data.dart';
import 'package:provider/provider.dart';
import 'Login.dart';
import 'Menu/Home.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _Intro();
}

class _Intro extends State<Intro> {
  static const storage = FlutterSecureStorage();
  bool logincheck = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInternetAndLogin();
  }
  // ** 인터넷 연결 확인 후 자동 로그인 시도**
  Future<void> _checkInternetAndLogin() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // 인터넷 연결 없음 → 사용자에게 알림
      _showNoInternetDialog();
      return;
    }

    // 인터넷 연결이 있으면 자동 로그인 시도
    _attemptAutoLogin();
  }

  // ** 자동 로그인 시도**
  Future<void> _attemptAutoLogin() async {
    try {
      // 1. 저장된 사용자 정보 불러오기
      String? userId = await storage.read(key: "auto_id.ver2");
      String? userPw = await storage.read(key: "auto_pw.ver2");

      if (userId == null || userPw == null) {
        // 자동 로그인 된 정보가 없다면 로그인 페이지로 바로 이동
        _navigateToLogin();
        return;
      }

      // 2. `StudentProvider`를 가져와서 Firestore에서 사용자 정보 불러오기
      final userProvider = Provider.of<StudentProvider>(context, listen: false);
      await userProvider.fetchStudentData(userId);

      // 학생이 아닌 경우 → 리스너 해제 후 로그인 화면 이동
      if (userProvider.role != 'student') {
        userProvider.resetStudentData(); // 리스너 + 변수 초기화
        _navigateToLogin();
        return;
      }

      // 비밀번호 불일치 → 리스너 해제 후 로그인 화면 이동
      if (userProvider.password != userPw) {
        userProvider.resetStudentData(); // 안전하게 초기화
        _navigateToLogin();
        return;
      }

      // // 3. FCM 토큰 일치 여부 확인
      // final currentToken = await FirebaseMessaging.instance.getToken();
      // final savedToken = userProvider.fcmToken;
      //
      // if (currentToken != savedToken) {
      //   debugPrint("FCM 토큰 불일치: 저장된 토큰: $savedToken / 현재 토큰: $currentToken");
      //   userProvider.resetStudentData();
      //   await storage.delete(key: "auto_id.ver2");
      //   await storage.delete(key: "auto_pw.ver2");
      //   _navigateToLogin();
      //   return;
      // }

      await fetchSemesterInfo();
      await showNotificationPermissionDialog(context);

      // 3. Firestore 데이터 로드 완료 후 홈 화면으로 이동
      _navigateToHome();

    } catch (e) {
      debugPrint("❌ 자동 로그인 중 오류 발생: $e");
      _navigateToLogin(); // 오류 발생 시 로그인 화면 이동
    }
  }
  // 로그인 페이지로 이동
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      _createRoute(const Login()),
    );
  }

  // 홈 화면으로 이동
  void _navigateToHome() {
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushReplacement(
      _createRoute(const Home()),
    );
  }

  // 인터넷 연결이 없을 때 다이얼로그 표시
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('인터넷 연결 오류'),
          content: const Text('인터넷에 연결되지 않았습니다. 연결을 확인하고 다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
                _checkInternetAndLogin(); // 재시도
              },
              child: const Text('재시도'),
            ),
          ],
        );
      },
    );
  }
  void showLoadingDialog() {
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
                "수업 정보를 불러오는 중...",
                style: style.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // UI 부분

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: PRIMARY_COLOR,
        body: Stack(
          children: [
            Container(
              color: PRIMARY_COLOR, // 배경 색 설정
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset('assets/img/로고_배경제거.png',
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.73
                    ),
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
}