import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // 요일별 예약 가능 시간 (시작 시간과 끝나는 시간)
  Map<String, List<DateTime>> availableSlots = {
    'Mon': [DateTime(2024, 11, 4, 10, 0), DateTime(2024, 11, 4, 18, 0)],
    'Tue': [DateTime(2024, 11, 5, 10, 0), DateTime(2024, 11, 5, 18, 0)],
    // 다른 요일들 추가
  };

  // 예약된 시간 리스트 (각 DateTime은 예약된 특정 시간)
  List<DateTime> bookedSlots = [
    DateTime(2024, 11, 11, 11, 30),
    DateTime(2024, 11, 12, 12, 0),
    // 예약된 시간들 추가
  ];

  DateTime selectedDate = DateTime.now();

  // 30분 간격으로 시간 슬롯 생성 함수
  List<DateTime> generateTimeSlots(DateTime start, DateTime end) {
    List<DateTime> slots = [];
    DateTime current = start;

    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: 30));
    }

    return slots;
  }

  // 선택한 날짜의 예약 가능한 시간 슬롯 생성
  List<DateTime> getAvailableTimes() {
    String dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][selectedDate.weekday % 7];
    List<DateTime> slots = [];

    if (availableSlots.containsKey(dayOfWeek)) {
      DateTime start = availableSlots[dayOfWeek]![0];
      DateTime end = availableSlots[dayOfWeek]![1];

      // 선택된 날짜와 동일한 날짜의 예약된 시간을 필터링하여 제외
      slots = generateTimeSlots(start, end).where((time) {
        // 같은 날짜의 예약된 시간을 제외
        return !bookedSlots.any((bookedTime) =>
        bookedTime.year == selectedDate.year &&
            bookedTime.month == selectedDate.month &&
            bookedTime.day == selectedDate.day &&
            bookedTime.hour == time.hour &&
            bookedTime.minute == time.minute);
      }).toList();
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('예약 화면')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            onDaySelected: (selectedDay, _) {
              setState(() {
                selectedDate = selectedDay;
              });
            },
          ),
          SizedBox(height: 16),
          Text('예약 가능한 시간', style: TextStyle(fontSize: 18)),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
              ),
              itemCount: getAvailableTimes().length,
              itemBuilder: (context, index) {
                DateTime time = getAvailableTimes()[index];
                return Column(
                  mainAxisSize: MainAxisSize.min, // 버튼이 부모 위젯 크기에 맞게 확장되지 않도록 설정
                  children: [
                    SizedBox(
                      width: 95, // 버튼 너비
                      height: 45, // 버튼 높이
                      child: ElevatedButton(
                        onPressed: () {
                          // 예약 기능 추가
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // 버튼 배경색 (흰색)
                          foregroundColor: Colors.black, // 텍스트 색상 (검정색)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0), // 모서리를 둥글게
                            side: BorderSide(color: Colors.grey.shade300, width: 1), // 테두리 색상 및 두께 조정
                          ),
                          elevation: 0, // 그림자 제거
                          padding: EdgeInsets.zero, // padding을 제거해 버튼 크기와 맞춤
                        ),
                        child: Text(
                          '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}