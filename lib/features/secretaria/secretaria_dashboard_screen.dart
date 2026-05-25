import 'package:conecta_saude_pi/features/secretaria/secretaria_escala_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/animations/app_animations.dart';
import '../auth/login_admin_screen.dart';

class SecretariaDashboardScreen extends StatefulWidget {
  const SecretariaDashboardScreen({super.key});
  @override
  State<SecretariaDashboardScreen> createState() =>
      _SecretariaDashboardScreenState();
}

class _SecretariaDashboardScreenState extends State<SecretariaDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = 0;
  static const _bgMain = Color(0xFFF2F6FC);
  static const _textDark = Color(0xFF1A2138);
  static const _textMuted = Color(0xFF7B8794);
  static const _dividerColor = Color(0xFFE8EEF5);
  static const _cardShadow = Color(0x0D000000);
  static const _warningOrange = Color(0xFFFFA726);
  static const _purpleAccent = Color(0xFF7C3AED);
  static const _blueAccent = Color(0xFF2563EB);
  static const _greenAccent = Color(0xFF10B981);
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
    if (aba == DrawerAba.escalas) destino = const SecretariaEscalaScreen();

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
              userName: _user?.displayName ?? 'Administrador',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: DrawerAba.inicio,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
              role: UserRole.secretaria,
            ),
      body: isDesktop ? _buildDesktop(isSmall) : _buildMobile(isSmall),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(isSmall),
    );
  }

  Widget _buildDesktop(bool isSmall) {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Administrador',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.inicio,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
          role: UserRole.secretaria,
        ),
      ),
      Container(width: 1, color: const Color(0xFFE2E8F0)),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Admin',
            userPhoto: _user?.photoURL,
            title: 'Painel Admin',
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
        userName: _user?.displayName?.split(' ').first ?? 'Admin',
        userPhoto: _user?.photoURL,
        title: 'Painel Admin',
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
                _buildStatGrid(isSmall),
                SizedBox(height: isSmall ? 24 : 28),
                _buildPlatformUsage(isSmall),
                SizedBox(height: isSmall ? 24 : 28),
                _buildAdminControls(isSmall),
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
      padding:
          EdgeInsets.fromLTRB(isSmall ? 16 : 20, 20, isSmall ? 16 : 20, 24),
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
                colors: [Color(0xFF2980B9), Color(0xFF1A72FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/logo-var01.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isSmall ? 14 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: 'Conecta',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isSmall ? 10 : 11,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.6),
                            )),
                        TextSpan(
                            text: 'Saúde',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isSmall ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blueLt,
                            )),
                        TextSpan(
                            text: 'PI',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isSmall ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            )),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Super Admin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isSmall ? 8 : 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 4 : 6),
                Text('Bem-vindo, ${_user?.displayName ?? 'Administrador'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 17 : 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    )),
                const SizedBox(height: 2),
                Text('Administrador do Sistema',
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

  Widget _buildStatGrid(bool isSmall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              width: cardW,
              icon: Icons.people_alt_rounded,
              iconBgColor: const Color(0xFFEBF5FF),
              iconColor: _blueAccent,
              valor: '12.543',
              label: 'Usuários Totais',
              trend: '+2%',
              trendLabel: 'último mês',
              positivo: true,
              isSmall: isSmall,
            ),
            _buildStatCard(
              width: cardW,
              icon: Icons.monitor_heart_rounded,
              iconBgColor: const Color(0xFFE8FFF5),
              iconColor: _greenAccent,
              valor: '1.234',
              label: 'Sessões Ativas',
              trend: '+6.7%',
              trendLabel: 'último mês',
              positivo: true,
              isSmall: isSmall,
            ),
            _buildStatCard(
              width: cardW,
              icon: Icons.verified_rounded,
              iconBgColor: const Color(0xFFF3EEFF),
              iconColor: _purpleAccent,
              valor: '99.8%',
              label: 'Disponibilidade',
              trend: 'Excelente',
              trendLabel: '',
              positivo: true,
              isSmall: isSmall,
            ),
            _buildStatCard(
              width: cardW,
              icon: Icons.pending_actions_rounded,
              iconBgColor: const Color(0xFFFFF4E5),
              iconColor: _warningOrange,
              valor: '15',
              label: 'Relatórios Pendentes',
              trend: '',
              trendLabel: '',
              positivo: true,
              isSmall: isSmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String valor,
    required String label,
    required String trend,
    required String trendLabel,
    required bool positivo,
    required bool isSmall,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(
              color: _cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: iconColor.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isSmall ? 38 : 44,
                  height: isSmall ? 38 : 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: isSmall ? 20 : 22, color: iconColor),
                ),
                if (trend.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: positivo
                          ? _greenAccent.withOpacity(0.1)
                          : const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(trend,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSmall ? 9 : 10,
                          fontWeight: FontWeight.w600,
                          color:
                              positivo ? _greenAccent : const Color(0xFFEF4444),
                        )),
                  ),
              ],
            ),
            SizedBox(height: isSmall ? 14 : 16),
            Text(valor,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                )),
            if (trendLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(trendLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 9 : 10,
                      color: _textMuted.withOpacity(0.6),
                    )),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformUsage(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Visão Geral de Uso',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _dividerColor),
                boxShadow: const [
                  BoxShadow(
                      color: _cardShadow, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: _blueAccent),
                  const SizedBox(width: 6),
                  Text('Últimos 7 Dias',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isSmall ? 10 : 11,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      )),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: _textMuted),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isSmall ? 14 : 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildActivityChart(isSmall)),
            SizedBox(width: isSmall ? 12 : 14),
            Expanded(flex: 2, child: _buildDonutChart(isSmall)),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityChart(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: _cardShadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Atividade da Plataforma',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  )),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 14 : 18),
          SizedBox(
            height: isSmall ? 90 : 110,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                color: _blueAccent,
                fillColor: _blueAccent.withOpacity(0.06),
                showGrid: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
                .map((d) => Text(d,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 7 : 8,
                      color: _textMuted.withOpacity(0.6),
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: _cardShadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text('Usuários por Perfil',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: _textDark,
              )),
          SizedBox(height: isSmall ? 12 : 16),
          SizedBox(
            width: isSmall ? 85 : 105,
            height: isSmall ? 85 : 105,
            child: CustomPaint(
              painter: _DonutChartPainter(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('12,543',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        )),
                    Text('Total',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSmall ? 8 : 9,
                          color: _textMuted,
                        )),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isSmall ? 12 : 14),
          _buildLegendItem('Cidadãos', _blueAccent, '80%', isSmall),
          const SizedBox(height: 5),
          _buildLegendItem('Profissionais', _greenAccent, '15%', isSmall),
          const SizedBox(height: 5),
          _buildLegendItem('Admin', _warningOrange, '5%', isSmall),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      String label, Color color, String value, bool isSmall) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 9 : 10,
                color: _textMuted,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
      ],
    );
  }

  Widget _buildAdminControls(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Controles Admin',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
        SizedBox(height: isSmall ? 14 : 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardW = (constraints.maxWidth - 24) / 4;
            return Row(
              children: [
                _buildControlBtn(cardW, Icons.manage_accounts_rounded,
                    'Gestão de\nUsuários', _blueAccent, isSmall),
                const SizedBox(width: 8),
                _buildControlBtn(cardW, Icons.tune_rounded,
                    'Config. do\nSistema', _greenAccent, isSmall),
                const SizedBox(width: 8),
                _buildControlBtn(cardW, Icons.history_rounded,
                    'Logs de\nAtividade', _purpleAccent, isSmall),
                const SizedBox(width: 8),
                _buildControlBtn(cardW, Icons.analytics_rounded,
                    'Relatórios\n& Análises', _warningOrange, isSmall),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlBtn(
      double width, IconData icon, String label, Color color, bool isSmall) {
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 16 : 20,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _dividerColor.withOpacity(0.7)),
          boxShadow: const [
            BoxShadow(color: _cardShadow, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: isSmall ? 38 : 44,
              height: isSmall ? 38 : 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: isSmall ? 20 : 22, color: color),
            ),
            SizedBox(height: isSmall ? 8 : 10),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  height: 1.3,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isSmall) {
    final atividades = [
      _Atividade(
        Icons.person_add_alt_1_rounded,
        _blueAccent,
        'Novo usuário registrado',
        'Maria Oliveira - cadastro completo',
        'há 5 min',
      ),
      _Atividade(
        Icons.security_rounded,
        _greenAccent,
        'Verificação de segurança concluída',
        'Nenhuma vulnerabilidade detectada',
        'há 12 min',
      ),
      _Atividade(
        Icons.description_rounded,
        _warningOrange,
        'Relatório gerado',
        'Relatório mensal de atendimentos exportado',
        'há 25 min',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Atividade Recente do Sistema',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                )),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text('Ver Tudo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isSmall ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: _blueAccent,
                      )),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: _blueAccent),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isSmall ? 12 : 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: _cardShadow, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: List.generate(atividades.length, (i) {
              final a = atividades[i];
              final isLast = i == atividades.length - 1;
              return Container(
                padding: EdgeInsets.symmetric(
                  vertical: isSmall ? 14 : 16,
                  horizontal: isSmall ? 14 : 16,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: _dividerColor.withOpacity(0.5),
                              width: 0.8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isSmall ? 40 : 44,
                      height: isSmall ? 40 : 44,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(a.icon, size: isSmall ? 20 : 22, color: a.color),
                    ),
                    SizedBox(width: isSmall ? 12 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.titulo,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isSmall ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              )),
                          const SizedBox(height: 3),
                          Text(a.descricao,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isSmall ? 10 : 11,
                                color: _textMuted,
                              )),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: a.color.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(a.tempo,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isSmall ? 9 : 10,
                              color: _textMuted,
                            )),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isSmall) {
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.people_alt_outlined, 'Usuários'),
      _NavItem(Icons.shield_outlined, 'Segurança'),
    ];
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == _navIndex;
          final isDataAI = i == 3;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: selected
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDataAI
                                  ? [
                                      _blueAccent.withOpacity(0.15),
                                      _purpleAccent.withOpacity(0.1)
                                    ]
                                  : [
                                      _blueAccent.withOpacity(0.12),
                                      _blueAccent.withOpacity(0.06)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      items[i].icon,
                      size: isSmall ? 22 : 24,
                      color: isDataAI
                          ? (selected
                              ? _blueAccent
                              : _blueAccent.withOpacity(0.7))
                          : (selected ? _blueAccent : _textMuted),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 9 : 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: isDataAI
                          ? _blueAccent
                          : (selected ? _blueAccent : _textMuted),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Color color;
  final Color fillColor;
  final bool showGrid;
  _LineChartPainter({
    required this.color,
    required this.fillColor,
    this.showGrid = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFEEF2F7)
        ..strokeWidth = 0.5;
      for (int i = 0; i <= 4; i++) {
        final y = h * i / 4;
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    }
    final points = [0.25, 0.45, 0.35, 0.65, 0.55, 0.8, 0.7, 0.88, 0.72, 0.82];
    final stepX = w / (points.length - 1);
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = h - (points[i] * h);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = h - (points[i - 1] * h);
        final cpX1 = prevX + stepX * 0.4;
        final cpX2 = x - stepX * 0.4;
        path.cubicTo(cpX1, prevY, cpX2, y, x, y);
        fillPath.cubicTo(cpX1, prevY, cpX2, y, x, y);
      }
    }
    fillPath.lineTo(w, h);
    fillPath.close();
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
    );
    canvas.drawPath(fillPath,
        Paint()..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    final lastX = (points.length - 1) * stepX;
    final lastY = h - (points.last * h);
    canvas.drawCircle(
        Offset(lastX, lastY), 5, Paint()..color = color.withOpacity(0.2));
    canvas.drawCircle(Offset(lastX, lastY), 3.5, Paint()..color = color);
    canvas.drawCircle(Offset(lastX, lastY), 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => false;
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    const strokeWidth = 14.0;
    final segments = [
      _DonutSegment(0.80, const Color(0xFF2563EB)),
      _DonutSegment(0.15, const Color(0xFF10B981)),
      _DonutSegment(0.05, const Color(0xFFFFA726)),
    ];
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = const Color(0xFFF0F4F8));
    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = 2 * math.pi * seg.value;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.06,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = seg.color,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) => false;
}

class _DonutSegment {
  final double value;
  final Color color;
  _DonutSegment(this.value, this.color);
}

class _Atividade {
  final IconData icon;
  final Color color;
  final String titulo;
  final String descricao;
  final String tempo;
  _Atividade(this.icon, this.color, this.titulo, this.descricao, this.tempo);
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
