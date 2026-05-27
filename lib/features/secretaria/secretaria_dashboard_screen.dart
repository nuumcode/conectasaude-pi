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

class _SecretariaDashboardScreenState extends State<SecretariaDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

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
    if (aba == DrawerAba.escala) destino = const SecretariaEscalaScreen();


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
              userName: _user?.displayName ?? 'Administrador',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: DrawerAba.inicio,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
              role: UserRole.secretaria,
            ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildDesktop() {
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
      Container(width: 1, color: AppColors.borderDim),
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
          Expanded(child: _buildScrollableContent()),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Admin',
        userPhoto: _user?.photoURL,
        title: 'Painel Admin',
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
          AppEntrance(index: 0, child: _buildWelcomeBanner()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const AppEntrance(
                    index: 1,
                    delay: Duration(milliseconds: 100),
                    child: _StatGrid()),
                const SizedBox(height: 28),
                const AppEntrance(
                    index: 2,
                    delay: Duration(milliseconds: 200),
                    child: _PlatformUsage()),
                const SizedBox(height: 28),
                AppEntrance(
                    index: 3,
                    delay: const Duration(milliseconds: 300),
                    child: _AdminControls()),
                const SizedBox(height: 28),
                AppEntrance(
                    index: 4,
                    delay: const Duration(milliseconds: 400),
                    child: _RecentActivity()),
                const SizedBox(height: 100),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(10),
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
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                            text: 'Conecta',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              color: Colors.white70,
                            )),
                        TextSpan(
                            text: 'Saúde',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        TextSpan(
                            text: 'PI',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Super Admin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Bem-vindo, ${_user?.displayName ?? 'Administrador'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    )),
                const SizedBox(height: 2),
                Text('Administrador do Sistema',
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

  Widget _buildBottomNav() {
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
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      items[i].icon,
                      size: 24,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
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

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              width: cardW,
              icon: Icons.people_alt_rounded,
              iconBgColor: AppColors.primary.withOpacity(0.1),
              iconColor: AppColors.primary,
              valor: '12.543',
              label: 'Usuários Totais',
              trend: '+2%',
              trendLabel: 'último mês',
              positivo: true,
            ),
            _StatCard(
              width: cardW,
              icon: Icons.monitor_heart_rounded,
              iconBgColor: AppColors.success.withOpacity(0.1),
              iconColor: AppColors.success,
              valor: '1.234',
              label: 'Sessões Ativas',
              trend: '+6.7%',
              trendLabel: 'último mês',
              positivo: true,
            ),
            _StatCard(
              width: cardW,
              icon: Icons.verified_rounded,
              iconBgColor: AppColors.primaryDeep.withOpacity(0.1),
              iconColor: AppColors.primaryDeep,
              valor: '99.8%',
              label: 'Disponibilidade',
              trend: 'Excelente',
              trendLabel: '',
              positivo: true,
            ),
            _StatCard(
              width: cardW,
              icon: Icons.pending_actions_rounded,
              iconBgColor: AppColors.warning.withOpacity(0.1),
              iconColor: AppColors.warning,
              valor: '15',
              label: 'Relatórios Pendentes',
              trend: '',
              trendLabel: '',
              positivo: true,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String valor;
  final String label;
  final String trend;
  final String trendLabel;
  final bool positivo;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.valor,
    required this.label,
    required this.trend,
    required this.trendLabel,
    required this.positivo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDim),
          boxShadow: [
            const BoxShadow(
              color: Color(0x05000000),
              blurRadius: 12,
              offset: Offset(0, 4),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                if (trend.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: positivo
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(trend,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              positivo ? AppColors.success : AppColors.error,
                        )),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(valor,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                )),
            if (trendLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(trendLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textSecondary.withOpacity(0.6),
                    )),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlatformUsage extends StatelessWidget {
  const _PlatformUsage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Visão Geral de Uso',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDim),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Últimos 7 Dias',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      )),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _ActivityChart()),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: _DonutChart()),
          ],
        ),
      ],
    );
  }
}

class _ActivityChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Atividade da Plataforma',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                color: AppColors.primary,
                fillColor: AppColors.primary.withOpacity(0.06),
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
                      fontSize: 8,
                      color: AppColors.textSecondary.withOpacity(0.6),
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        children: [
          const Text('Usuários por Perfil',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: 105,
            height: 105,
            child: CustomPaint(
              painter: _DonutChartPainter(),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('12,543',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                    Text('Total',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _LegendItem('Cidadãos', AppColors.primary, '80%'),
          const SizedBox(height: 5),
          _LegendItem('Profissionais', AppColors.success, '15%'),
          const SizedBox(height: 5),
          _LegendItem('Admin', AppColors.warning, '5%'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final String value;

  const _LegendItem(this.label, this.color, this.value);

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary,
              )),
        ),
        Text(value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }
}

class _AdminControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Controles Admin',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardW = (constraints.maxWidth - 24) / 4;
            return Row(
              children: [
                _ControlBtn(cardW, Icons.manage_accounts_rounded,
                    'Gestão de\nUsuários', AppColors.primary),
                const SizedBox(width: 8),
                _ControlBtn(cardW, Icons.tune_rounded,
                    'Config. do\nSistema', AppColors.success),
                const SizedBox(width: 8),
                _ControlBtn(cardW, Icons.history_rounded,
                    'Logs de\nAtividade', AppColors.primaryDeep),
                const SizedBox(width: 8),
                _ControlBtn(cardW, Icons.analytics_rounded,
                    'Relatórios\n& Análises', AppColors.warning),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final Color color;

  const _ControlBtn(this.width, this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDim),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                )),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final atividades = [
      _AtividadeData(
        Icons.person_add_alt_1_rounded,
        AppColors.primary,
        'Novo usuário registrado',
        'Maria Oliveira - cadastro completo',
        'há 5 min',
      ),
      _AtividadeData(
        Icons.security_rounded,
        AppColors.success,
        'Verificação de segurança concluída',
        'Nenhuma vulnerabilidade detectada',
        'há 12 min',
      ),
      _AtividadeData(
        Icons.description_rounded,
        AppColors.warning,
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
            const Text('Atividade Recente do Sistema',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            GestureDetector(
              onTap: () {},
              child: const Row(
                children: [
                  Text('Ver Tudo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDim),
          ),
          child: Column(
            children: List.generate(atividades.length, (i) {
              final a = atividades[i];
              final isLast = i == atividades.length - 1;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                              color: AppColors.borderDim,
                              width: 0.8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(a.icon, size: 22, color: a.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.titulo,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                          const SizedBox(height: 3),
                          Text(a.descricao,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textSecondary,
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
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: AppColors.textSecondary,
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
        ..color = AppColors.borderDim
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
      _DonutSegment(0.80, AppColors.primary),
      _DonutSegment(0.15, AppColors.success),
      _DonutSegment(0.05, AppColors.warning),
    ];
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = AppColors.surfaceDim);
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

class _AtividadeData {
  final IconData icon;
  final Color color;
  final String titulo;
  final String descricao;
  final String tempo;
  _AtividadeData(this.icon, this.color, this.titulo, this.descricao, this.tempo);
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
