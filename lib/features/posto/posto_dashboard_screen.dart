import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/animations/app_animations.dart';
import '../auth/login_admin_screen.dart';
import 'posto_fila_screen.dart';
import 'posto_chamar_screen.dart';
import 'posto_ausencia_screen.dart';
import 'posto_emergencia_screen.dart';

class PostoDashboardScreen extends StatefulWidget {
  const PostoDashboardScreen({super.key});
  @override
  State<PostoDashboardScreen> createState() => _PostoDashboardScreenState();
}

class _PostoDashboardScreenState extends State<PostoDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _bgMain = Color(0xFFF2F6FC);
  static const _textDark = Color(0xFF1A2138);
  static const _textMuted = Color(0xFF7B8794);
  static const _dividerColor = Color(0xFFE8EEF5);
  static const _cardShadow = Color(0x0D000000);
  
  static const _blueAccent = Color(0xFF2563EB);
  static const _greenAccent = Color(0xFF10B981);
  static const _warningOrange = Color(0xFFFFA726);
  static const _purpleAccent = Color(0xFF7C3AED);

  late AnimationController _animController;
  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginAdminScreen()),
    );
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.inicio) return;
    Widget? destino;
    if (aba == DrawerAba.chamar) destino = const PostoChamarScreen();
    if (aba == DrawerAba.ausencia) destino = const PostoAusenciaScreen();
    if (aba == DrawerAba.fila) destino = const PostoFilaScreen();
    if (aba == DrawerAba.emergencia) destino = const PostoEmergenciaScreen();

    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Em breve.'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isSmall = screenW < 360;
    final isDesktop = screenW >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgMain,
      drawer: isDesktop
          ? null
          : AppDrawer(
              userName: _user?.displayName ?? 'Gestor de Posto',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: DrawerAba.inicio,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
              role: UserRole.posto,
            ),
      body: isDesktop ? _buildDesktop(isSmall) : _buildMobile(isSmall),
    );
  }

  Widget _buildDesktop(bool isSmall) {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Gestor de Posto',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.inicio,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
          role: UserRole.posto,
        ),
      ),
      Container(width: 1, color: const Color(0xFFE2E8F0)),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Gestor',
            userPhoto: _user?.photoURL,
            title: 'Painel do Posto',
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () {},
          ),
          Expanded(child: _buildScrollableContent(isSmall)),
        ]),
      ),
    ]);
  }

  Widget _buildMobile(bool isSmall) {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Gestor',
        userPhoto: _user?.photoURL,
        title: 'Painel do Posto',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      Expanded(child: _buildScrollableContent(isSmall)),
    ]);
  }

  Widget _buildScrollableContent(bool isSmall) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(isSmall),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmall ? 20 : 24),
                _buildActionGrid(isSmall),
                SizedBox(height: isSmall ? 24 : 28),
                _buildRecentActivity(isSmall),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isSmall ? 16 : 20, 20, isSmall ? 16 : 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bgMid, AppColors.bgBase],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isSmall ? 52 : 60,
            height: isSmall ? 52 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
          ),
          SizedBox(width: isSmall ? 14 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo, ${_user?.displayName ?? 'Gestor'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 17 : 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    )),
                const SizedBox(height: 2),
                Text('Operação do Posto de Saúde',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.45),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações do Dia',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
        SizedBox(height: isSmall ? 14 : 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardW = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionCard(
                  width: cardW,
                  icon: Icons.record_voice_over_rounded,
                  label: 'Chamar Paciente',
                  color: _blueAccent,
                  isSmall: isSmall,
                  onTap: () => _onAbaChanged(DrawerAba.chamar),
                ),
                _buildActionCard(
                  width: cardW,
                  icon: Icons.person_off_rounded,
                  label: 'Registrar Ausência',
                  color: _warningOrange,
                  isSmall: isSmall,
                  onTap: () => _onAbaChanged(DrawerAba.ausencia),
                ),
                _buildActionCard(
                  width: cardW,
                  icon: Icons.groups_rounded,
                  label: 'Fila do Posto',
                  color: _greenAccent,
                  isSmall: isSmall,
                  onTap: () => _onAbaChanged(DrawerAba.fila),
                ),
                _buildActionCard(
                  width: cardW,
                  icon: Icons.emergency_rounded,
                  label: 'Chamadas SOS',
                  color: Colors.red,
                  isSmall: isSmall,
                  onTap: () => _onAbaChanged(DrawerAba.emergencia),
                ),
                _buildActionCard(
                  width: cardW,
                  icon: Icons.history_rounded,
                  label: 'Histórico de Chamadas',
                  color: _purpleAccent,
                  isSmall: isSmall,
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required double width,
    required IconData icon,
    required String label,
    required Color color,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Container(
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: _cardShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: isSmall ? 42 : 48,
                height: isSmall ? 42 : 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: isSmall ? 22 : 24, color: color),
              ),
              SizedBox(height: isSmall ? 12 : 16),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atividade Recente',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
        SizedBox(height: isSmall ? 12 : 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: _cardShadow,
                  blurRadius: 10,
                  offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem('Paciente Chamado', 'Maria Santos - Guichê 02', 'há 2 min', isSmall),
              const Divider(color: _dividerColor),
              _buildActivityItem('Ausência Registrada', 'José Lima - Faltou', 'há 15 min', isSmall),
              const Divider(color: _dividerColor),
              _buildActivityItem('Início de Turno', 'Abertura do posto', 'há 1h', isSmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String titulo, String sub, String tempo, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: _textDark)),
                Text(sub, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _textMuted)),
              ],
            ),
          ),
          Text(tempo, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _textMuted)),
        ],
      ),
    );
  }
}
