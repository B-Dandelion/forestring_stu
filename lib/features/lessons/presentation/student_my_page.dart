import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
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
  late Future<LessonHistoryData> _historyFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _historyFuture = context.read<LessonController>().fetchLessonHistory();
  }

  Future<void> _reload() async {
    setState(() {
      _historyFuture = context.read<LessonController>().fetchLessonHistory();
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
                      primaryColor.withValues(alpha: 0.10),
                      primaryColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('이번 학기'),
                  const SizedBox(height: 10),
                  if (current == null)
                    _emptyCard('이번 학기 수강 내역이 없습니다.')
                  else ...[
                    _semesterSummary(history, current),
                    const SizedBox(height: 16),
                    _sectionTitle('수업 내역', small: true),
                    const SizedBox(height: 8),
                    ..._timeline(history, current),
                  ],
                  const SizedBox(height: 28),
                  _sectionTitle('지난 학기'),
                  const SizedBox(height: 10),
                  if (past.isEmpty)
                    _emptyCard('지난 학기 수강 내역이 없습니다.')
                  else
                    ...past.map(
                      (semester) => _pastTile(history, semester),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, {bool small = false}) {
    return Text(
      text,
      style: forestringTextStyle.copyWith(
        color: small ? primaryColor : Colors.black87,
        fontSize: small ? 16 : 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _semesterSummary(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final baseRights = semester.rights
        .where(
          (right) => history.isRegular
              ? right.origin == 'regular_base'
              : right.origin == 'flex_base',
        )
        .toList();
    final baseCount = baseRights.length;
    final carryoverCount = semester.rights
        .where((right) => right.origin == 'carryover')
        .length;
    final countedStudentCancellations = baseRights.fold<int>(
      0,
      (sum, right) =>
          sum +
          right.cancellations
              .where(
                (event) =>
                    event.origin == 'student' && event.countsTowardLimit,
              )
              .length,
    );
    final cancellationLimit = history.isRegular
        ? (baseCount ~/ 4) * 2
        : baseCount ~/ 4;
    final remainingCancellations =
        cancellationLimit > countedStudentCancellations
            ? cancellationLimit - countedStudentCancellations
            : 0;
    final rebookableCount = baseRights
        .where(
          (right) => right.status == 'available' && right.wasCanceled,
        )
        .length;
    final flexAvailableCount = baseRights
        .where(
          (right) => right.status == 'available' && !right.wasCanceled,
        )
        .length;

    final chips = history.isRegular
        ? <String>[
            '예약된 수업 ${semester.reservedRights}개',
            '취소 가능 $remainingCancellations회',
            '보강 수업권 ${carryoverCount == 0 ? '없음' : '$carryoverCount개'}',
            if (rebookableCount > 0)
              '재예약 가능 수업권 $rebookableCount개',
          ]
        : <String>[
            '기본 수업권 $baseCount개',
            '예약 가능 수업권 $flexAvailableCount개',
            '예약된 수업 ${semester.reservedRights}개',
            '취소 가능 $remainingCancellations회',
            '보강 수업권 ${carryoverCount == 0 ? '없음' : '$carryoverCount개'}',
            if (rebookableCount > 0)
              '재예약 가능 수업권 $rebookableCount개',
          ];

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
            children: chips
                .map(
                  (text) => _pill(
                    text,
                    Colors.white,
                    Colors.black87,
                    borderColor: primaryColor.withValues(alpha: 0.18),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _timeline(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final rights = semester.rights.where((right) {
      if (history.isRegular) {
        return right.origin == 'regular_base';
      }
      return right.origin == 'flex_base' || right.origin == 'carryover';
    }).toList();

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
      if (right.lesson != null) {
        originalCards.add(
          _originalCard(
            history,
            right,
            history.isRegular ? '정규 수업' : '예약 수업',
          ),
        );
      }
      if (right.isRebooked) {
        rebookCards.add(_rebookCard(history, right));
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

  Widget _originalCard(
    LessonHistoryData history,
    LessonRightHistory right,
    String title,
  ) {
    final lesson = right.lesson!;
    final originalStart = right.originalStartsAt ?? lesson.startsAt;
    final originalEnd = originalStart.add(
      Duration(minutes: right.durationMinutes),
    );
    final cancellation = right.latestCancellation;
    final canceled = right.wasCanceled;
    final staffChanged = !canceled && lesson.isAcademyChanged;
    final displayStart = staffChanged ? lesson.startsAt : originalStart;
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
                    color: canceled ? Colors.black45 : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (canceled)
                _pill('취소됨', Colors.black12, Colors.black54)
              else if (staffChanged)
                _pill(
                  '변경',
                  secondaryColor.withValues(alpha: 0.12),
                  secondaryColor,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${DateFormat('M월 d일 HH:mm').format(displayStart)} ~ '
            '${DateFormat('HH:mm').format(displayEnd)}',
            style: forestringTextStyle.copyWith(
              color: canceled ? Colors.black45 : Colors.black87,
              fontSize: 14,
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

  Widget _rebookCard(
    LessonHistoryData history,
    LessonRightHistory right,
  ) {
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
                secondaryColor.withValues(alpha: 0.14),
                secondaryColor,
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

  Widget _pastTile(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final regularCount = semester.rights
        .where((right) => right.origin == 'regular_base')
        .length;

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
              ? '기본 수업 $regularCount개'
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
          ..._timeline(history, semester),
        ],
      ),
    );
  }

  Widget _pill(
    String text,
    Color background,
    Color foreground, {
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
