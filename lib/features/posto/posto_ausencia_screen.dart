// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  PostoAusenciaScreen — Gestão de ausências/faltas de pacientes
//  Permite registrar ausência e reconvocar pacientes
//  TODO: conectar Firestore collection 'ausencias'
// ─────────────────────────────────────────────────────────────
class PostoAusenciaScreen extends StatefulWidget {
  const PostoAusenciaScreen({super.key});
  @override
  State<PostoAusenciaScreen> createState() => _PostoAusenciaScreenState();
}

class _PostoAusenciaScreenState extends State<PostoAusenciaScreen> {
  final List<_Ausencia> _ausencias = [
    _Ausencia('Raimundo Nonato', 'A-10', 'Clínica Geral', '09:02', '09:20', 1),
    _Ausencia('Tereza Cristina', 'B-03', 'Pediatria', '08:15', '08:45', 2),
    _Ausencia('José Almeida', 'A-08', 'Cardiologia', '07:50', '08:30', 3),
    _Ausencia('Sandra Mota', 'B-07', 'Ginecologia', '08:30', '09:10', 1),
    _Ausencia('Marcos Vinicius', 'A-12', 'Clínica Geral', '09:10', '09:35', 1),
  ];
  @override
  Widget build(BuildContext context) {
    final hoje = _ausencias.where((a) => a.chamadas < 3).toList();
    final perdidas = _ausencias.where((a) => a.chamadas >= 3).toList();
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gestão de Ausências',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumo
              _buildResumo(),
              const SizedBox(height: 20),
              // Ausências reconvocáveis
              _sectionTitle('Pacientes ausentes (reconvocáveis)', hoje.length),
              const SizedBox(height: 10),
              ...hoje.map((a) => _buildAusenciaCard(a, reconvocavel: true)),
              const SizedBox(height: 24),
              // Perderam a vez
              _sectionTitle('Perderam a vez (3 chamadas)', perdidas.length),
              const SizedBox(height: 10),
              ...perdidas
                  .map((a) => _buildAusenciaCard(a, reconvocavel: false)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5C2A2A).withOpacity(0.3),
            const Color(0xFF0F1B3D),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5C2A2A).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.person_off_rounded,
                  color: Color(0xFFEF5350), size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_ausencias.length} ausências hoje',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                Text(
                  '${_ausencias.where((a) => a.chamadas < 3).length} reconvocáveis • ${_ausencias.where((a) => a.chamadas >= 3).length} perderam a vez',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.blueLt,
              )),
        ),
      ],
    );
  }

  Widget _buildAusenciaCard(_Ausencia aus, {required bool reconvocavel}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A6E)),
      ),
      child: Row(
        children: [
          // Info paciente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(aus.senha,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF5350),
                          )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(aus.nome,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(aus.especialidade,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        )),
                    const SizedBox(width: 8),
                    Text('Chamado: ${aus.horaChamada}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.3),
                        )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${aus.chamadas}/3 chamadas',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: aus.chamadas >= 3
                                ? const Color(0xFFEF5350)
                                : const Color(0xFFFFA726),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ações
          if (reconvocavel) ...[
            const SizedBox(width: 10),
            Column(
              children: [
                _actionBtn(
                    'Reconvocar', Icons.campaign_rounded, AppColors.greenLt,
                    () {
                  setState(() => aus.chamadas++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reconvocando ${aus.nome}...'),
                      backgroundColor: const Color(0xFF1A3A6B),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                _actionBtn('Fim da fila', Icons.low_priority_rounded,
                    const Color(0xFFFFA726), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${aus.nome} movido para o fim da fila'),
                      backgroundColor: const Color(0xFF1A3A6B),
                    ),
                  );
                }),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Perdeu a vez',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF5350),
                  )),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: cor),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cor,
                )),
          ],
        ),
      ),
    );
  }
}

class _Ausencia {
  final String nome;
  final String senha;
  final String especialidade;
  final String horaChegada;
  final String horaChamada;
  int chamadas;
  _Ausencia(this.nome, this.senha, this.especialidade, this.horaChegada,
      this.horaChamada, this.chamadas);
}
