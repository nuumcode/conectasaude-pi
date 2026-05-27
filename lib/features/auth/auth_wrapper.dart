// ═══════════════════════════════════════════════════════════════════
//  auth_wrapper.dart  —  ConectaSaúdePI
//
//  RESPONSABILIDADE:
//    "Silent Gate" — Verifica sessão e perfil sem splash invasivo.
//    Se a resposta for instantânea (<300ms), o usuário nem vê o splash.
//    Se demorar, exibe o fundo padrão para manter a fluidez.
// ═══════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

import '../cidadao/dashboard_cidadao.dart';
import '../secretaria/secretaria_dashboard_screen.dart';
import '../posto/posto_dashboard_screen.dart';
import 'login_cidadao_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Pequeno delay para garantir que o Firebase Auth inicializou
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;

    // IMPORTANTE PARA WEB: Se o usuário acessou um deep link (ex: /admin)
    // o AuthWrapper estará na base da pilha, mas não será a rota "atual".
    // Se não for a rota atual, não devemos disparar o redirecionamento automático.
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isCurrent) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigate('/login');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final perfil = doc.data()?['perfil'] as String?;
      if (perfil == 'admin') {
        _navigate('/admin/home');
      } else if (perfil == 'posto') {
        _navigate('/posto/home');
      } else {
        _navigate('/home');
      }
    } catch (_) {
      _navigate('/login');
    }
  }

  void _navigate(String route) {
    if (!mounted) return;
    
    Widget page;
    switch (route) {
      case '/home': page = const HomeCidadaoScreen(); break;
      case '/admin/home': page = const SecretariaDashboardScreen(); break;
      case '/posto/home': page = const PostoDashboardScreen(); break;
      case '/login':
      default: page = const LoginCidadaoScreen(); break;
    }

    Navigator.of(context).pushReplacement(
      AppHeroFadeRoute(page: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retorna apenas o fundo sutil enquanto decide o destino.
    // Isso evita o "pisca" da logo e mantém a elegância.
    return const Scaffold(
      backgroundColor: AppColors.bgBase,
      body: AppBackground(child: SizedBox.expand()),
    );
  }
}
