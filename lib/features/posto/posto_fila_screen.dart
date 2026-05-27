// lib/features/posto/posto_fila_screen.dart
//
// Tela do posto — gerencia a fila virtual em tempo real via Firestore.
// Header com gradiente, card de paciente atual, fila ao vivo lateral e
// stats inferiores.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/theme/app_theme.dart';
import '/services/fila_service.dart';

class PostoFilaScreen extends StatefulWidget {
  const PostoFilaScreen({super.key});

  @override
  State<PostoFilaScreen> createState() => _PostoFilaScreenState();
}

class _PostoFilaScreenState extends State<PostoFilaScreen> {
  final _filaSvc = FilaService.instance;

  // Controla se uma ação assíncrona está em curso — desabilita botões.
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
  }

  // ── Helpers derivados do snapshot ──────────────────────────

  PacienteNaFila? _pacienteAtual(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.emAtendimento).firstOrNull;

  List<PacienteNaFila> _filaEspera(List<PacienteNaFila> fila) =>
      fila
          .where((p) => p.status == StatusFila.aguardando)
          .toList()
        ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 768;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: StreamBuilder<List<PacienteNaFila>>(
          stream: _filaSvc.streamFila(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(
                    'Erro ao carregar a fila:\n\n${snap.error}',
                    style:
                        const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final fila = snap.data ?? const <PacienteNaFila>[];

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isWide
                      ? _buildWideLayout(fila)
                      : _buildNarrowLayout(fila),
                ),
                _buildBottomStats(fila),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    final dateStr = DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR')
        .format(DateTime.now());

    final user = FirebaseAuth.instance.currentUser;
    final String nome;
    if (user == null) {
      nome = 'Atendente';
    } else if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      nome = user.displayName!.trim();
    } else if (user.email != null && user.email!.isNotEmpty) {
      nome = user.email!.split('@').first;
    } else {
      nome = 'Atendente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bem-vindo, $nome',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Consultório 01',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Simular novo paciente',
            icon: const Icon(Icons.person_add_outlined,
                color: Colors.white, size: 22),
            onPressed: _loading ? null : _simularPaciente,
          ),
          const SizedBox(width: 8),
          const _LiveClock(),
        ],
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────

  Widget _buildWideLayout(List<PacienteNaFila> fila) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildPacienteAtualCard(fila)),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _buildFilaAoVivo(fila)),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(List<PacienteNaFila> fila) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPacienteAtualCard(fila),
          const SizedBox(height: 16),
          SizedBox(height: 400, child: _buildFilaAoVivo(fila)),
        ],
      ),
    );
  }

  // ── Card do paciente atual ─────────────────────────────────

  Widget _buildPacienteAtualCard(List<PacienteNaFila> fila) {
    final pac = _pacienteAtual(fila);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: pac != null ? AppColors.primary : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PACIENTE ATUAL',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: pac != null ? AppColors.primary : AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pac != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSenhaGrande(pac.senha),
                const SizedBox(width: 24),
                Expanded(child: _buildPacienteInfo(pac)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderDim, height: 1),
            const SizedBox(height: 24),
            _buildActionButtons(pac),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Nenhum paciente em atendimento',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderDim, height: 1),
            const SizedBox(height: 24),
            _buildActionButtons(null),
          ],
        ],
      ),
    );
  }

  Widget _buildSenhaGrande(String senha) {
    return Column(
      children: [
        const Text(
          'SENHA',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Text(
            senha,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacienteInfo(PacienteNaFila pac) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pac.nome,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (pac.cpf != null)
          _infoRow(Icons.badge_outlined, 'CPF: ${pac.cpf}'),
        if (pac.sus != null)
          _infoRow(Icons.local_hospital_outlined, 'SUS: ${pac.sus}'),
        _infoRow(Icons.medical_services_outlined, pac.especialidade),
        const SizedBox(height: 12),
        Row(
          children: [
            _timeChip(Icons.schedule, pac.horaFormatada, 'Chegada'),
            const SizedBox(width: 12),
            _timeChip(
                Icons.campaign_outlined, pac.senhaComNome, 'Chamada'),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeChip(IconData icon, String time, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Botões de ação ─────────────────────────────────────────

  Widget _buildActionButtons(PacienteNaFila? pacAtual) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return AbsorbPointer(
          absorbing: _loading,
          child: Column(
            children: [
              SizedBox(
                height: 4,
                child: _loading
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (pacAtual != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _finalizarAtendimento(pacAtual),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      isCompact ? 'FINALIZAR' : 'FINALIZAR ATENDIMENTO',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _chamarProximo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.campaign_rounded, size: 20),
                      label: Text(
                        isCompact ? 'CHAMAR' : 'CHAMAR PRÓXIMO',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: pacAtual == null
                          ? null
                          : () => _registrarAusencia(pacAtual),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        disabledForegroundColor: AppColors.borderMid,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: pacAtual != null
                              ? AppColors.error.withOpacity(0.3)
                              : AppColors.borderDim,
                        ),
                      ),
                      icon: const Icon(Icons.person_off_outlined, size: 20),
                      label: Text(
                        isCompact ? 'AUSÊNCIA' : 'REGISTRAR AUSÊNCIA',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Fila ao vivo ───────────────────────────────────────────

  Widget _buildFilaAoVivo(List<PacienteNaFila> fila) {
    final espera = _filaEspera(fila);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.queue_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'FILA AO VIVO',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${espera.length} na fila',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDim),
          Expanded(
            child: espera.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum paciente aguardando',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: espera.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: AppColors.surfaceDim,
                    ),
                    itemBuilder: (_, i) => _buildFilaItem(espera[i], i + 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaItem(PacienteNaFila pac, int posicao) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                pac.senha,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pac.nome,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${pac.especialidade} • ${pac.horaFormatada}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Aguardando',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats inferiores ───────────────────────────────────────

  Widget _buildBottomStats(List<PacienteNaFila> fila) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppColors.borderDim, width: 1)),
      ),
      child: Row(
        children: [
          _statItem(Icons.person_rounded,
              '${FilaService.emAtendimento(fila)}', 'Em atendimento', AppColors.primary),
          _statDivider(),
          _statItem(Icons.schedule_rounded,
              '${FilaService.aguardando(fila)}', 'Aguardando', AppColors.warning),
          _statDivider(),
          _statItem(Icons.check_circle_rounded,
              '${FilaService.atendidos(fila)}', 'Atendidos', AppColors.success),
          _statDivider(),
          _statItem(Icons.groups_rounded, '${fila.length}',
              'Fila completa', AppColors.primary),
        ],
      ),
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
        width: 1, height: 30, color: AppColors.borderDim);
  }

  // ── Ações ──────────────────────────────────────────────────

  Future<void> _runAction(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simularPaciente() => _runAction(() async {
        await _filaSvc.simularNovoPaciente();
        if (!mounted) return;
        _showSnack('Novo paciente adicionado à fila', AppColors.primary);
      });

  Future<void> _chamarProximo() => _runAction(() async {
        try {
          final proximo = await _filaSvc.chamarProximo();
          if (!mounted) return;
          if (proximo == null) {
            _showSnack('Nenhum paciente aguardando na fila', AppColors.primary);
            return;
          }
          _showSnack(
              'Chamando: ${proximo.nome} (${proximo.senha})', AppColors.success);
        } on ConflitoChamadaException {
          if (!mounted) return;
          _showSnack(
              'Outro atendente chamou este paciente. Tente novamente.',
              AppColors.warning);
        }
      });

  Future<void> _finalizarAtendimento(PacienteNaFila pac) =>
      _runAction(() async {
        await _filaSvc.finalizarAtendimento(pac.id);
        if (!mounted) return;
        _showSnack(
            '${pac.nome} (${pac.senha}) — atendimento finalizado',
            AppColors.success);
      });

  Future<void> _registrarAusencia(PacienteNaFila atual) =>
      _runAction(() async {
        await _filaSvc.atualizarStatus(atual.id, StatusFila.ausente);
        if (!mounted) return;
        _showSnack('${atual.nome} marcado como ausente', AppColors.error);
      });

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_agora);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
