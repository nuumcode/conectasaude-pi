import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum UserRole { cidadao, secretaria, posto }

enum DrawerAba {
  inicio,
  agendamentos,
  fila,
  emergencia,
  perfil,
  mensagens,
  vacinacao,
  prontuarios,
  notificacoes,
  medicos,
  escala,
  posto,
  configuracoes,
  mais,
  chamar,
  ausencia
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
    final drawer = Drawer(
      backgroundColor: AppColors.navyDeep,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
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

    return isFixed ? drawer : drawer;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(children: [
        Hero(
          tag: 'brand-logo-drawer',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ConectaSaúde',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Teresina • PI',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildCidadaoItems(BuildContext context) {
    return [
      _buildSectionLabel('MENU PRINCIPAL'),
      _buildItem(
        context,
        icon: Icons.home_rounded,
        label: 'Início',
        aba: DrawerAba.inicio,
      ),
      _buildItem(
        context,
        icon: Icons.calendar_today_rounded,
        label: 'Agendamentos',
        aba: DrawerAba.agendamentos,
      ),
      _buildItem(
        context,
        icon: Icons.groups_rounded,
        label: 'Fila Virtual',
        aba: DrawerAba.fila,
      ),
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
      _buildSectionLabel('DASHBOARD'),
      _buildItem(
        context,
        icon: Icons.analytics_rounded,
        label: 'Painel Geral',
        aba: DrawerAba.inicio,
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
        icon: Icons.event_note_rounded,
        label: 'Escalas',
        aba: DrawerAba.escala,
      ),
      _buildItem(
        context,
        icon: Icons.local_hospital_rounded,
        label: 'Postos de Saúde',
        aba: DrawerAba.posto,
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white24,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required dynamic aba,
    bool isEmergency = false,
  }) {
    final isSelected = abaAtual == aba;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () {
          if (!isFixed) Navigator.pop(context);
          onAbaChanged(aba);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isEmergency
                    ? AppColors.error.withOpacity(0.15)
                    : Colors.white.withOpacity(0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isEmergency ? AppColors.error : Colors.white)
                  : Colors.white54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isEmergency ? AppColors.error : Colors.white)
                      : Colors.white54,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isEmergency ? AppColors.error : AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: ClipOval(
            child: userPhoto != null
                ? Image.network(userPhoto!, fit: BoxFit.cover)
                : const Icon(Icons.person_rounded,
                    color: Colors.white38, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                userEmail,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white38,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onLogout,
          tooltip: 'Sair',
          icon: const Icon(Icons.logout_rounded,
              color: Colors.white38, size: 20),
        ),
      ]),
    );
  }
}
