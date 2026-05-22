// lib/features/posto/posto_fila_screen.dart
//
// Gerenciamento da fila pelo posto — agora consumindo a fila do Firestore.
// As ações (chamar próximo, marcar ausente, finalizar atendimento) gravam
// direto no Firestore e a CidadaoFilaScreen reflete imediatamente.
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/fila_service.dart';
class PostoFilaScreen extends StatefulWidget {
  const PostoFilaScreen({super.key});
  @override
  State<PostoFilaScreen> createState() => _PostoFilaScreenState();
}
class _PostoFilaScreenState extends State<PostoFilaScreen> {
  final _fila = FilaService.instance;
  String _filtro = 'todos';
  List<PacienteNaFila> _filtrar(List<PacienteNaFila> fila) {
    if (_filtro == 'todos') return fila;
    final status = switch (_filtro) {
      'aguardando' => StatusFila.aguardando,
      'em_atendimento' => StatusFila.emAtendimento,
      'atendido' => StatusFila.atendido,
      'ausente' => StatusFila.ausente,
      _ => null,
    };
    if (status == null) return fila;
    return fila.where((p) => p.status == status).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fila de Atendimento',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: Colors.white38, size: 20),
            tooltip: 'Simular novo paciente',
            onPressed: () async {
              await _fila.simularNovoPaciente();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Novo paciente adicionado à fila'),
                  backgroundColor: Color(0xFF1A3A6B),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<PacienteNaFila>>(
          stream: _fila.streamFila(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erro: ${snap.error}',
                      style: const TextStyle(color: Colors.white)),
                ),
              );
            }
            final fila = snap.data ?? const [];
            final visivel = _filtrar(fila);
            return Column(
              children: [
                _buildResumo(fila),
                const SizedBox(height: 12),
                _buildFiltros(),
                const SizedBox(height: 12),
                Expanded(
                  child: visivel.isEmpty
                      ? _buildVazio()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: visivel.length,
                          itemBuilder: (_, i) =>
                              _buildPacienteCard(visivel[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _chamarProximo,
        backgroundColor: AppColors.greenLt,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text(
          'Chamar Próximo',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  // ── Resumo ──────────────────────────────────────────────────
  Widget _buildResumo(List<PacienteNaFila> fila) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _resumoChip(Icons.people_outline, '${FilaService.aguardando(fila)}',
              'Aguardando', const Color(0xFFFFA726)),
          const SizedBox(width: 10),
          _resumoChip(Icons.check_circle_outline,
              '${FilaService.atendidos(fila)}', 'Atendidos', AppColors.greenLt),
          const SizedBox(width: 10),
          _resumoChip(Icons.person_off_outlined,
              '${FilaService.ausentes(fila)}', 'Ausentes',
              const Color(0xFFEF5350)),
        ],
      ),
    );
  }
  Widget _resumoChip(IconData icon, String valor, String label, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: cor, size: 20),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cor,
                )),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: cor.withOpacity(0.7),
                )),
          ],
        ),
      ),
    );
  }
  Widget _buildFiltros() {
    final filtros = {
      'todos': 'Todos',
      'aguardando': 'Aguardando',
      'em_atendimento': 'Atendendo',
      'atendido': 'Atendidos',
      'ausente': 'Ausentes',
    };
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filtros.entries.map((e) {
          final sel = _filtro == e.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _filtro = e.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppColors.blue : const Color(0xFF0F1B3D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: sel
                          ? AppColors.blueLt
                          : const Color(0xFF1E3A6E)),
                ),
                child: Text(e.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? Colors.white : Colors.white60,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildPacienteCard(PacienteNaFila pac) {
    final corStatus = switch (pac.status) {
      StatusFila.aguardando => const Color(0xFFFFA726),
      StatusFila.emAtendimento => AppColors.blueLt,
      StatusFila.atendido => AppColors.greenLt,
      StatusFila.ausente => const Color(0xFFEF5350),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pac.status == StatusFila.emAtendimento
              ? AppColors.blueLt.withOpacity(0.4)
              : const Color(0xFF1E3A6E),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(pac.senha,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: corStatus,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pac.nome,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(pac.especialidade,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        )),
                    const SizedBox(width: 8),
                    Text('• ${pac.horaFormatada}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.3),
                        )),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: corStatus.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(pac.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: corStatus,
                    )),
              ),
              if (pac.status == StatusFila.aguardando) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionBtn(
                        Icons.campaign,
                        AppColors.greenLt,
                        () => _fila.atualizarStatus(
                            pac.id, StatusFila.emAtendimento)),
                    const SizedBox(width: 6),
                    _actionBtn(
                        Icons.person_off,
                        const Color(0xFFEF5350),
                        () => _fila.atualizarStatus(
                            pac.id, StatusFila.ausente)),
                  ],
                ),
              ],
              if (pac.status == StatusFila.emAtendimento) ...[
                const SizedBox(height: 6),
                _actionBtn(
                    Icons.check_circle_outline,
                    AppColors.greenLt,
                    () => _fila.atualizarStatus(
                        pac.id, StatusFila.atendido)),
              ],
            ],
          ),
        ],
      ),
    );
  }
  Widget _actionBtn(IconData icon, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: cor),
      ),
    );
  }
  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_outlined, size: 48, color: Colors.white12),
          SizedBox(height: 12),
          Text('Nenhum paciente neste filtro',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white38,
              )),
        ],
      ),
    );
  }
  Future<void> _chamarProximo() async {
    final proximo = await _fila.chamarProximo();
    if (!mounted) return;
    if (proximo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum paciente aguardando na fila'),
          backgroundColor: Color(0xFF5C2A2A),
        ),
      );
      return;
    }
    setState(() => _filtro = 'em_atendimento');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Chamando: ${proximo.nome}  •  Senha ${proximo.senha}'),
        backgroundColor: const Color(0xFF1A3A6B),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
