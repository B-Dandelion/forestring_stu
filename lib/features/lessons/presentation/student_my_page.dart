import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_history.dart';
import 'lesson_controller.dart';
import 'reschedule_page.dart';

class StudentMyPage extends StatefulWidget {
  const StudentMyPage({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  State<StudentMyPage> createState() => _StudentMyPageState();
}

class _StudentMyPageState extends State<StudentMyPage> {
  final LessonRepository _repository = LessonRepository();
  late Future<LessonHistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _repository.fetchMyLessonHistory();
  }

  Future<void> _reload() async {
    setState(() {
      _historyFuture = _repository.fetchMyLessonHistory();
    });
    await _historyFuture;
  }

  void _goHome() {
    Navigator.of(context).pop();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goReschedule() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<LessonController>(),
          child: ReschedulePage(profile: widget.profile),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StudentAppBar(title: '마이페이지'),
      drawer: StudentDrawer(
        displayName: widget.profile.displayName,
        onHome: _goHome,
        onReschedule: _goReschedule,
        onMyPage: () => Navigator.of(context).pop(),
        onLogout: () async {
          Navigator.of(context).pop();
          await context.read<AuthController>().signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
      body: SafeArea(
        child: FutureBuilder<LessonHistoryData>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: forestringTextStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            }

            final history = snapshot.data ??
                const LessonHistoryData(semesters: []);
            final current = history.currentSemester;
            final past = history.pastSemesters;

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  Text(
                    '${widget.profile.displayName}님의 수강 내역',
                    style: forestringTextStyle.copyWith(
                      color: primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '이번 학기',
                    style: forestringTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (current == null)
                    _emptyCard('이번 학기 수강권 내역이 없습니다.')
                  else ...[
                    _semesterSummary(current),
                    const SizedBox(height: 10),
                    ...current.rights.map(_rightCard),
                  ],
                  const SizedBox(height: 26),
                  Text(
                    '지난 학기',
                    style: forestringTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (past.isEmpty)
                    _emptyCard('지난 학기 수강 내역이 없습니다.')
                  else
                    ...past.map(_pastSemesterTile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _semesterSummary(SemesterLessonHistory semester) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ivoryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _semesterTitle(semester.code),
            style: forestringTextStyle.copyWith(
              color: primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('M월 d일').format(semester.startsOn)} ~ '
            '${DateFormat('M월 d일').format(semester.endsOn)}',
            style: forestringTextStyle.copyWith(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip('수강권 ${semester.totalRights}개'),
              _summaryChip('예약 ${semester.reservedRights}개'),
              if (semester.availableRights > 0)
                _summaryChip('재예약 대기 ${semester.availableRights}개'),
              if (semester.studentCancellationCount > 0)
                _summaryChip('학생 취소 ${semester.studentCancellationCount}회'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: forestringTextStyle.copyWith(fontSize: 12),
      ),
    );
  }

  Widget _rightCard(LessonRightHistory right) {
    final original = right.originalStartsAt;
    final current = right.currentStartsAt;
    final currentEnd = right.currentEndsAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    right.sequenceNo > 0
                        ? '${right.sequenceNo}회차 · ${right.durationMinutes}분'
                        : '${right.originLabel} · ${right.durationMinutes}분',
                    style: forestringTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _statusBadge(right),
              ],
            ),
            const SizedBox(height: 10),
            if (original != null)
              _historyRow(
                title: right.origin == 'regular_base' ? '기본 수업' : '예약 수업',
                value: DateFormat('M월 d일 HH:mm').format(original),
                trailing: right.wasCanceled ? '취소' : null,
                canceled: right.wasCanceled,
              ),
            if (right.wasCanceled) ...[
              const SizedBox(height: 7),
              Text(
                [
                  if (right.studentCancellationCount > 0)
                    '학생 취소 ${right.studentCancellationCount}회',
                  if (right.academyCancellationCount > 0)
                    '학원 취소 ${right.academyCancellationCount}회',
                ].join(' · '),
                style: forestringTextStyle.copyWith(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
            if (right.isRebooked && current != null && currentEnd != null) ...[
              const Divider(height: 20),
              _historyRow(
                title: '재예약 수업',
                value: '${DateFormat('M월 d일 HH:mm').format(current)} ~ '
                    '${DateFormat('HH:mm').format(currentEnd)}',
                trailing: '예약',
              ),
            ] else if (right.status == 'available' && right.wasCanceled) ...[
              const Divider(height: 20),
              _historyRow(
                title: '재예약',
                value: '아직 예약하지 않았습니다.',
                trailing: '대기',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historyRow({
    required String title,
    required String value,
    String? trailing,
    bool canceled = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            title,
            style: forestringTextStyle.copyWith(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: forestringTextStyle.copyWith(
              fontSize: 13,
              decoration: canceled ? TextDecoration.lineThrough : null,
              color: canceled ? Colors.black45 : Colors.black87,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: forestringTextStyle.copyWith(
              fontSize: 12,
              color: canceled ? Colors.redAccent : secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(LessonRightHistory right) {
    final isWaiting = right.status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isWaiting
            ? Colors.orange.withValues(alpha: 0.10)
            : secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        right.statusLabel,
        style: forestringTextStyle.copyWith(
          color: isWaiting ? Colors.orange.shade800 : primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _pastSemesterTile(SemesterLessonHistory semester) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.14)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          _semesterTitle(semester.code),
          style: forestringTextStyle.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '수강권 ${semester.totalRights}개 · 학생 취소 ${semester.studentCancellationCount}회',
          style: forestringTextStyle.copyWith(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: semester.rights.map(_rightCard).toList(),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ivoryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: forestringTextStyle.copyWith(color: Colors.black54),
      ),
    );
  }

  String _semesterTitle(String code) {
    final parts = code.split('-');
    if (parts.length == 2) {
      final month = int.tryParse(parts[1]);
      if (month != null) {
        return '${parts[0]}년 $month월 학기';
      }
    }
    return '$code 학기';
  }
}
