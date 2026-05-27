import 'package:conecta_saude_pi/features/posto/posto_emergencia_screen.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/animations/app_animations.dart';
import '../auth/login_admin_screen.dart';
import 'posto_dashboard_screen.dart';
import 'posto_fila_screen.dart';
import 'posto_ausencia_screen.dart';

class PostoChamarScreen extends StatefulWidget {
  const PostoChamarScreen({super.key});
  @override
  State<PostoChamarScreen> createState() => _PostoChamarScreenState();
}

class _PostoChamarScreenState extends State<PostoChamarScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _navIndex = 0;
  
  static const _cardShadow = Color(0x0A000000);

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
    if (aba == DrawerAba.chamar) return;
    Widget? destino;
    if (aba == DrawerAba.inicio) destino = const PostoDashboardScreen();
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

  // Mock data
  final _profissional = _DadosProfissional(
    nome: 'Dr. João Silva',
    especialidade: 'Cardiologia',
  );
  final _resumo = _ResumoDia(
    pacientesCadastrados: 24,
    consultasHoje: 5,
    filaVirtualAguardando: 3,
  );
  final _consultas = <_Consulta>[
    _Consulta('Maria Oliveira', 'Consulta presencial', '08:30', AppColors.primary),
    _Consulta('Carlos Mendes', 'Consulta', '09:15', AppColors.success),
    _Consulta('Ana Paula Santos', 'Consulta presencial', '10:00', AppColors.primaryDeep),
    _Consulta('João Pereira', 'Consulta presencial', '10:45', AppColors.warning),
    _Consulta('Fernanda Lima', 'Consulta presencial', '11:30', AppColors.accent),
  ];

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
              abaAtual: DrawerAba.chamar,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
              role: UserRole.posto,
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
          userName: _user?.displayName ?? 'Gestor de Posto',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.chamar,
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
            title: 'Chamar Paciente',
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
        title: 'Chamar Paciente',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildResumoSection(),
                const SizedBox(height: 28),
                _buildAcoesRapidas(),
                const SizedBox(height: 28),
                _buildProximasConsultas(),
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
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profissional.nome,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      _profissional.especialidade,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Resumo do dia ──────────────────────────────────────────
  Widget _buildResumoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Resumo do dia',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  _getDataHoje(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Cards de stats
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 3;
            return Row(
              children: [
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primary.withOpacity(0.1),
                  valor: '${_resumo.pacientesCadastrados}',
                  label: 'Pacientes',
                  sublabel: 'Cadastrados',
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.event_note_rounded,
                  iconColor: AppColors.success,
                  iconBg: AppColors.success.withOpacity(0.1),
                  valor: '${_resumo.consultasHoje}',
                  label: 'Consultas Hoje',
                  sublabel: 'Agendadas',
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.primaryDeep,
                  iconBg: AppColors.primaryDeep.withOpacity(0.1),
                  valor: '${_resumo.filaVirtualAguardando}',
                  label: 'Fila Virtual',
                  sublabel: 'Aguardando',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String valor,
    required String label,
    required String sublabel,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDim),
          boxShadow: const [
            BoxShadow(
              color: _cardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ações rápidas ──────────────────────────────────────────
  Widget _buildAcoesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ações rápidas',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAcaoBtn(
                icon: Icons.people_outline_rounded,
                label: 'Ver Pacientes',
                sublabel: 'Acessar lista',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAcaoBtn(
                icon: Icons.queue_rounded,
                label: 'Fila Virtual',
                sublabel: 'Ver fila atual',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAcaoBtn(
                icon: Icons.chat_outlined,
                label: 'Mensagens',
                sublabel: 'Ver conversas',
                color: AppColors.primaryDeep,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcaoBtn({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 2),
          Text(sublabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }

  // ── Próximas consultas ─────────────────────────────────────
  Widget _buildProximasConsultas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Próximas consultas',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            GestureDetector(
              onTap: () {},
              child: const Text('Ver agenda completa >',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(_consultas.length, (i) {
          final consulta = _consultas[i];
          return _buildConsultaItem(
              consulta, i == _consultas.length - 1);
        }),
      ],
    );
  }

  Widget _buildConsultaItem(_Consulta consulta, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLast ? 12 : 0).copyWith(
          topLeft: Radius.circular(
              isLast ? 0 : (_consultas.indexOf(consulta) == 0 ? 12 : 0)),
          topRight: Radius.circular(
              isLast ? 0 : (_consultas.indexOf(consulta) == 0 ? 12 : 0)),
          bottomLeft: Radius.circular(isLast ? 12 : 0),
          bottomRight: Radius.circular(isLast ? 12 : 0),
        ),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: consulta.avatarColor.withOpacity(0.1),
              border: Border.all(
                color: consulta.avatarColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.person_rounded,
                size: 22, color: consulta.avatarColor),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consulta.nome,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(consulta.tipo,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ],
            ),
          ),
          // Horário
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(consulta.horario,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                )),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ──────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.calendar_today_rounded, 'Agenda'),
      _NavItem(Icons.people_alt_outlined, 'Pacientes'),
      _NavItem(Icons.chat_bubble_outline_rounded, 'Mensagens'),
      _NavItem(Icons.more_horiz_rounded, 'Mais'),
    ];
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderDim)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    size: 24,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

  // ── Utils ──────────────────────────────────────────────────
  String _getDataHoje() {
    final meses = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final now = DateTime.now();
    return '${now.day} de ${meses[now.month - 1]}, ${now.year}';
  }
}

// ─────────────────────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────────────────────
class _DadosProfissional {
  final String nome;
  final String especialidade;
  _DadosProfissional({required this.nome, required this.especialidade});
}

class _ResumoDia {
  final int pacientesCadastrados;
  final int consultasHoje;
  final int filaVirtualAguardando;
  _ResumoDia({
    required this.pacientesCadastrados,
    required this.consultasHoje,
    required this.filaVirtualAguardando,
  });
}

class _Consulta {
  final String nome;
  final String tipo;
  final String horario;
  final Color avatarColor;
  _Consulta(this.nome, this.tipo, this.horario, this.avatarColor);
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
