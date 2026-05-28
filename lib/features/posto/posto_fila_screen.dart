import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/theme/app_theme.dart';
import '../../features/posto/posto_dashboard_screen.dart';
import '/services/fila_service.dart';
import '../../core/animations/app_animations.dart';

class PostoFilaScreen extends StatefulWidget {
  const PostoFilaScreen({super.key});

  @override
  State<PostoFilaScreen> createState() => _PostoFilaScreenState();
}

class _PostoFilaScreenState extends State<PostoFilaScreen> {
  final _filaSvc = FilaService.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
  }

  PacienteNaFila? _pacienteAtual(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.emAtendimento).firstOrNull;

  List<PacienteNaFila> _filaEspera(List<PacienteNaFila> fila) =>
      fila
          .where((p) => p.status == StatusFila.aguardando)
          .toList()
        ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: StreamBuilder<List<PacienteNaFila>>(
          stream: _filaSvc.streamFila(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final fila = snap.data ?? const <PacienteNaFila>[];

            return Column(
              children: [
                _buildModernHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: isWide
                            ? _buildWideLayout(fila)
                            : _buildNarrowLayout(fila),
                      ),
                    ),
                  ),
                ),
                _buildStatsFooter(fila),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderDim)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pushReplacement(AppFadeRoute(page: const PostoDashboardScreen())),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTROLE DE FLUXO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2),
              ),
              Text(
                'UBS Novo Oriente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 600)
            const _HeaderClock(),
          const SizedBox(width: 16),
          _btnHeaderSimular(),
        ],
      ),
    );
  }

  Widget _btnHeaderSimular() {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _simularPaciente,
      icon: const Icon(Icons.person_add_rounded, size: 18),
      label: const Text('SIMULAR PACIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceDim,
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.borderDim)),
      ),
    );
  }

  Widget _buildWideLayout(List<PacienteNaFila> fila) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildMainControlArea(fila)),
        const SizedBox(width: 24),
        Expanded(flex: 4, child: _buildQueueSideArea(fila)),
      ],
    );
  }

  Widget _buildNarrowLayout(List<PacienteNaFila> fila) {
    return Column(
      children: [
        _buildMainControlArea(fila),
        const SizedBox(height: 24),
        _buildQueueSideArea(fila),
      ],
    );
  }

  Widget _buildMainControlArea(List<PacienteNaFila> fila) {
    final pac = _pacienteAtual(fila);

    return Column(
      children: [
        _buildCurrentPatientCard(pac),
        const SizedBox(height: 24),
        _buildActionPanel(pac),
      ],
    );
  }

  Widget _buildCurrentPatientCard(PacienteNaFila? pac) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: pac != null ? AppColors.primary.withOpacity(0.2) : AppColors.borderDim),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: pac == null 
          ? _buildEmptyState()
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                      child: const Row(
                        children: [
                          Icon(Icons.record_voice_over_rounded, size: 14, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('EM ATENDIMENTO', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  pac.senha,
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -2),
                ),
                Text(
                  pac.nome.toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  pac.especialidade,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceDim, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _cardInfoItem(Icons.access_time_rounded, 'CHEGADA', pac.horaFormatada),
                      _cardDivider(),
                      _cardInfoItem(Icons.person_outline_rounded, 'MÉDICO', 'Dr. Ricardo Silva'),
                      _cardDivider(),
                      _cardInfoItem(Icons.room_rounded, 'SALA', 'CONSULTÓRIO 04'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      children: [
        Icon(Icons.person_search_rounded, size: 48, color: AppColors.textTertiary),
        SizedBox(height: 16),
        Text('Aguardando Próximo Paciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        Text('Chame o próximo na fila para iniciar o atendimento.', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _cardInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _cardDivider() => Container(width: 1, height: 30, color: AppColors.borderDim);

  Widget _buildActionPanel(PacienteNaFila? pac) {
    return Row(
      children: [
        if (pac != null) ...[
          Expanded(
            child: _actionBtn(
              onTap: () => _finalizarAtendimento(pac),
              icon: Icons.check_circle_rounded,
              label: 'FINALIZAR',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionBtn(
              onTap: () => _registrarAusencia(pac),
              icon: Icons.person_off_rounded,
              label: 'AUSENTE',
              color: AppColors.error,
              isOutline: true,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: _actionBtn(
            onTap: _chamarProximo,
            icon: Icons.skip_next_rounded,
            label: 'CHAMAR PRÓXIMO',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({required VoidCallback onTap, required IconData icon, required String label, required Color color, bool isOutline = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutline ? Border.all(color: color, width: 2) : null,
          boxShadow: isOutline ? null : [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isOutline ? color : Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isOutline ? color : Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSideArea(List<PacienteNaFila> fila) {
    final espera = _filaEspera(fila);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('FILA DE ESPERA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceDim, borderRadius: BorderRadius.circular(8)),
                child: Text('${espera.length} aguardando', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (espera.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('Nenhum paciente na fila', style: TextStyle(color: AppColors.textTertiary))))
          else
            ...espera.asMap().entries.map((e) => _buildQueueItem(e.value, e.key + 1)),
        ],
      ),
    );
  }

  Widget _buildQueueItem(PacienteNaFila pac, int pos) {
    final isPreferencial = pac.senha.startsWith('P');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPreferencial ? AppColors.warning.withOpacity(0.05) : AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPreferencial ? AppColors.warning.withOpacity(0.2) : Colors.transparent),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isPreferencial ? AppColors.warning : AppColors.primary.withOpacity(0.1),
            child: Text('$pos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPreferencial ? Colors.white : AppColors.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pac.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                Text(pac.especialidade, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.borderDim)),
            child: Text(pac.senha, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsFooter(List<PacienteNaFila> fila) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderDim)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.people_rounded, '${fila.length}', 'TOTAL'),
          _statItem(Icons.check_circle_rounded, '${FilaService.atendidos(fila)}', 'CONCLUÍDOS'),
          _statItem(Icons.timer_rounded, '12m', 'T.M.A'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textTertiary, letterSpacing: 1)),
          ],
        ),
      ],
    );
  }

  // Ações do sistema
  Future<void> _runAction(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try { await action(); } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _simularPaciente() => _runAction(() async {
        await _filaSvc.simularNovoPaciente();
        _showSnack('Novo paciente adicionado', AppColors.primary);
      });

  Future<void> _chamarProximo() => _runAction(() async {
        final proximo = await _filaSvc.chamarProximo();
        if (proximo == null) {
          _showSnack('Nenhum paciente aguardando', AppColors.warning);
        } else {
          _showSnack('Chamando: ${proximo.nome}', AppColors.success);
        }
      });

  Future<void> _finalizarAtendimento(PacienteNaFila pac) => _runAction(() async {
        await _filaSvc.finalizarAtendimento(pac.id);
        _showSnack('Atendimento finalizado', AppColors.success);
      });

  Future<void> _registrarAusencia(PacienteNaFila pac) => _runAction(() async {
        await _filaSvc.atualizarStatus(pac.id, StatusFila.ausente);
        _showSnack('Paciente marcado como ausente', AppColors.error);
      });

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
}

class _HeaderClock extends StatefulWidget {
  const _HeaderClock();
  @override
  State<_HeaderClock> createState() => _HeaderClockState();
}

class _HeaderClockState extends State<_HeaderClock> {
  late DateTime _agora = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
      child: Text(DateFormat('HH:mm:ss').format(_agora), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
    );
  }
}
