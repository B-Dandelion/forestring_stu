import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/lessons/data/lesson_repository.dart';
import '../features/lessons/presentation/lesson_controller.dart';
import '../features/lessons/presentation/student_home_page.dart';

class AppGate extends StatelessWidget {
  const AppGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = auth.profile;

    if (!auth.isSignedIn || profile == null) {
      return const LoginPage();
    }

    return ChangeNotifierProvider(
      create: (_) => LessonController(
        LessonRepository(),
      )..initialize(),
      child: StudentHomePage(
        profile: profile,
      ),
    );
  }
}
