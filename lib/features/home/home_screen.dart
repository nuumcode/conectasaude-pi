// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
// ─────────────────────────────────────────────────────────────
//  HomeScreen — Tela principal após login
//  Exibe menu baseado no tipo de usuário (cidadão/posto/secretaria)
//  TODO: conectar Firebase Auth para detectar role do usuário
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  // Mock — substituir por role do Firebase Auth custom claims
  String _tipoUsuario = 'cidadao'; // cidadao | posto | secretaria
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildLogo(),
        actions: [
          // Troca de perfil (apenas para demo/hackathon)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz, color: Colors.white38),
            color: const Color(0xFF0F1B3D),
            onSelected: (v) => setState(() => _tipoUsuario = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cidadao', child: Text('Cidadão', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'posto', child: Text('Posto', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'secretaria', child: Text('Secretaria', style: TextStyle(color: Colors.white))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white38),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saudação
              _buildSaudacao(),
              const SizedBox(height: 28),
              // Menu baseado no tipo
              if (_tipoUsuario == 'cidadao') _buildMenuCidadao(),
              if (_tipoUsuario == 'posto') _buildMenuPosto(),
              if (_tipoUsuario == 'secretaria') _buildMenuSecretaria(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLogo() {
    return RichText(
      text: TextSpan(children: [
        const TextSpan(
            text: 'Conecta',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            )),
        TextSpan(
            text: 'Saúde',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.blueLt,
            )),
        TextSpan(
            text: 'PI',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.greenLt,
            )),
      ]),
    );
  }
  Widget _buildSaudacao() {
    final perfil = switch (_tipoUsuario) {
      'cidadao' => ('Olá, Cidadão!', 'O que você precisa hoje?', Icons.person_outline),
      'posto' => ('Painel do Posto', 'UBS Vila Esperança', Icons.local_hospital_outlined),
      'secretaria' => ('Secretaria de Saúde', 'Prefeitura de Teresina', Icons.account_balance_outlined),
      _ => ('', '', Icons.home),
    };
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.blue.withOpacity(0.4), AppColors.blueLt.withOpacity(0.2)],
            ),
          ),
          child: Icon(perfil.$3, color: AppColors.blueLt, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(perfil.$1,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
            Text(perfil.$2,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                )),
          ],
        ),
      ],
    );
  }
  // ── Menu Cidadão ───────────────────────────────────────────
  Widget _buildMenuCidadao() {
    return Column(
      children: [
        _menuCard(
          'Fila Virtual',
          'Acompanhe sua posição em tempo real',
          Icons.queue,
          AppColors.greenLt,
          () => Navigator.pushNamed(context, '/cidadao/fila'),
        ),
        _menuCard(
          'Escala de Atendimento',
          'Veja os profissionais disponíveis',
          Icons.calendar_month_outlined,
          AppColors.blueLt,
          () => Navigator.pushNamed(context, '/cidadao/escala'),
        ),
        _menuCard(
          'Meus Agendamentos',
          'Consultas e exames marcados',
          Icons.event_note_outlined,
          const Color(0xFFFFA726),
          () {}, // TODO
        ),
        _menuCard(
          'Unidades Próximas',
          'Encontre a UBS mais perto de você',
          Icons.location_on_outlined,
          const Color(0xFF9C27B0),
          () {}, // TODO
        ),
      ],
    );
  }
  // ── Menu Posto ─────────────────────────────────────────────
  Widget _buildMenuPosto() {
    return Column(
      children: [
        _menuCard(
          'Gerenciar Fila',
          'Veja e gerencie pacientes na fila',
          Icons.format_list_numbered_rounded,
          AppColors.greenLt,
          () => Navigator.pushNamed(context, '/posto/fila'),
        ),
        _menuCard(
          'Painel de Chamada',
          'Tela de display para chamar pacientes',
          Icons.campaign_rounded,
          AppColors.blueLt,
          () => Navigator.pushNamed(context, '/posto/chamar'),
        ),
        _menuCard(
          'Ausências',
          'Gerencie pacientes que não compareceram',
          Icons.person_off_outlined,
          const Color(0xFFEF5350),
          () => Navigator.pushNamed(context, '/posto/ausencia'),
        ),
        _menuCard(
          'Escala do Posto',
          'Profissionais escalados esta semana',
          Icons.calendar_today_outlined,
          const Color(0xFFFFA726),
          () {}, // TODO
        ),
      ],
    );
  }
  // ── Menu Secretaria ────────────────────────────────────────
  Widget _buildMenuSecretaria() {
    return Column(
      children: [
        _menuCard(
          'Dashboard',
          'Visão geral de todas as unidades',
          Icons.dashboard_outlined,
          AppColors.blueLt,
          () => Navigator.pushNamed(context, '/secretaria/dashboard'),
        ),
        _menuCard(
          'Gestão de Escalas',
          'Gerencie escalas de todas as UBS',
          Icons.event_available_outlined,
          AppColors.greenLt,
          () => Navigator.pushNamed(context, '/secretaria/escala'),
        ),
        _menuCard(
          'Relatórios',
          'Indicadores e métricas detalhadas',
          Icons.bar_chart_rounded,
          const Color(0xFFFFA726),
          () {}, // TODO
        ),
        _menuCard(
          'Notificações',
          'Alertas e avisos do sistema',
          Icons.notifications_outlined,
          const Color(0xFF9C27B0),
          () {}, // TODO
        ),
      ],
    );
  }
  Widget _menuCard(String titulo, String subtitulo, IconData icon, Color cor,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B3D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
