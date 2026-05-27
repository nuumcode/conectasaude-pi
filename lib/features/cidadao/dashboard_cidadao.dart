import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_escala_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_fila_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/perfil_screen.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

class HomeCidadaoScreen extends StatefulWidget {
  const HomeCidadaoScreen({super.key});

  @override
  State<HomeCidadaoScreen> createState() => _HomeCidadaoScreenState();
}

class _HomeCidadaoScreenState extends State<HomeCidadaoScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginCidadaoScreen()),
    );
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.inicio) return;
    final Widget? destino = _resolverAba(aba);
    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Em breve.'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  Widget? _resolverAba(dynamic aba) {
    switch (aba) {
      case DrawerAba.inicio:
        return const HomeCidadaoScreen();
      case DrawerAba.agendamentos:
        return const CidadaoEscalaScreen();
      case DrawerAba.fila:
        return const CidadaoFilaScreen();
      case DrawerAba.emergencia:
        return const CidadaoEmergenciaScreen();
      case DrawerAba.perfil:
        return const PerfilScreen();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
      drawer: isDesktop
          ? null
          : AppDrawer(
              userName: _user?.displayName ?? 'Usuário',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: DrawerAba.inicio,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
            ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  Widget _buildDesktop() {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Usuário',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.inicio,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
        ),
      ),
      Container(width: 1, color: AppColors.borderDim),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Usuário',
            userPhoto: _user?.photoURL,
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
          ),
          Expanded(child: _buildConteudo()),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Usuário',
        userPhoto: _user?.photoURL,
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
      ),
      Expanded(child: _buildConteudo()),
    ]);
  }

  Widget _buildConteudo() {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildActionGrid(),
              const SizedBox(height: 32),
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, ${_user?.displayName?.split(' ').first ?? 'Usuário'}!',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'Como podemos ajudar você hoje?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      _AcaoData(
          icon: Icons.calendar_today_rounded,
          label: 'Agendamentos',
          onTap: () => _onAbaChanged(DrawerAba.agendamentos)),
      _AcaoData(
          icon: Icons.groups_rounded,
          label: 'Fila Virtual',
          onTap: () => _onAbaChanged(DrawerAba.fila)),
      _AcaoData(
          icon: Icons.folder_outlined,
          label: 'Meus Dados',
          onTap: () => _onAbaChanged(DrawerAba.perfil)),
      _AcaoData(
          icon: Icons.emergency_rounded,
          label: 'Emergência',
          destaque: true,
          onTap: () => _onAbaChanged(DrawerAba.emergencia)),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];
          return _buildActionCard(item);
        },
      );
    });
  }

  Widget _buildActionCard(_AcaoData item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.destaque ? AppColors.error : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDim),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 32,
              color: item.destaque ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.destaque ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informativo Conecta Saúde',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mantenha seu cadastro sempre atualizado para facilitar o atendimento nas unidades de saúde.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcaoData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destaque;
  _AcaoData(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.destaque = false});
}
