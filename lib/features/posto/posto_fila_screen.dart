import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/posto/posto_dashboard_screen.dart';
import '../../services/fila_service.dart';
import '../../core/animations/app_animations.dart';

class PostoFilaScreen extends StatefulWidget {
  const PostoFilaScreen({super.key});

  @override
  State<PostoFilaScreen> createState() => _PostoFilaScreenState();
}

class _PostoFilaScreenState extends State<PostoFilaScreen>
    with TickerProviderStateMixin {
  final _filaSvc = FilaService.instance;
  bool _loading = false;

  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: StreamBuilder<List<PacienteNaFila>>(
        stream: _filaSvc.streamFila(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (snap.hasError) {
            return _buildErrorState(snap.error.toString());
          }

          final fila = snap.data ?? [];
          final atual = fila
              .where((p) => p.status == StatusFila.emAtendimento)
              .firstOrNull;
          final espera = fila
              .where((p) => p.status == StatusFila.aguardando)
              .toList()
            ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));
          final atendidos = FilaService.atendidos(fila);

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildHeader(fila.length, atendidos, espera.length),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Coluna Central ──
                          Expanded(
                            flex: 6,
                            child: _buildCentralColumn(atual),
                          ),
                          const SizedBox(width: 16),
                          // ── Sidebar ──
                          SizedBox(
                            width: 320,
                            child: _buildSidebar(espera),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(fila, atendidos),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────── HEADER ───────────────

  Widget _buildHeader(int total, int atendidos, int aguardando) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              // Back button
              _HeaderIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pushReplacement(
                  AppFadeRoute(page: const PostoDashboardScreen()),
                ),
              ),
              const SizedBox(width: 14),
              // Título
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gerenciamento de Fila',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'UBS NOVO ORIENTE  •  PAINEL DE CONTROLE DE FLUXO',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Chips de status rápido
              _HeaderChip(
                  label: '$total',
                  sublabel: 'Total',
                  icon: Icons.group_rounded),
              const SizedBox(width: 8),
              _HeaderChip(
                  label: '$aguardando',
                  sublabel: 'Fila',
                  icon: Icons.hourglass_top_rounded),
              const SizedBox(width: 8),
              _HeaderChip(
                  label: '$atendidos',
                  sublabel: 'Atendidos',
                  icon: Icons.check_circle_rounded),
              const SizedBox(width: 12),
              // Simular btn
              _SimularButton(onPressed: _simular, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── CENTRAL ───────────────

  Widget _buildCentralColumn(PacienteNaFila? pac) {
    return Column(
      children: [
        // Card principal de senha
        Expanded(
          flex: 5,
          child: pac == null ? _buildEmptyCard() : _buildSenhaCard(pac),
        ),
        const SizedBox(height: 16),
        // Botões de ação
        _buildActionBar(pac),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSenhaCard(PacienteNaFila pac) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderDim),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Topo com gradiente (badge "chamando agora")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CHAMANDO AGORA',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Número da senha — DESTAQUE MÁXIMO
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        pac.senha,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 140,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeep,
                          letterSpacing: -6,
                          height: 0.95,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Linha divisória decorativa
                    Container(
                      height: 3,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome do paciente
                    Text(
                      pac.nome.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Especialidade
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        pac.especialidade,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info boxes — Consultório e Médico
                    Row(
                      children: [
                        Expanded(
                          child: _InfoBox(
                            icon: Icons.meeting_room_rounded,
                            label: 'CONSULTÓRIO',
                            value: '04',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoBox(
                            icon: Icons.person_rounded,
                            label: 'RESPONSÁVEL',
                            value: 'Dr. Ricardo Silva',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoBox(
                            icon: Icons.access_time_rounded,
                            label: 'HORA CHAMADA',
                            value: _formatHora(pac.horaChegada),
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgBase,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDim, width: 2),
            ),
            child: const Icon(Icons.sensors_rounded,
                size: 36, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),
          const Text(
            'AGUARDANDO PRÓXIMO PACIENTE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pressione "CHAMAR PRÓXIMO" para iniciar o atendimento',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(PacienteNaFila? pac) {
    return Row(
      children: [
        // FINALIZAR (só ativo se tem paciente)
        Expanded(
          child: _ActionButton(
            label: 'FINALIZAR ATENDIMENTO',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            enabled: pac != null && !_loading,
            onTap: pac != null ? () => _finalizar(pac) : null,
          ),
        ),
        const SizedBox(width: 12),
        // CHAMAR PRÓXIMO — destaque maior
        Expanded(
          flex: 2,
          child: _ActionButton(
            label: 'CHAMAR PRÓXIMO',
            icon: Icons.record_voice_over_rounded,
            color: AppColors.primary,
            enabled: !_loading,
            onTap: _proximo,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        // AUSÊNCIA
        Expanded(
          child: _ActionButton(
            label: 'REGISTRAR AUSÊNCIA',
            icon: Icons.person_off_rounded,
            color: AppColors.warning,
            enabled: pac != null && !_loading,
            onTap: pac != null ? () => _ausencia(pac) : null,
          ),
        ),
      ],
    );
  }

  // ─────────────── SIDEBAR ───────────────

  Widget _buildSidebar(List<PacienteNaFila> espera) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header sidebar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderDim)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.format_list_numbered_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRÓXIMOS DA FILA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Em ordem de chegada',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contador badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${espera.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: espera.isEmpty
                ? _buildSidebarEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: espera.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _QueueCard(
                      paciente: espera[i],
                      posicao: i + 1,
                      isNext: i == 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 36, color: AppColors.textTertiary),
          SizedBox(height: 10),
          Text(
            'Fila vazia',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Nenhum paciente aguardando',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── FOOTER ───────────────

  Widget _buildFooter(List<PacienteNaFila> fila, int atendidos) {
    final aguardando =
        fila.where((p) => p.status == StatusFila.aguardando).length;
    final emAtendimento =
        fila.where((p) => p.status == StatusFila.emAtendimento).length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FooterStat(
            icon: Icons.group_rounded,
            value: '${fila.length}',
            label: 'Total Hoje',
            color: AppColors.primary,
          ),
          _FooterDivider(),
          _FooterStat(
            icon: Icons.hourglass_top_rounded,
            value: '$aguardando',
            label: 'Aguardando',
            color: AppColors.warning,
          ),
          _FooterDivider(),
          _FooterStat(
            icon: Icons.medical_services_rounded,
            value: '$emAtendimento',
            label: 'Em Atendimento',
            color: AppColors.primary,
          ),
          _FooterDivider(),
          _FooterStat(
            icon: Icons.check_circle_rounded,
            value: '$atendidos',
            label: 'Atendidos',
            color: AppColors.success,
          ),
          _FooterDivider(),
          const _FooterStat(
            icon: Icons.timer_rounded,
            value: '12 min',
            label: 'Tempo Médio',
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ─────────────── ESTADOS DE LOADING/ERRO ───────────────

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Carregando fila...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Erro ao carregar fila',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 6),
              Text(error,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── HELPERS ───────────────

  String _formatHora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _simular() => _run(() => _filaSvc.simularNovoPaciente());
  void _proximo() => _run(() => _filaSvc.chamarProximo());
  void _finalizar(PacienteNaFila p) =>
      _run(() => _filaSvc.finalizarAtendimento(p.id));
  void _ausencia(PacienteNaFila p) =>
      _run(() => _filaSvc.atualizarStatus(p.id, StatusFila.ausente));
}

// ══════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;

  const _HeaderChip({
    required this.label,
    required this.sublabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: Colors.white70,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimularButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool loading;

  const _SimularButton({required this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'SIMULAR',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppColors.textTertiary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          gradient: isPrimary && enabled ? AppColors.primaryGradient : null,
          color: isPrimary && enabled
              ? null
              : enabled
                  ? effectiveColor.withOpacity(0.08)
                  : AppColors.bgBase,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled
                ? effectiveColor.withOpacity(isPrimary ? 0 : 0.3)
                : AppColors.borderDim,
          ),
          boxShadow: isPrimary && enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary && enabled ? Colors.white : effectiveColor,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPrimary && enabled ? Colors.white : effectiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final PacienteNaFila paciente;
  final int posicao;
  final bool isNext;

  const _QueueCard({
    required this.paciente,
    required this.posicao,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isNext ? AppColors.primaryGradient : null,
        color: isNext ? null : AppColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext ? Colors.transparent : AppColors.borderDim,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Posição / senha
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isNext
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  paciente.senha,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isNext ? Colors.white : AppColors.primaryDeep,
                  ),
                ),
                Text(
                  '#$posicao',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isNext ? Colors.white60 : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente.nome,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isNext ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  paciente.especialidade.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isNext ? Colors.white70 : AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // "PRÓXIMO" badge ou hora
          if (isNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRÓXIMO',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Text(
              '${paciente.horaChegada.hour.toString().padLeft(2, '0')}:${paciente.horaChegada.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _FooterStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color == AppColors.textSecondary
                    ? AppColors.textPrimary
                    : color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.borderDim,
    );
  }
}
