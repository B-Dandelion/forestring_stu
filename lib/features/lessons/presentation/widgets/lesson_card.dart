import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/forestring_theme.dart';
import '../../domain/lesson.dart';

class StudentLessonCard extends StatelessWidget {
  const StudentLessonCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  final Lesson lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: lesson.isCanceled
                      ? Colors.black12
                      : primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${lesson.startsAt.month}월',
                      style: forestringTextStyle.copyWith(fontSize: 12),
                    ),
                    Text(
                      '${lesson.startsAt.day}',
                      style: forestringTextStyle.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.teacherName ?? '담당 선생님'} 선생님',
                      style: forestringTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: lesson.isCanceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('HH:mm').format(lesson.startsAt)} '
                      '~ ${DateFormat('HH:mm').format(lesson.endsAt)} '
                      '· ${lesson.displayTypeLabel}',
                      style: forestringTextStyle.copyWith(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.isCanceled)
                Text(
                  '취소',
                  style: forestringTextStyle.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (lesson.isRescheduled)
                Text(
                  '재예약',
                  style: forestringTextStyle.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
