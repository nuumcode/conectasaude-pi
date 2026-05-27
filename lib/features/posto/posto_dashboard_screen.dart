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
  
  static const _cardShadow = Color(0x0D000000);

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
    final isDesktop = screenW >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
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
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  Widget _buildDesktop() {
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
      Container(width: 1, color: AppColors.borderDim),
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
          Expanded(child: _buildScrollableContent()),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Gestor',
        userPhoto: _user?.photoURL,
        title: 'Painel do Posto',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      Expanded(child: _buildScrollableContent()),
    ]);
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                _ActionGrid(),
                SizedBox(height: 28),
                _RecentActivity(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo, ${_user?.displayName ?? 'Gestor'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    )),
                const SizedBox(height: 2),
                Text('Operação do Posto de Saúde',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ações do Dia',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardW = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionCard(
                  width: cardW,
                  icon: Icons.record_voice_over_rounded,
                  label: 'Chamar Paciente',
                  color: AppColors.primary,
                  onTap: () {
                    final state = context.findAncestorStateOfType<_PostoDashboardScreenState>();
                    state?._onAbaChanged(DrawerAba.chamar);
                  },
                ),
                _ActionCard(
                  width: cardW,
                  icon: Icons.person_off_rounded,
                  label: 'Registrar Ausência',
                  color: AppColors.warning,
                  onTap: () {
                    final state = context.findAncestorStateOfType<_PostoDashboardScreenState>();
                    state?._onAbaChanged(DrawerAba.ausencia);
                  },
                ),
                _ActionCard(
                  width: cardW,
                  icon: Icons.groups_rounded,
                  label: 'Fila do Posto',
                  color: AppColors.success,
                  onTap: () {
                    final state = context.findAncestorStateOfType<_PostoDashboardScreenState>();
                    state?._onAbaChanged(DrawerAba.fila);
                  },
                ),
                _ActionCard(
                  width: cardW,
                  icon: Icons.emergency_rounded,
                  label: 'Chamadas SOS',
                  color: AppColors.error,
                  onTap: () {
                    final state = context.findAncestorStateOfType<_PostoDashboardScreenState>();
                    state?._onAbaChanged(DrawerAba.emergencia);
                  },
                ),
                _ActionCard(
                  width: cardW,
                  icon: Icons.history_rounded,
                  label: 'Histórico de Chamadas',
                  color: AppColors.primaryDeep,
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDim),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 16),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Atividade Recente',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDim),
          ),
          child: const Column(
            children: [
              _ActivityItem('Paciente Chamado', 'Maria Santos - Guichê 02', 'há 2 min'),
              Divider(color: AppColors.borderDim),
              _ActivityItem('Ausência Registrada', 'José Lima - Faltou', 'há 15 min'),
              Divider(color: AppColors.borderDim),
              _ActivityItem('Início de Turno', 'Abertura do posto', 'há 1h'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String titulo;
  final String sub;
  final String tempo;

  const _ActivityItem(this.titulo, this.sub, this.tempo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                Text(sub, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(tempo, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
