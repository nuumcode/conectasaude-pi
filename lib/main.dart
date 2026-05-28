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

import 'package:conecta_saude_pi/features/cidadao/cidadao_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/posto/posto_dashboard_screen.dart';
import 'package:conecta_saude_pi/features/posto/posto_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/secretaria/secretaria_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  await initializeDateFormatting('pt_BR', null);

  // ✅ Pré-carregamento global de assets críticos para evitar o "pisca" na logo
  // Fazemos isso antes do runApp para que no primeiro frame a logo já esteja pronta.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.addPostFrameCallback((_) async {
    final BuildContext context = binding.rootElement!;
    precacheImage(const AssetImage('assets/logo-var01.png'), context);
  });

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
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginCidadaoScreen(),
        '/home': (_) => const HomeCidadaoScreen(),
        '/admin': (_) => const LoginAdminScreen(),
        '/admin/home': (_) => const SecretariaDashboardScreen(),
        '/posto/home': (_) => const PostoDashboardScreen(),
        '/emergencia': (_) => const CidadaoEmergenciaScreen(),
        '/posto/emergencia': (_) => const PostoEmergenciaScreen(),
        '/perfil': (_) => const PerfilScreen(),
        '/setup-admin': (_) => const AdminSetupPage(),
      },
    );
  }
}
