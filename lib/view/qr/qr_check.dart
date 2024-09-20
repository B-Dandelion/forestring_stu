import 'package:flutter/material.dart';
import 'package:forestring_stu/data/constant.dart';

class QRCheckScreen extends StatefulWidget {
  const QRCheckScreen({super.key});

  @override
  State<QRCheckScreen> createState() => _QRCheckScreen();
}

class _QRCheckScreen extends State<QRCheckScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
        drawer: const BaseDrawer(),
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Not Yet !!',
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'ELAND',
                fontWeight: FontWeight.w300,
                fontSize: 30
            ),
            ),
          ],
        ));
  }
}