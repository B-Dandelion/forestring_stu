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
          lesson.isCanceled ? '취소된 수업' : '수업 정보',
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
              lesson.type.label,
              style: forestringTextStyle.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (!lesson.isCanceled)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                      context: dialogContext,
                      builder: (confirmContext) => AlertDialog(
                        title: const Text('수업 취소'),
                        content: const Text(
                          '이 수업을 취소하시겠습니까?\n취소 가능 횟수와 보강 정책은 자동으로 적용됩니다.',
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
          if (lesson.isCanceled && lesson.lessonRightId != null)
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (hostContext.mounted) {
                  await showStudentMakeupDialog(
                    context: hostContext,
                    lesson: lesson,
                    controller: controller,
                  );
                }
              },
              child: const Text('보강 예약'),
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

Future<void> showStudentMakeupDialog({
  required BuildContext context,
  required Lesson lesson,
  required LessonController controller,
}) async {
  final hostContext = context;
  var selectedDate = lesson.startsAt;
  var options = <LessonBookingOption>[];
  var isLoading = true;
  String? errorMessage;

  Future<void> loadOptions(
    void Function(void Function()) setState,
  ) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loaded = await controller.getBookingOptions(
        lesson: lesson,
        selectedDate: selectedDate,
      );
      setState(() {
        options = loaded;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  await showDialog<void>(
    context: hostContext,
    builder: (dialogContext) {
      var firstBuild = true;

      return StatefulBuilder(
        builder: (dialogBodyContext, setState) {
          if (firstBuild) {
            firstBuild = false;
            Future.microtask(() => loadOptions(setState));
          }

          return AlertDialog(
            title: Text(
              '보강 예약',
              style: forestringTextStyle.copyWith(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('yyyy년 M월 d일').format(selectedDate),
                          style: forestringTextStyle,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogBodyContext,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 180),
                            ),
                          );
                          if (picked != null) {
                            selectedDate = picked;
                            await loadOptions(setState);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: forestringTextStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    )
                  else if (options.isEmpty)
                    Text(
                      '예약 가능한 시간이 없습니다.',
                      style: forestringTextStyle,
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${DateFormat('HH:mm').format(option.startsAt)} '
                              '~ ${DateFormat('HH:mm').format(option.endsAt)}',
                              style: forestringTextStyle.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final ok = await controller.bookLessonRight(
                                lesson: lesson,
                                option: option,
                              );

                              if (!dialogBodyContext.mounted) {
                                return;
                              }

                              if (ok) {
                                Navigator.of(dialogContext).pop();
                                if (hostContext.mounted) {
                                  _showMessage(
                                    hostContext,
                                    '보강 수업이 예약되었습니다.',
                                  );
                                }
                              } else if (hostContext.mounted) {
                                _showMessage(
                                  hostContext,
                                  controller.errorMessage ??
                                      '보강 수업을 예약하지 못했습니다.',
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('닫기'),
              ),
            ],
          );
        },
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
