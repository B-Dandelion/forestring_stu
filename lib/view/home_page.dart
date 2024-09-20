import 'package:flutter/material.dart';
import 'package:forestring_stu/data/constant.dart';
import 'package:forestring_stu/data/schedule_card.dart';
import 'package:forestring_stu/data/today_banner.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class Home_page extends StatefulWidget {
  const Home_page({super.key});

  @override
  State<Home_page> createState() => _Home_page();
}

class _Home_page extends State<Home_page>{
  DateTime selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
      drawer: const BaseDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            MainCalendar(
              selectedDate: selectedDate,
              onDaySelected: (selectedDate, focusedDate) => onDaySelected(selectedDate, focusedDate, context),
            ),
            const SizedBox(height: 8),
            TodayBanner(selectedDate: selectedDate),
            const SizedBox(height: 8),
            Expanded(
              // steambuilder로 구현하기
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection(
                    'schedule',
                  ).where('date',
                  isEqualTo: '${selectedDate.year}${selectedDate.month}${selectedDate.day}').snapshots(),
                  builder: (context, snapshot) {

                    // 일정 정보 오류 있을 경우 출력되는 메세지
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('일정 정보를 가져오지 못했습니다.' '관리자에게 문의 바랍니다.',
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'ELAND',
                            fontWeight: FontWeight.w300,
                            fontSize: 30),
                        ),
                      );
                    }

                    // 로딩 중일 때 보여줄 화면
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }

                    // 스케줄 데이터로 데이터 매핑하기
                    final schedules = snapshot.data!.docs.map(
                        (QueryDocumentSnapshot e) => ScheduleModel.fromJson(
                          json: (e.data() as Map<String, dynamic>)),
                    ).toList();

                    return ListView.builder(
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];

                          return Dismissible(
                              key: ObjectKey(schedule.id),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (DismissDirection direction) {},
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,),
                                child: ScheduleCard(
                                    startTimeA: schedule.startTimeA,
                                    startTimeB: schedule.startTimeB,
                                    endTimeA: schedule.endTimeA,
                                    endTimeB: schedule.endTimeB,
                                    month: schedule.month,
                                    date: schedule.date,
                                    content: schedule.content),
                              )
                          );
                        }
                    );
                  },
                )
            )
          ],
        ),
      ),
    );
  }
  void onDaySelected(
      DateTime selectedDate,
      DateTime focusedDate,
      BuildContext context,
      ) {
    setState(() {
      this.selectedDate = selectedDate;
    });
  }
}
 // 메인 페이지 앱 바 구현
