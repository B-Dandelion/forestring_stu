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

            if (snapshot.hasError || snapshot.data == null) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Text(
                      snapshot.error?.toString() ?? '수강 내역을 불러오지 못했습니다.',
                      textAlign: TextAlign.center,
                      style: forestringTextStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            }

            final history = snapshot.data!;
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _pill(
                      history.studentTypeLabel,
                      background: primaryColor.withValues(alpha: 0.10),
                      foreground: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '이번 학기',
                    style: forestringTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (current == null)
                    _emptyCard('이번 학기 수강 내역이 없습니다.')
                  else ...[
                    _semesterSummary(history, current),
                    const SizedBox(height: 16),
                    Text(
                      '수업 내역',
                      style: forestringTextStyle.copyWith(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._lessonTimeline(history, current),
                  ],
                  const SizedBox(height: 28),
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
                    ...past.map(
                      (semester) => _pastSemesterTile(history, semester),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _semesterSummary(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final baseRights = semester.rights.where(
      (right) => history.isRegular
          ? right.origin == 'regular_base'
          : right.origin == 'flex_base',
    );
    final carryoverCount = semester.rights
        .where((right) => right.origin == 'carryover')
        .length;

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
            children: history.isRegular
                ? [
                    _summaryChip('기본 생성 수업 ${baseRights.length}개'),
                    _summaryChip('예약 ${semester.reservedRights}개'),
                    if (semester.availableRights > 0)
                      _summaryChip('재예약 가능 ${semester.availableRights}개'),
                    if (carryoverCount > 0)
                      _summaryChip('이월 수강권 $carryoverCount개'),
                  ]
                : [
                    _summaryChip('기본 수강권 ${baseRights.length}개'),
                    _summaryChip('남은 수강권 ${semester.availableRights}개'),
                    _summaryChip(
                      '예약/사용 ${semester.reservedRights + semester.consumedRights}개',
                    ),
                    if (carryoverCount > 0)
                      _summaryChip('이월 수강권 $carryoverCount개'),
                  ],
          ),
        ],
      ),
    );
  }

  List<Widget> _lessonTimeline(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final rights = [...semester.rights];
    rights.sort((a, b) {
      final aDate = a.originalStartsAt ?? a.currentStartsAt;
      final bDate = b.originalStartsAt ?? b.currentStartsAt;
      if (aDate == null && bDate == null) {
        return a.sequenceNo.compareTo(b.sequenceNo);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    final originalCards = <Widget>[];
    final rebookCards = <Widget>[];

    for (final right in rights) {
      if (history.isRegular && right.origin != 'regular_base') {
        continue;
      }
      if (history.isFlex &&
          right.origin != 'flex_base' &&
          right.origin != 'carryover') {
        continue;
      }

      if (right.lesson != null) {
        originalCards.add(
          _originalLessonCard(
            history: history,
            right: right,
            title: history.isRegular ? '정규 수업' : '예약 수업',
          ),
        );
      }

      if (right.isRebooked) {
        rebookCards.add(
          _rebookedLessonCard(
            history: history,
            right: right,
          ),
        );
      }
    }

    if (originalCards.isEmpty && rebookCards.isEmpty) {
      return [_emptyCard('아직 등록된 수업 내역이 없습니다.')];
    }

    return [
      ...originalCards,
      if (rebookCards.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          '재예약 내역',
          style: forestringTextStyle.copyWith(
            color: secondaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...rebookCards,
      ],
    ];
  }

  Widget _originalLessonCard({
    required LessonHistoryData history,
    required LessonRightHistory right,
    required String title,
  }) {
    final lesson = right.lesson!;
    final original = right.originalStartsAt ?? lesson.startsAt;
    final originalEnd = original.add(
      Duration(minutes: right.durationMinutes),
    );
    final cancellation = right.latestCancellation;
    final canceled = right.wasCanceled;
    final staffChanged = !canceled && lesson.isAcademyChanged;
    final displayStart = staffChanged ? lesson.startsAt : original;
    final displayEnd = staffChanged ? lesson.endsAt : originalEnd;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: canceled ? Colors.black.withValues(alpha: 0.035) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canceled
              ? Colors.black12
              : primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: forestringTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: canceled ? Colors.black45 : Colors.black87,
                  ),
                ),
              ),
              if (canceled)
                _pill(
                  '취소됨',
                  background: Colors.black12,
                  foreground: Colors.black54,
                )
              else if (staffChanged)
                _pill(
                  '변경',
                  background: secondaryColor.withValues(alpha: 0.12),
                  foreground: secondaryColor,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${DateFormat('M월 d일 HH:mm').format(displayStart)} ~ '
            '${DateFormat('HH:mm').format(displayEnd)}',
            style: forestringTextStyle.copyWith(
              fontSize: 14,
              color: canceled ? Colors.black45 : Colors.black87,
              decoration: canceled ? TextDecoration.lineThrough : null,
            ),
          ),
          if (lesson.teacherName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${lesson.teacherName} 선생님',
              style: forestringTextStyle.copyWith(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
          if (cancellation != null) ...[
            const SizedBox(height: 9),
            Text(
              '${cancellation.actorLabel(history.studentId)} · '
              '${DateFormat('M월 d일 HH:mm').format(cancellation.canceledAt)} 취소',
              style: forestringTextStyle.copyWith(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ] else if (staffChanged && lesson.updatedAt != null) ...[
            const SizedBox(height: 9),
            Text(
              '학원 관리자 · '
              '${DateFormat('M월 d일 HH:mm').format(lesson.updatedAt!)} 변경',
              style: forestringTextStyle.copyWith(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rebookedLessonCard({
    required LessonHistoryData history,
    required LessonRightHistory right,
  }) {
    final lesson = right.lesson!;
    final reservedAt = right.reservedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: secondaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '재예약 수업',
                  style: forestringTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _pill(
                '재예약',
                background: secondaryColor.withValues(alpha: 0.14),
                foreground: secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${DateFormat('M월 d일 HH:mm').format(lesson.startsAt)} ~ '
            '${DateFormat('HH:mm').format(lesson.endsAt)}',
            style: forestringTextStyle.copyWith(fontSize: 14),
          ),
          if (lesson.teacherName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${lesson.teacherName} 선생님',
              style: forestringTextStyle.copyWith(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
          if (reservedAt != null) ...[
            const SizedBox(height: 9),
            Text(
              '${right.bookingActorLabel(history.studentId)} · '
              '${DateFormat('M월 d일 HH:mm').format(reservedAt)} 재예약',
              style: forestringTextStyle.copyWith(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pastSemesterTile(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
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
          history.isRegular
              ? '기본 수업 ${semester.rights.where((r) => r.origin == 'regular_base').length}개'
              : '수강권 ${semester.totalRights}개 · 남은 ${semester.availableRights}개',
          style: forestringTextStyle.copyWith(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _semesterSummary(history, semester),
          const SizedBox(height: 10),
          ..._lessonTimeline(history, semester),
        ],
      ),
    );
  }

  Widget _summaryChip(String text) {
    return _pill(
      text,
      background: Colors.white,
      foreground: Colors.black87,
      borderColor: primaryColor.withValues(alpha: 0.18),
    );
  }

  Widget _pill(
    String text, {
    required Color background,
    required Color foreground,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: forestringTextStyle.copyWith(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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
