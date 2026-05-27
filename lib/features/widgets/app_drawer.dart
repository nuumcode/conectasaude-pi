// ═══════════════════════════════════════════════════════════════════
//  app_drawer.dart  —  ConectaSaúdePI
//  Drawer reutilizável (mobile: Scaffold.drawer / desktop: fixo)
//
//  ✅ Enum DrawerAba estendido — cada item tem aba própria
//  ✅ Os 5 primeiros valores mantêm alinhamento de índice com _Aba
//     do HomeCidadaoScreen (compatibilidade com dashboard).
//  ✅ Novo: item "Meu Perfil" (DrawerAba.perfil) na seção CONTA
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

// ⚠️ Os 5 primeiros valores DEVEM permanecer alinhados com _Aba do
// HomeCidadaoScreen (inicio, agendamentos, prontuarios, mensagens, mais).
// Novos valores devem ser adicionados ao final.
enum UserRole { cidadao, secretaria, posto }

enum DrawerAba {
  // Comuns/Cidadão
  inicio,
  agendamentos,
  prontuarios,
  mensagens,
  mais,
  vacinacao,
  fila,
  notificacoes,
  emergencia,
  perfil,

  // Secretaria (Admin)
  usuarios,
  medicos,
  escalas,
  logs,
  configuracoes,
  relatorios,

  // Posto
  chamar,
  ausencia,
}

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userPhoto;
  final dynamic abaAtual;
  final void Function(dynamic) onAbaChanged;
  final VoidCallback onLogout;
  final bool isFixed;
  final UserRole role;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhoto,
    required this.abaAtual,
    required this.onAbaChanged,
    required this.onLogout,
    this.isFixed = false,
    this.role = UserRole.cidadao,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      shape: isFixed
          ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(0),
            )),
      child: Column(children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: role == UserRole.cidadao
                  ? _buildCidadaoItems(context)
                  : role == UserRole.secretaria
                      ? _buildSecretariaItems(context)
                      : _buildPostoItems(context),
            ),
          ),
        ),
        _buildFooter(context),
      ]),
    );
  }

  List<Widget> _buildCidadaoItems(BuildContext context) {
    return [
      _buildSectionLabel('PRINCIPAL'),
      _buildItem(
        context,
        icon: Icons.home_rounded,
        label: 'Início',
        aba: DrawerAba.inicio,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('SAÚDE'),
      _buildItem(
        context,
        icon: Icons.calendar_today_rounded,
        label: 'Escala/Agendamentos',
        aba: DrawerAba.agendamentos,
      ),
      _buildItem(
        context,
        icon: Icons.groups_rounded,
        label: 'Fila Virtual',
        aba: DrawerAba.fila,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('COMUNICAÇÃO'),
      _buildItem(
        context,
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Mensagens',
        aba: DrawerAba.mensagens,
        badge: 2,
      ),
      _buildItem(
        context,
        icon: Icons.notifications_none_rounded,
        label: 'Notificações',
        aba: DrawerAba.notificacoes,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('CONTA'),
      _buildItem(
        context,
        icon: Icons.person_outline_rounded,
        label: 'Meu Perfil',
        aba: DrawerAba.perfil,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('EMERGÊNCIA'),
      _buildItem(
        context,
        icon: Icons.emergency_rounded,
        label: 'Emergência',
        aba: DrawerAba.emergencia,
        isEmergency: true,
      ),
    ];
  }

  List<Widget> _buildSecretariaItems(BuildContext context) {
    return [
      _buildSectionLabel('ADMINISTRAÇÃO'),
      _buildItem(
        context,
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        aba: DrawerAba.inicio,
      ),
      _buildItem(
        context,
        icon: Icons.manage_accounts_rounded,
        label: 'Gestão de Usuários',
        aba: DrawerAba.usuarios,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('GERENCIAMENTO'),
      _buildItem(
        context,
        icon: Icons.medical_services_rounded,
        label: 'Médicos',
        aba: DrawerAba.medicos,
      ),
      _buildItem(
        context,
        icon: Icons.calendar_month_rounded,
        label: 'Escalas',
        aba: DrawerAba.escalas,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('SISTEMA'),
      _buildItem(
        context,
        icon: Icons.analytics_rounded,
        label: 'Relatórios',
        aba: DrawerAba.relatorios,
      ),
      _buildItem(
        context,
        icon: Icons.history_rounded,
        label: 'Logs de Atividade',
        aba: DrawerAba.logs,
      ),
      _buildItem(
        context,
        icon: Icons.settings_rounded,
        label: 'Configurações',
        aba: DrawerAba.configuracoes,
      ),
    ];
  }

  List<Widget> _buildPostoItems(BuildContext context) {
    return [
      _buildSectionLabel('ATENDIMENTO'),
      _buildItem(
        context,
        icon: Icons.home_rounded,
        label: 'Início',
        aba: DrawerAba.inicio,
      ),
      _buildItem(
        context,
        icon: Icons.record_voice_over_rounded,
        label: 'Chamar Paciente',
        aba: DrawerAba.chamar,
      ),
      _buildItem(
        context,
        icon: Icons.person_off_rounded,
        label: 'Registrar Ausência',
        aba: DrawerAba.ausencia,
      ),
      _buildItem(
        context,
        icon: Icons.groups_rounded,
        label: 'Fila do Posto',
        aba: DrawerAba.fila,
      ),
      const SizedBox(height: 16),
      _buildSectionLabel('EMERGÊNCIA'),
      _buildItem(
        context,
        icon: Icons.emergency_rounded,
        label: 'Chamadas SOS',
        aba: DrawerAba.emergencia,
        isEmergency: true,
      ),
    ];
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(children: [
        Hero(
          tag: 'brand-logo-drawer',
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2B6B), AppColors.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.35), blurRadius: 12),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo-var01.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    CustomPaint(painter: CrossEcgPainter()),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  const TextSpan(
                    text: 'Conecta',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Saúde',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blueLt,
                        shadows: [
                          Shadow(
                              color: AppColors.blueLt.withOpacity(0.4),
                              blurRadius: 8)
                        ]),
                  ),
                  TextSpan(
                    text: 'PI',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenLt,
                        shadows: [
                          Shadow(
                              color: AppColors.greenLt.withOpacity(0.4),
                              blurRadius: 8)
                        ]),
                  ),
                ]),
              ),
              Text(
                'Sua saúde conectada.',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.45)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 1.8)),
      );
  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DrawerAba aba,
    int badge = 0,
    bool isEmergency = false,
  }) {
    final selected = abaAtual.index == aba.index;
    final fg = selected
        ? AppColors.bgBase
        : isEmergency
            ? const Color(0xFFFF6B6B)
            : Colors.white;
    final bg = selected
        ? Colors.white
        : isEmergency
            ? const Color(0xFFFF6B6B).withOpacity(0.10)
            : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // ✅ Fecha o drawer ANTES de navegar — evita pop indevido
            // de uma rota recém-empurrada por pushReplacement.
            if (!isFixed && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            onAbaChanged(aba);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg)),
              ),
              if (badge > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgMid.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryDeep,
          backgroundImage: userPhoto != null ? NetworkImage(userPhoto!) : null,
          child: userPhoto == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis),
              Text(userEmail,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.55)),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          onPressed: onLogout,
          tooltip: 'Sair',
          icon: Icon(Icons.logout_rounded,
              color: Colors.white.withOpacity(0.6), size: 20),
        ),
      ]),
    );
  }
}
