import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:forestring_student_1/firebase_options.dart';
import 'package:forestring_student_1/ver2/Intro.dart';
import 'package:forestring_student_1/ver2/constant_data.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 로컬 알림 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // // 로컬 알림 설정
  // const AndroidInitializationSettings initializationSettingsAndroid =
  // AndroidInitializationSettings('@mipmap/ic_launcher');
  //
  // const InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  // );
  //
  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: (NotificationResponse response) {
  //     if (response.payload != null) {
  //       // 알림 클릭 시 처리
  //       navigatorKey.currentState?.pushNamed('/home'); // 예: 홈 화면으로 이동
  //     }
  //   },
  // );

  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => StudentProvider())
    ],
      child: const Forestring(),
    )
  );

  // // foreground 메시지 처리 (로컬 알림 표시)
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   RemoteNotification? notification = message.notification;
  //   AndroidNotification? android = message.notification?.android;
  //
  //   if (notification != null && android != null) {
  //     flutterLocalNotificationsPlugin.show(
  //       notification.hashCode,
  //       notification.title,
  //       notification.body,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           'default_channel',
  //           '기본 알림',
  //           channelDescription: '포그라운드 알림 채널',
  //           importance: Importance.max,
  //           priority: Priority.high,
  //         ),
  //       ),
  //     );
  //   }
  // });
  //
  // // 알림 클릭 (앱 백그라운드에서 켜졌을 때)
  // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //   navigatorKey.currentState?.pushNamed('/home'); // 혹은 message.data에 따라 다른 페이지로 이동
  // });

}

class Forestring extends StatelessWidget {
  const Forestring({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Forestring_student',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: PRIMARY_COLOR),
            useMaterial3: true,
          ),
          home: const Intro())
    );
  }
}