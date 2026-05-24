import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  PostoChamarScreen — Painel do Profissional de Saúde
//  Dashboard com resumo do dia, ações rápidas e próximas consultas
//  TODO: conectar Firestore para dados reais
// ─────────────────────────────────────────────────────────────
class PostoChamarScreen extends StatefulWidget {
  const PostoChamarScreen({super.key});
  @override
  State<PostoChamarScreen> createState() => _PostoChamarScreenState();
}

class _PostoChamarScreenState extends State<PostoChamarScreen> {
  int _navIndex = 0;
  // Cores auxiliares tema claro
  static const _bgMain = Color(0xFFF0F5FC);
  static const _textDark = Color(0xFF1A2138);
  static const _textMuted = Color(0xFF7B8794);
  static const _dividerColor = Color(0xFFE8EEF5);
  static const _cardShadow = Color(0x0A000000);
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
    _Consulta('Maria Oliveira', 'Consulta presencial', '08:30',
        const Color(0xFF4A9FFF)),
    _Consulta('Carlos Mendes', 'Consulta', '09:15', const Color(0xFF00B894)),
    _Consulta('Ana Paula Santos', 'Consulta presencial', '10:00',
        const Color(0xFF9B59B6)),
    _Consulta('João Pereira', 'Consulta presencial', '10:45',
        const Color(0xFFE67E22)),
    _Consulta('Fernanda Lima', 'Consulta presencial', '11:30',
        const Color(0xFF1A72FF)),
  ];
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isSmall = screenW < 360;
    return Scaffold(
      backgroundColor: _bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isSmall),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isSmall ? 20 : 24),
                    _buildResumoSection(isSmall),
                    SizedBox(height: isSmall ? 22 : 28),
                    _buildAcoesRapidas(isSmall),
                    SizedBox(height: isSmall ? 22 : 28),
                    _buildProximasConsultas(isSmall),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isSmall),
    );
  }

  // ── Header com avatar e info do profissional ───────────────
  Widget _buildHeader(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmall ? 14 : 20,
        isSmall ? 16 : 20,
        isSmall ? 14 : 20,
        isSmall ? 18 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyMid, AppColors.navyDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: isSmall ? 52 : 60,
            height: isSmall ? 52 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.blueLt.withOpacity(0.3),
                  AppColors.blue.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.blueLt.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: isSmall ? 28 : 32,
              color: AppColors.blueLt,
            ),
          ),
          SizedBox(width: isSmall ? 12 : 16),
          // Nome + especialidade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profissional.nome,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmall ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      _profissional.especialidade,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isSmall ? 12 : 13,
                        color: AppColors.blueLt,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notificação
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Resumo do dia ──────────────────────────────────────────
  Widget _buildResumoSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Resumo do dia',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                )),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: _textMuted),
                const SizedBox(width: 6),
                Text(
                  _getDataHoje(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmall ? 11 : 12,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: isSmall ? 12 : 16),
        // Cards de stats
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 3;
            return Row(
              children: [
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.blue,
                  iconBg: AppColors.blue.withOpacity(0.1),
                  valor: '${_resumo.pacientesCadastrados}',
                  label: 'Pacientes',
                  sublabel: 'Cadastrados',
                  isSmall: isSmall,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.event_note_rounded,
                  iconColor: AppColors.accent,
                  iconBg: AppColors.accent.withOpacity(0.1),
                  valor: '${_resumo.consultasHoje}',
                  label: 'Consultas Hoje',
                  sublabel: 'Agendadas',
                  isSmall: isSmall,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.blueLt,
                  iconBg: AppColors.blueLt.withOpacity(0.1),
                  valor: '${_resumo.filaVirtualAguardando}',
                  label: 'Fila Virtual',
                  sublabel: 'Aguardando',
                  isSmall: isSmall,
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
    required bool isSmall,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 14 : 18,
          horizontal: isSmall ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: isSmall ? 36 : 42,
              height: isSmall ? 36 : 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: isSmall ? 18 : 22, color: iconColor),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Text(
              valor,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 22 : 26,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 10 : 11,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 9 : 10,
                color: _textMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ações rápidas ──────────────────────────────────────────
  Widget _buildAcoesRapidas(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações rápidas',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
        SizedBox(height: isSmall ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: _buildAcaoBtn(
                icon: Icons.people_outline_rounded,
                label: 'Ver Pacientes',
                sublabel: 'Acessar lista',
                color: AppColors.blue,
                isSmall: isSmall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAcaoBtn(
                icon: Icons.queue_rounded,
                label: 'Fila Virtual',
                sublabel: 'Ver fila atual',
                color: AppColors.accent,
                isSmall: isSmall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAcaoBtn(
                icon: Icons.chat_outlined,
                label: 'Mensagens',
                sublabel: 'Ver conversas',
                color: AppColors.blueLt,
                isSmall: isSmall,
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
    required bool isSmall,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 14 : 16,
        horizontal: isSmall ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dividerColor),
        boxShadow: [
          BoxShadow(
            color: _cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isSmall ? 34 : 40,
            height: isSmall ? 34 : 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: isSmall ? 18 : 20, color: color),
          ),
          SizedBox(height: isSmall ? 8 : 10),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: _textDark,
              )),
          const SizedBox(height: 2),
          Text(sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 8 : 9,
                color: _textMuted,
              )),
        ],
      ),
    );
  }

  // ── Próximas consultas ─────────────────────────────────────
  Widget _buildProximasConsultas(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Próximas consultas',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                )),
            GestureDetector(
              onTap: () {},
              child: Text('Ver agenda completa >',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  )),
            ),
          ],
        ),
        SizedBox(height: isSmall ? 12 : 14),
        ...List.generate(_consultas.length, (i) {
          final consulta = _consultas[i];
          return _buildConsultaItem(
              consulta, isSmall, i == _consultas.length - 1);
        }),
      ],
    );
  }

  Widget _buildConsultaItem(_Consulta consulta, bool isSmall, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 12 : 14,
        horizontal: isSmall ? 12 : 14,
      ),
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
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: _dividerColor.withOpacity(0.6), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: isSmall ? 38 : 44,
            height: isSmall ? 38 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: consulta.avatarColor.withOpacity(0.1),
              border: Border.all(
                color: consulta.avatarColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.person_rounded,
                size: isSmall ? 20 : 22, color: consulta.avatarColor),
          ),
          SizedBox(width: isSmall ? 10 : 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consulta.nome,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 12, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(consulta.tipo,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSmall ? 10 : 11,
                          color: _textMuted,
                        )),
                  ],
                ),
              ],
            ),
          ),
          // Horário
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 10 : 12,
              vertical: isSmall ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(consulta.horario,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                )),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ──────────────────────────────────
  Widget _buildBottomNav(bool isSmall) {
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
                    size: isSmall ? 22 : 24,
                    color: selected ? AppColors.blue : _textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 9 : 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.blue : _textMuted,
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
