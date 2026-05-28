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
                _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061030), Color(0xFF0D2B6B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Botão sutil de voltar
          IconButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/admin/home'),
            tooltip: 'Voltar ao Dashboard',
            icon: const Icon(Icons.dashboard_rounded, color: Colors.white70, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.live_tv_rounded, color: AppColors.accent, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'PAINEL DE ATENDIMENTO AO VIVO',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Unidade: UBS Novo Oriente • Bola de Ouro',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Mock: Tempo Médio
          _buildTopStatMock('ESPERA MÉDIA', '14 min', Icons.timer_outlined),
          const SizedBox(width: 24),
          
          IconButton(
            tooltip: 'Simular novo paciente',
            icon: const Icon(Icons.person_add_outlined,
                color: Colors.white70, size: 22),
            onPressed: _loading ? null : _simularPaciente,
          ),
          const SizedBox(width: 12),
          const _LiveClock(),
        ],
      ),
    );
  }

  Widget _buildTopStatMock(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ── Layouts ────────────────────────────────────────────────

  Widget _buildWideLayout(List<PacienteNaFila> fila) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: Column(
            children: [
              _buildPacienteAtualCard(fila),
              const SizedBox(height: 24),
              Expanded(child: _buildHistoricoMock()),
            ],
          )),
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
          _buildHistoricoMock(isCompact: true),
          const SizedBox(height: 16),
          SizedBox(height: 400, child: _buildFilaAoVivo(fila)),
        ],
      ),
    );
  }

  Widget _buildHistoricoMock({bool isCompact = false}) {
    final historico = [
      {'nome': 'Ricardo Silva', 'senha': 'P-042', 'hora': '14:20'},
      {'nome': 'Joana Souza', 'senha': 'G-015', 'hora': '14:05'},
      {'nome': 'Marcos Vinicius', 'senha': 'P-041', 'hora': '13:50'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('ÚLTIMAS CHAMADAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          ...historico.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(item['hora']!, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.surfaceMid, borderRadius: BorderRadius.circular(4)),
                  child: Text(item['senha']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item['nome']!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Card do paciente atual ─────────────────────────────────

  Widget _buildPacienteAtualCard(List<PacienteNaFila> fila) {
    final pac = _pacienteAtual(fila);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF061030), // Fundo escuro para o card principal
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: pac != null ? AppColors.accent : Colors.white24,
                      shape: BoxShape.circle,
                      boxShadow: pac != null ? [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 8)] : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PACIENTE EM ATENDIMENTO',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: pac != null ? Colors.white : Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              if (pac != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.record_voice_over_rounded, size: 14, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text('CHAMADA ATIVA', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          if (pac != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSenhaTV(pac.senha),
                const SizedBox(width: 40),
                Expanded(child: _buildPacienteInfoTV(pac)),
              ],
            ),
            const SizedBox(height: 40),
            _buildActionButtonsTV(pac),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum paciente sendo atendido',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButtonsTV(null),
          ],
        ],
      ),
    );
  }

  Widget _buildSenhaTV(String senha) {
    return Column(
      children: [
        const Text(
          'SENHA',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A72FF), Color(0xFF0D2B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1A72FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Text(
            senha,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacienteInfoTV(PacienteNaFila pac) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pac.nome.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _badgeTV(pac.especialidade, AppColors.accent),
            const SizedBox(width: 12),
            if (pac.senha.startsWith('P')) _badgeTV('PREFERENCIAL', AppColors.warning),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _infoItemTV(Icons.access_time_rounded, 'CHEGADA', pac.horaFormatada),
            const SizedBox(width: 32),
            _infoItemTV(Icons.room_rounded, 'LOCAL', 'GUICHÊ 01'),
          ],
        ),
      ],
    );
  }

  Widget _badgeTV(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _infoItemTV(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white38),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionButtonsTV(PacienteNaFila? pacAtual) {
    return Row(
      children: [
        if (pacAtual != null) ...[
          Expanded(
            child: _btnTV(
              onTap: () => _finalizarAtendimento(pacAtual),
              label: 'FINALIZAR',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _btnTV(
              onTap: () => _showSnack('Re-chamando paciente...', AppColors.accent),
              label: 'RE-CHAMAR',
              icon: Icons.refresh_rounded,
              color: AppColors.accent,
              outline: true,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: _btnTV(
            onTap: _chamarProximo,
            label: 'PRÓXIMO',
            icon: Icons.skip_next_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _btnTV({required VoidCallback onTap, required String label, required IconData icon, required Color color, bool outline = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(16),
          border: outline ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
          boxShadow: outline ? null : [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: outline ? color : Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: outline ? color : Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  // ── Fila ao vivo ───────────────────────────────────────────

  Widget _buildFilaAoVivo(List<PacienteNaFila> fila) {
    final espera = _filaEspera(fila);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D47), // Azul marinho escuro
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.queue_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'ORDEM DE CHAMADA',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('${espera.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: espera.isEmpty
                ? Center(child: Text('FILA VAZIA', style: TextStyle(color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.bold, letterSpacing: 2)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: espera.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10, indent: 24, endIndent: 24),
                    itemBuilder: (_, i) => _buildFilaItemTV(espera[i], i + 1),
                  ),
          ),
          
          // Mock: Próximo na vez em destaque
          if (espera.isNotEmpty) ...[
            const Divider(height: 1, color: Colors.white10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
              child: Row(
                children: [
                  const Text('A SEGUIR:', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(width: 12),
                  Text(espera[0].senha, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(espera[0].nome, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilaItemTV(PacienteNaFila pac, int posicao) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text('$posicaoº', style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
            child: Text(pac.senha, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(pac.nome, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white10, size: 20),
        ],
      ),
    );
  }

  // ── Stats inferiores ───────────────────────────────────────

  Widget _buildBottomStats(List<PacienteNaFila> fila) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF061030),
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          _statItemTV(Icons.people_rounded, '${fila.length}', 'TOTAL DO DIA', Colors.white38),
          _statDividerTV(),
          _statItemTV(Icons.check_circle_rounded, '${FilaService.atendidos(fila)}', 'ATENDIDOS', AppColors.success),
          _statDividerTV(),
          _statItemTV(Icons.timer_outlined, '12m', 'TMA', AppColors.accent),
          _statDividerTV(),
          _statItemTV(Icons.campaign_rounded, '38', 'CHAMADAS', AppColors.primary),
        ],
      ),
    );
  }

  Widget _statItemTV(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDividerTV() {
    return Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05), margin: const EdgeInsets.symmetric(horizontal: 10));
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
