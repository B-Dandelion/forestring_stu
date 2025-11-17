import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forestring_student_1/ver2/constant_data.dart';
import 'package:provider/provider.dart';

import 'Menu/Home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _Login();
}

class _Login extends State<Login> {
  bool _isChecked = false;
  bool isButtonEnabled = false; // 버튼 활성화 상태
  final id_controller = TextEditingController();
  final pw_controller = TextEditingController();
  static const storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    id_controller.addListener(_updateButtonState);
    pw_controller.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = id_controller.text.isNotEmpty && pw_controller.text.isNotEmpty;
    });
  }

  void _logIn() async {
    try {

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1. usersByName 컬렉션에서 입력한 이름을 검색
      DocumentSnapshot nameDoc = await firestore.collection('usersByName').doc(
          id_controller.text).get();

      if (!nameDoc.exists) {
        _showLoginError("아이디/비밀번호를 다시 확인해주세요");
        return;
      }

      List<String> userIds = List<String>.from(nameDoc['userIds']);

      // 2. `users` 컬렉션에서 비밀번호 확인
      String? matchedUserId;
      for (String userId in userIds) {
        DocumentSnapshot userDoc = await firestore.collection('users').doc(
            userId).get();
        if (userDoc.exists &&
            userDoc['password'] == pw_controller.text &&
            userDoc['role'] == 'student') {
          matchedUserId = userId;
          break;
        }
      }

      if (matchedUserId == null) {
        _showLoginError("아이디/비밀번호를 다시 확인해주세요");
        return;
      }

      // // 3. FCM 토큰 저장 (비밀번호 확인 직후)
      // final token = await FirebaseMessaging.instance.getToken();
      // if (token != null) {
      //   await firestore.collection('users').doc(matchedUserId).update({
      //     'fcmToken': token,
      //   });
      // }

      // 4. `StudentProvider`를 사용하여 학생 정보 불러오기
      final studentProvider = Provider.of<StudentProvider>(
          context, listen: false);
      await studentProvider.fetchStudentData(matchedUserId);

      // 5. 자동 로그인 저장
      if (_isChecked) {
        await storage.write(key: "auto_id.ver2", value: matchedUserId);
        await storage.write(
            key: "auto_pw.ver2", value: studentProvider.password);
      }
      await fetchSemesterInfo();
      // await showNotificationPermissionDialog(context);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) {
            return Home();
          }));
    } catch (e) {
      debugPrint("로그인 중 오류 발생: $e");
      _showLoginError("로그인 중 오류가 발생했습니다. 다시 시도해주세요.");
    }
  }

  // 로그인 실패 시 에러 메시지 표시 함수
  void _showLoginError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '로그인 실패',
            style: style.copyWith(color: PRIMARY_COLOR, fontSize: 17),
            textAlign: TextAlign.center,
          ),
          content: Text(message, style: style.copyWith(fontSize: 15)),
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

  //UI 부분
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: PRIMARY_COLOR,
        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/img/로고_배경제거.png',
                            width: MediaQuery.of(context).size.width * 0.73,
                          ),
                          const SizedBox(height: 20.0),
                          const Text(
                            '포레스트링 수강생',
                            style: TextStyle(
                                fontFamily: 'ELAND',
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ),
                  // 하단 입력 필드 및 버튼을 고정
                  const SizedBox(height: 20.0),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        const Text(
                          '자동 로그인',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'ELAND',
                              fontWeight: FontWeight.w300,
                              fontSize: 13),
                        ),
                        CupertinoSwitch(
                            value: _isChecked,
                            inactiveTrackColor: Colors.white60,
                            activeTrackColor: const Color(0xff3E6F58),
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = value ?? false;
                              });
                            }),
                      ]),
                      const SizedBox(height: 15),
                      TextField(
                        controller: id_controller,
                        style: const TextStyle(
                            fontFamily: 'ELAND',
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                        decoration: InputDecoration(
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 1.5),
                            ),
                            labelText: '아이디',
                            labelStyle: const TextStyle(
                              fontFamily: 'ELAND',
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                id_controller.clear();
                              },
                              icon: const Icon(Icons.close, size: 20),
                              color: PRIMARY_COLOR,
                            )),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: pw_controller,
                        style: const TextStyle(
                            fontFamily: 'ELAND',
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                        decoration: InputDecoration(
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 2),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 1.5),
                          ),
                          labelText: '비밀번호',
                          labelStyle: const TextStyle(
                            fontFamily: 'ELAND',
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              pw_controller.clear();
                            },
                            icon: const Icon(Icons.close, size: 20),
                            color: PRIMARY_COLOR,
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: isButtonEnabled ? Colors.white : Colors.grey, // 활성화 상태에 따라 변경
                            minimumSize: const Size(double.infinity, 40)),
                        onPressed: () async {
                          _logIn();
                        },
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                              color: PRIMARY_COLOR,
                              fontFamily: 'ELAND',
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 30.0), // 하단 여백 추가
                    ],
                  ),
                ],
              ),
            )
        ),
    );
  }
}