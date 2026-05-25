// ═══════════════════════════════════════════════════════════════════
//  main.dart  —  ConectaSaúdePI
//
//  ROTAS:
//    /           → AuthWrapper (decide pra onde vai)
//    /login      → LoginCidadaoScreen
//    /home       → HomeCidadaoScreen
//    /admin      → LoginAdminScreen
//    /admin/home → SecretariaDashboardScreen
//
//  LÓGICA DO AuthWrapper:
//    1. Usuário não logado       → /login
//    2. Logado + perfil=admin    → /admin/home
//    3. Logado + perfil=cidadão  → /home
// ═══════════════════════════════════════════════════════════════════

import 'package:conecta_saude_pi/features/secretaria/secretaria_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/auth/login_cidadao_screen.dart';
import 'features/auth/login_admin_screen.dart';
import 'features/cidadao/dashboard_cidadao.dart';
import 'features/cidadao/perfil_screen.dart';
import 'firebase_options.dart';
import 'admin_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await AppTheme.lockPortrait();
  AppTheme.applySystemUI();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ConectaSaudeApp());
}

class ConectaSaudeApp extends StatelessWidget {
  const ConectaSaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConectaSaúdePI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthWrapper(),
        '/login': (_) => const LoginCidadaoScreen(),
        '/home': (_) => const HomeCidadaoScreen(),
        '/admin': (_) => const LoginAdminScreen(),
        '/admin/home': (_) => const SecretariaDashboardScreen(),
        '/perfil': (_) => const PerfilScreen(),
        '/setup-admin': (_) => const AdminSetupPage(),
      },
    );
  }
}
