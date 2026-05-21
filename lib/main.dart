import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/dashboard_cidadao.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppTheme.lockPortrait();
  AppTheme.applySystemUI();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ConectaSaudeApp());
}

class ConectaSaudeApp extends StatelessWidget {
  const ConectaSaudeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConectaSaúdePI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login', // 👈 rota inicial
      routes: {
        '/login': (context) => const LoginCidadaoScreen(),
        '/home': (context) => const HomeCidadaoScreen(),
      },
      // Se quiser, pode manter um fallback com home
      // home: const LoginCidadaoScreen(),
    );
  }
}
