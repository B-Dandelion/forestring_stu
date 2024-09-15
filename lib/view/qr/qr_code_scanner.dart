// import 'package:flutter/material.dart';
// import 'package:forestring_stu/view/qr/qr_check.dart';
// import 'package:forestring_stu/data/constant.dart';
// import 'package:forestring_stu/view/home_page.dart';
//
//
// class Qr_code_scanner extends StatefulWidget {
//   Qr_code_scanner({Key? key}) : super(key: key);
//
//   @override
//   State<Qr_code_scanner> createState() => _Qr_code_scanner();
// }
//
// class _Qr_code_scanner extends State<Qr_code_scanner> {
//   String qrResult = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: PRIMARY_COLOR,
//         iconTheme: IconThemeData(color: Colors.white),
//         title: const Text(
//             'QR Check In',
//             style: TextStyle(
//                 color: Colors.white,
//                 fontFamily: 'OpenSans',
//                 fontWeight: FontWeight.w500,
//                 fontSize: 20
//             )
//         ),
//         centerTitle: true,
//         elevation: 0.0, //앱바 밑에 그림자
//       ),
//       drawer: Drawer(
//         child: ListView(
//           children: [
//             const UserAccountsDrawerHeader(
//               currentAccountPicture: CircleAvatar(
//                 backgroundImage: AssetImage('assets/img/ME_Profile.png'),
//               ),
//               accountName: Text(
//                 '진민경 님',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               accountEmail: Text(
//                 'Michelle_mk@naver.com',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontFamily: 'OpenSans',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               decoration: BoxDecoration(
//                   color: PRIMARY_COLOR,
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(10.0),
//                     bottomRight: Radius.circular(10.0),
//                   )
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.account_circle),
//               iconColor: PRIMARY_COLOR,
//               focusColor: IBORY,
//               title: const Text(
//                 '마이페이지',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               onTap: (){},
//               trailing: const Icon(Icons.navigate_next_rounded),
//             ),
//             ListTile(
//               leading: const Icon(Icons.home_filled),
//               iconColor: PRIMARY_COLOR,
//               focusColor: IBORY,
//               title: const Text(
//                 '메인페이지',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               onTap: (){
//                 Navigator.of(context)
//                     .pushReplacement(MaterialPageRoute(builder: (context) {
//                   return const Home_page();
//                 }));
//               },
//               trailing: const Icon(Icons.navigate_next_rounded),
//             ),
//             ListTile(
//               leading: const Icon(Icons.calendar_month_rounded),
//               iconColor: PRIMARY_COLOR,
//               focusColor: IBORY,
//               title: const Text(
//                 '예약 변경하기',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               onTap: (){},
//               trailing: const Icon(Icons.navigate_next_rounded),
//             ),
//             ListTile(
//               leading: const Icon(Icons.qr_code_scanner_rounded),
//               iconColor: PRIMARY_COLOR,
//               focusColor: IBORY,
//               title: const Text(
//                 'QR Check In',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               onTap: (){},
//               trailing: const Icon(Icons.navigate_next_rounded),
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout_rounded),
//               iconColor: PRIMARY_COLOR,
//               focusColor: IBORY,
//               title: const Text(
//                 '로그아웃',
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),
//               onTap: (){},
//               trailing: const Icon(Icons.navigate_next_rounded),
//             )
//           ],
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const Text('여기에 링크가 뜰 예정입니당',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontFamily: 'ELAND',
//                   fontWeight: FontWeight.w300,
//                 )
//             ),
//             Text(
//               qrResult,
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontFamily: 'ELAND',
//                 fontWeight: FontWeight.w300,
//               )
//             )
//           ],
//         ),
//       ),
//         floatingActionButton: FloatingActionButton(
//             onPressed: _onPressedFAB,
//             tooltip: 'In',
//             child: const Icon(Icons.camera_alt_outlined)
//         ),
//     );
//   }
//   void _onPressedFAB() async { //비동기 실행으로 QR화면이 닫히기 전까지 await으로 기다리도록 한다.
//     dynamic result = await Navigator.push(context, MaterialPageRoute(builder: (context) {
//       return QRCheckScreen(eventKeyword: 'userId');
//     }));
//
//     if(result != null) {
//       setState(() {
//         //qr스캐너에서 받은 결과값을 화면의 qrResult 에 적용하도록 한다.
//         qrResult = result.toString();
//       });
//     }
//   }
// }