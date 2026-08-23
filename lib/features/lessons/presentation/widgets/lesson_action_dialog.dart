import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/forestring_theme.dart';
import '../../domain/lesson.dart';
import '../lesson_controller.dart';

Future<void> showStudentLessonDialog({
  required BuildContext context,
  required Lesson lesson,
  required LessonController controller,
}) async {
  final hostContext = context;

  await showDialog<void>(
    context: hostContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          '수업 정보',
          style: forestringTextStyle.copyWith(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lesson.teacherName ?? '담당 선생님'} 선생님',
              style: forestringTextStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy년 M월 d일').format(lesson.startsAt),
              style: forestringTextStyle,
            ),
            Text(
              '${DateFormat('HH:mm').format(lesson.startsAt)} '
              '~ ${DateFormat('HH:mm').format(lesson.endsAt)}',
              style: forestringTextStyle,
            ),
            const SizedBox(height: 6),
            Text(
              lesson.displayTypeLabel,
              style: forestringTextStyle.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      title: const Text('수업 취소'),
                      content: const Text(
                        '이 수업을 취소하시겠습니까?\n취소 가능 횟수와 수강권 정책은 자동으로 적용됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(confirmContext, false),
                          child: const Text('아니요'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(confirmContext, true),
                          child: const Text(
                            '취소하기',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (!confirmed || !dialogContext.mounted) {
                return;
              }

              final ok = await controller.cancelLesson(lesson);
              if (!dialogContext.mounted) {
                return;
              }

              if (ok) {
                Navigator.of(dialogContext).pop();
                if (hostContext.mounted) {
                  _showMessage(hostContext, '수업이 취소되었습니다.');
                }
              } else if (hostContext.mounted) {
                _showMessage(
                  hostContext,
                  controller.errorMessage ?? '수업을 취소하지 못했습니다.',
                );
              }
            },
            child: const Text(
              '수업 취소',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      );
    },
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
