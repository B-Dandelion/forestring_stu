import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_gate.dart';
import 'core/config/app_config.dart';
import 'core/theme/forestring_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  final authController = AuthController(
    AuthRepository(),
  );

  await authController.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: authController,
      child: const ForestringStudent(),
    ),
  );
}

class ForestringStudent extends StatelessWidget {
  const ForestringStudent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '포레스트링 수강생',
      theme: buildForestringTheme(),
      home: const AppGate(),
    );
  }
}
