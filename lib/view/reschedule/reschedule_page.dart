import 'package:flutter/material.dart';
import 'package:forestring_stu/data/constant.dart';
import 'package:forestring_stu/data/schedule_card.dart';

class ReschedulePage extends StatefulWidget {
  const ReschedulePage({super.key});

  @override
  State<ReschedulePage> createState() => _ReschedulePage();
}

class _ReschedulePage extends State<ReschedulePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
        drawer: const BaseDrawer(),
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScheduleCard(
                startTime: 12,
                endTime: 13,
                month: 9,
                date: 26,
                teacher: '김진아 선생님 / 왕십리'),
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