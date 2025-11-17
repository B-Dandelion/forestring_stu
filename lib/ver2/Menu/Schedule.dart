import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant_data.dart';


class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? selectedSchedule;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 예약 / 변경 / 취소 탭

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

    // `selectedSchedule`을 처음 한 번만 초기화
    selectedSchedule ??= studentProvider.weeklySchedule.isNotEmpty
        ? studentProvider.weeklySchedule.first
        : {'code': 'all'};

    // 현재 학기 필터링
    DateTime semesterStart = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['startDate'];
    DateTime semesterEnd = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['endDate'].add(const Duration(days: 1));

    // 현재 학기 수업 데이터 필터링
    List<Map<String, dynamic>> lessons = studentProvider.lessons.where((lesson) {
      DateTime lessonDate = lesson['date'];
      return lessonDate.isAfter(semesterStart) && lessonDate.isBefore(semesterEnd);
    }).toList()
      ..sort((a, b) => a['date'].compareTo(b['date'])); // 날짜 기준 오름차순 정렬

    // 선택된 스케줄에 맞게 필터링
    List<Map<String, dynamic>> filteredLessons = lessons.where((lesson) {
      return selectedSchedule!['code'] == 'all' || lesson['code'] == selectedSchedule!['code'];
    }).toList();

    // 수업권 개수 계산 (스케줄 개수 고려)
    int totalLessons = filteredLessons.where((lesson) => lesson['status'] == 'confirmed').length;
    // 선택된 스케줄이 'all'이면 전체 weeklySchedule 개수를 곱하고, 개별 선택이면 4로 고정
    int totalAllowedLessons = selectedSchedule!['code'] == 'all'
        ? 4 * studentProvider.weeklySchedule.length
        : 4;
    int remainingLessons = totalAllowedLessons - totalLessons;

    // 드롭다운에 들어갈 리스트 구성
    List<Map<String, dynamic>> scheduleOptions = [
      {'code': 'all'}, // "모든 수업 보기"를 추가
      ...studentProvider.weeklySchedule,
    ];

    return Scaffold(
      appBar: BaseAppBar(title: "FORESTRING", center: true, appBar: AppBar()),
      drawer: BaseDrawer(name : studentProvider.name!),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수업권 현황 표시
            Card(
              color: remainingLessons > 0 ? const Color(0xff3E6F58) : Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "남은 수업권: $remainingLessons 개",
                      style: style.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: remainingLessons > 0 ? Colors.white : Colors.black ,
                      ),
                    ),
                    Icon(
                      remainingLessons > 0 ? Icons.check_rounded : Icons.check_circle,
                      color: remainingLessons > 0 ? Colors.white : PRIMARY_COLOR,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 수업 스케줄 선택 드롭다운
            DropdownButton<Map<String, dynamic>>(
            value: scheduleOptions.contains(selectedSchedule) ? selectedSchedule : scheduleOptions.first,
              isExpanded: true,
              items: scheduleOptions.map((schedule) {
                return DropdownMenuItem(
                  value: schedule,
                  child: Text(schedule['code'] == 'all' ? "모든 수업 보기" : _getScheduleLabel(schedule), style: style),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSchedule = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            // 보강 수업 카드 (드롭다운 아래, 탭바 위)
            _buildMakeupLessons(lessons, studentProvider),
            // 탭바
            TabBar(
              controller: _tabController,
              labelColor: PRIMARY_COLOR,
              unselectedLabelColor: Colors.grey,
              indicatorColor: PRIMARY_COLOR,
              tabs: const [
                Tab(text: "예약된 수업"),
                Tab(text: "변경된 수업"),
                Tab(text: "취소된 수업"),
              ],
            ),

            const SizedBox(height: 12),

            // 탭별 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLessonList(filteredLessons, "confirmed", studentProvider), // 예약된 수업
                  _buildLessonList(filteredLessons, "rescheduled", studentProvider), // 변경된 수업
                  _buildLessonList(filteredLessons, "canceled", studentProvider), // 취소된 수업
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // **탭에 맞는 리스트 빌드 함수**
  Widget _buildLessonList(List<Map<String, dynamic>> lessons, String status, StudentProvider studentProvider) {
    List<Map<String, dynamic>> filteredLessons = [];
    if( status =='rescheduled') {
      filteredLessons = lessons.where((lesson) =>
      lesson['isRescheduled'] == true && lesson['status'] != 'canceled'
      ).toList();
    } else {
      filteredLessons = lessons.where((lesson) => lesson['status'] == status).toList();
    }

    return filteredLessons.isEmpty
        ? Center(
      child: Text(
        "수업이 없습니다.",
        style: style.copyWith(fontSize: 16, color: Colors.grey),
      ),
    )
        : ListView.builder(
      itemCount: filteredLessons.length,
      itemBuilder: (context, index) {
        var lesson = filteredLessons[index];

        // 취소된 수업이면 `CanceledLessonCard` 사용
        if (status == 'canceled') {
          String canceledBy;

          if (lesson['canceledBy'] == studentProvider.studentId) {
            canceledBy = studentProvider.name!; // 본인 이름 표시
          } else if (lesson['canceledBy'] == 'master') {
            canceledBy = "관리자"; // 'master'는 관리자 표시
          } else {
            canceledBy = "알 수 없음"; // 그 외 경우
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: CanceledLessonCard(
              startTime: lesson['date'],
              endTime: lesson['date'].add(Duration(minutes: lesson['duration'])),
              student: studentProvider.name!,
              teacher: studentProvider.teacherName!,
              canceledBy: canceledBy, // 취소자 정보 추가
              code: lesson['code'],
              color: lesson['code'] == '-1' ? const Color(0xff26734D) : PRIMARY_COLOR,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: LessonCard(
            startTime: lesson['date'],
            endTime: lesson['date'].add(Duration(minutes: lesson['duration'])),
            month: lesson['date'].month,
            date: lesson['date'].day,
            student: studentProvider.name!,
            teacher: studentProvider.teacherName!,
            onEdit: () async {
              if (lesson['status'] == "canceled") {
                await showWarningDialog(context, "이미 취소된 수업입니다.");
                return;
              }

              if (lesson['code'] == '-1') {
                await showWarningDialog(context, "보강 수업은 취소할 수 없습니다. 관리자에게 문의해주세요.");
                return;
              }

              bool canCancel = await _canCancelLesson(lesson, studentProvider.teacherId!, studentProvider.studentId!);
              if (canCancel) {
                await _showCancelDialog(context, lesson['id']);
              }
            },
            color: lesson['code'] == '-1' ? Color(0xff26734D) : PRIMARY_COLOR, // 보강 수업 배경 적용
          ),
        );
      },
    );
  }
  Widget _buildMakeupLessons(List<Map<String, dynamic>> lessons, StudentProvider studentProvider) {
    List<Map<String, dynamic>> makeupLessons = lessons.where((lesson) =>
    lesson['code'] == '-1' && lesson['status'] != 'canceled'
    ).toList();

    if (makeupLessons.isEmpty) return const SizedBox.shrink(); // 보강 수업이 없으면 아무것도 표시 안 함

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "보강 수업",
          style: style.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: PRIMARY_COLOR),
        ),
        const SizedBox(height: 6.0),
        ...makeupLessons.map((lesson) => MakeupLessonCard(
          startTime: lesson['date'],
          endTime: lesson['date'].add(Duration(minutes: lesson['duration'])),
          student: studentProvider.name!,
          teacher: studentProvider.teacherName!,
          onEdit: () async {
            bool canCancel = await _canCancelLesson(lesson, studentProvider.teacherId!, studentProvider.studentId!);
            if (canCancel) {
              await _showCancelDialog(context, lesson['id']);
            }
          },
          backgroundColor: const Color(0xff26734D), // 보강 수업용 색상
          borderColor: PRIMARY_COLOR,
          textColor: Colors.white,

        )),
        const SizedBox(height: 12.0),
      ],
    );
  }

  // 수업 취소 가능한지 점검하는 함수
  Future<bool> _canCancelLesson(Map<String, dynamic> lesson, String teacherId, String studentId) async {
    final String? reason = await canCancelLesson(lesson, teacherId, studentId);

    if (reason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason,
            style: style.copyWith(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red.shade200,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  // 취소 조건을 확인하는 함수
  Future<String?> canCancelLesson(Map<String, dynamic> lesson, String teacherId, String studentId) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    try {
      // 1. Firebase 서버 시간 가져오기
      DateTime serverTime = await getServerTime();

      // 2. 현재 학기 시작/종료 날짜 가져오기
      DateTime semesterStart = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['startDate'];
      DateTime semesterEnd = SemesterTerm['${nowsemester.year}-${nowsemester.month.toString().padLeft(2, '0')}']!['endDate'];

      // 3. 해당 수업 정보 가져오기
      DateTime lessonStartTime = lesson['date'];

      // 1번 조건: 미래 학기 수업은 취소 불가
      if (lessonStartTime.isAfter(semesterEnd)) {
        return "미래 학기 수업은 취소할 수 없습니다.";
      }

      // 2번 조건: 수업 시작 5시간 이내면 취소 불가
      if (lessonStartTime.isBefore(serverTime.add(const Duration(hours: 5)))) {
        return "수업 시작 5시간 전까지만 취소할 수 있습니다.";
      }

      // 3번 조건: 한 학기 취소 횟수 2번 초과 시 취소 불가
      int maxCancellable = studentProvider.weeklySchedule.length * 2;
      int canceledLessonCount = studentProvider.lessons.where((lesson) =>
      lesson['status'] == 'canceled' &&
          lesson['canceledBy'] == studentProvider.studentId &&
          lesson['date'].isAfter(semesterStart) &&
          lesson['date'].isBefore(semesterEnd)
      ).length;

      if (canceledLessonCount >= maxCancellable) {
        print(maxCancellable);
        return "취소 가능 횟수를 초과하였습니다.";
      }

      return null;
    } catch (e) {
      print("canCancelLesson 오류: $e");
      return '취소 처리 중 오류가 발생했습니다.';
    }
  }

  // 서버 시간을 가져오는 함수
  Future<DateTime> _getServerTime() async {
    DocumentReference timeRef = FirebaseFirestore.instance.collection('serverTime').doc('now');

    // 서버 타임스탬프 생성 (업데이트)
    await timeRef.set({"timestamp": FieldValue.serverTimestamp()});

    // Firestore에서 현재 서버 시간 가져오기
    DocumentSnapshot timeSnapshot = await timeRef.get();
    Timestamp serverTimestamp = timeSnapshot["timestamp"];
    return serverTimestamp.toDate(); // DateTime 형태로 변환
  }

  // 취소 다이얼로그
  Future<void> _showCancelDialog(BuildContext context, String lessonId) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("수업 취소", style: style),
        content: Text("정말로 이 수업을 취소하시겠습니까?", style: style),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("취소", style: style.copyWith(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await cancelLesson(lessonId, studentProvider.teacherId!, studentProvider.studentId!);
            },
            child: Text("확인", style: style.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("수업이 취소되었습니다!", style: style.copyWith(color: Colors.black)),
          backgroundColor: IBORY,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  // 수업 삭제 함수
  Future<void> cancelLesson(String lessonId, String teacherId, String studentId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference lessonsRef = firestore.collection('lessons');
    final DocumentReference teacherSlotRef = firestore.collection('availableSlots').doc(teacherId);
    final CollectionReference studentLessonsCollection =
    firestore.collection('users').doc(studentId).collection('lessons');

    WriteBatch batch = firestore.batch();
    FieldValue serverTimestamp = FieldValue.serverTimestamp();

    try {

      // 1 lesson 컬렉션에서 해당 레슨 문서 상태 변경 (canceled)
      final lessonDocRef = lessonsRef.doc(lessonId);
      batch.update(lessonDocRef, {
        'status': 'canceled',
        'canceledBy': studentId,     // 누가 취소했는지 기록
        'updatedAt': serverTimestamp,
      });

      // 2 선생님 availableSlots - bookedSlots 맵 필드에서 해당 수업 삭제
      batch.update(teacherSlotRef, {
        'bookedSlots.$lessonId': FieldValue.delete(), // bookedSlots 맵에서 해당 레슨 ID 삭제
      });

      // 3 학생 레슨 컬렉션에서 해당 수업 상태 변경 (canceled)
      final studentLessonDocRef = studentLessonsCollection.doc(lessonId);
      batch.update(studentLessonDocRef, {
        'status': 'canceled',
        'canceledBy': studentId,     // 누가 취소했는지 기록
        'updatedAt': serverTimestamp,
      });

      // 변경 사항 적용
      await batch.commit();
      print("수업 취소 완료: lessonId: $lessonId");
    } catch (e) {
      print("수업 취소 실패: $e");
      throw Exception("수업 취소 중 오류 발생");
    }
  }

  // 보강 / 이미 취소된 수업은 취소할 수 없음 알림
  Future<void> showWarningDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("알림", style: style.copyWith(fontWeight: FontWeight.w500)),
        content: Text(
          message,
          style: style.copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 닫기 버튼
            child: Text("확인", style: style.copyWith(color: PRIMARY_COLOR)),
          ),
        ],
      ),
    );
  }

  // 주어진 lesson 데이터를 스케줄 라벨 형식으로 변환
  String _getScheduleLabel(Map<String, dynamic> lesson) {
    Map<String, String> dayMap = {
      'MO': '월',
      'TU': '화',
      'WE': '수',
      'TH': '목',
      'FR': '금',
      'SA': '토',
      'SU': '일',
    };
    String day = dayMap[lesson['day']] ?? '알 수 없음'; // "월", "화" ...
    String time = lesson['startTime'];
    return "$day요일 $time 수업";
  }

}
