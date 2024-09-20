import 'package:forestring_stu/data/constant.dart';
import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final int startTimeA;
  final int startTimeB;
  final int endTimeA;
  final int endTimeB;
  final int month;
  final int date;
  final String content;

  const ScheduleCard({
    required this.startTimeA,
    required this.startTimeB,
    required this.endTimeA,
    required this.endTimeB,
    required this.month,
    required this.date,
    required this.content,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.5,
            color: PRIMARY_COLOR,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Date(month: month, date: date),
                  const SizedBox(width: 16.0),
                  _Time(startTimeA: startTimeA, startTimeB: startTimeB, endTimeA: endTimeA, endTimeB: endTimeB),
                  const SizedBox(width: 15.0),
                  _Content(content: content),
                ],
              ),
            )));
  }
}

class _Date extends StatelessWidget {
  final int month;
  final int date;

  const _Date({
    required this.month,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w500,
      color: PRIMARY_COLOR,
      fontSize: 20.0,
    );

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      Text(
        month.toString(),
        style: textStyle,
      ),
      const Text(
        '/',
        style: textStyle,
      ),
      Text(
        date.toString(),
        style: textStyle,
      )
    ]);
  }
}

class _Time extends StatelessWidget {
  final int startTimeA;
  final int startTimeB;
  final int endTimeA;
  final int endTimeB;

  const _Time({
    required this.startTimeA,
    required this.startTimeB,
    required this.endTimeA,
    required this.endTimeB,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'ELAND',
      fontWeight: FontWeight.w300,
      color: Colors.black,
      fontSize: 13.0,
    );

    return Column(children: [
      Text(
        '$startTimeA:${startTimeB.toString().padLeft(2,'0')}',
        style: textStyle,
      ),
      Text('~ $endTimeA:${endTimeB.toString().padLeft(2,'0')}',
          style: textStyle.copyWith(fontSize: 10.0))
    ]);
  }
}

class _Content extends StatelessWidget {
  final String content;

  const _Content({
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'ELAND',
      fontWeight: FontWeight.w300,
      color: Colors.black,
      fontSize: 18.0,
    );

    return Expanded(
       child:
       Text(
         content,
         style: textStyle,
       ),
    );
  }
}
