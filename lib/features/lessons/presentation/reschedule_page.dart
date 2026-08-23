import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import 'lesson_controller.dart';
import 'widgets/lesson_action_dialog.dart';
import 'widgets/lesson_card.dart';

class ReschedulePage extends StatelessWidget {
  const ReschedulePage({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();
    final canceled = controller.canceledLessons;

    return Scaffold(
      appBar: const StudentAppBar(),
      drawer: StudentDrawer(
        displayName: profile.displayName,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
        },
        onReschedule: () => Navigator.of(context).pop(),
        onLogout: () async {
          Navigator.of(context).pop();
          await context.read<AuthController>().signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.reload,
          child: canceled.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 100),
                    const Icon(
                      Icons.event_available_outlined,
                      size: 52,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '보강 예약이 필요한 수업이 없습니다.',
                      textAlign: TextAlign.center,
                      style: forestringTextStyle.copyWith(
                        fontSize: 17,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: canceled.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lesson = canceled[index];
                    return StudentLessonCard(
                      lesson: lesson,
                      onTap: () => showStudentMakeupDialog(
                        context: context,
                        lesson: lesson,
                        controller: context.read<LessonController>(),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
