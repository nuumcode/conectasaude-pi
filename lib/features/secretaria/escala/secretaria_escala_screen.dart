// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
// ─────────────────────────────────────────────────────────────
//  SecretariaEscalaScreen — Gestão de escalas pela Secretaria
//  Permite visualizar e editar escalas de todas as UBS
//  TODO: conectar Firestore collection 'escalas'
// ─────────────────────────────────────────────────────────────
class SecretariaEscalaScreen extends StatefulWidget {
  const SecretariaEscalaScreen({super.key});
  @override
  State<SecretariaEscalaScreen> createState() => _SecretariaEscalaScreenState();
}
class _SecretariaEscalaScreenState extends State<SecretariaEscalaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);
  String _unidadeSelecionada = 'Todas';
  int _semanaSelecionada = 0;
  final _unidades = ['Todas', 'UBS Vila Esperança', 'UBS Centro',
      'UBS Parque Piauí', 'UBS Dirceu Arcoverde'];
  // Mock data
  final _escalas = <_EscalaItem>[
    _EscalaItem('Dr. Carlos Mendes', 'Clínica Geral', 'UBS Vila Esperança',
        [true, true, true, true, true, false, false], '07:00', '13:00'),
    _EscalaItem('Dra. Ana Souza', 'Pediatria', 'UBS Vila Esperança',
        [true, true, false, true, true, false, false], '07:00', '13:00'),
    _EscalaItem('Dr. Roberto Lima', 'Cardiologia', 'UBS Vila Esperança',
        [false, true, true, false, true, false, false], '13:00', '19:00'),
    _EscalaItem('Dr. Paulo Andrade', 'Clínica Geral', 'UBS Centro',
        [true, true, true, true, true, false, false], '07:00', '13:00'),
    _EscalaItem('Dra. Lucia Ferreira', 'Dermatologia', 'UBS Centro',
        [true, false, true, false, true, false, false], '08:00', '14:00'),
    _EscalaItem('Dra. Renata Dias', 'Clínica Geral', 'UBS Parque Piauí',
        [true, true, true, true, true, false, false], '07:00', '13:00'),
    _EscalaItem('Dr. Antonio Nunes', 'Clínica Geral', 'UBS Dirceu Arcoverde',
        [true, true, true, true, true, true, false], '07:00', '13:00'),
    _EscalaItem('Dra. Carla Ribeiro', 'Ginecologia', 'UBS Dirceu Arcoverde',
        [true, true, false, true, true, false, false], '07:00', '13:00'),
  ];
  List<_EscalaItem> get _escalasFiltradas {
    if (_unidadeSelecionada == 'Todas') return _escalas;
    return _escalas.where((e) => e.unidade == _unidadeSelecionada).toList();
  }
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gestão de Escalas',
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
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.blueLt,
          labelColor: AppColors.blueLt,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Visão Semanal'),
            Tab(text: 'Cobertura'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildVisaoSemanal(),
            _buildCobertura(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarEscala,
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  // ── Tab 1: Visão Semanal ───────────────────────────────────
  Widget _buildVisaoSemanal() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Filtro de unidade
        _buildUnidadeFilter(),
        const SizedBox(height: 12),
        // Navegação de semana
        _buildSemanaNav(),
        const SizedBox(height: 12),
        // Grid de escala
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _escalasFiltradas.length,
            itemBuilder: (_, i) => _buildEscalaRow(_escalasFiltradas[i]),
          ),
        ),
      ],
    );
  }
  Widget _buildUnidadeFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _unidades.map((u) {
          final sel = _unidadeSelecionada == u;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _unidadeSelecionada = u),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppColors.blue : const Color(0xFF0F1B3D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: sel ? AppColors.blueLt : const Color(0xFF1E3A6E)),
                ),
                child: Text(u,
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
  Widget _buildSemanaNav() {
    final hoje = DateTime.now();
    final inicioSemana = hoje.add(Duration(days: _semanaSelecionada * 7));
    final fimSemana = inicioSemana.add(const Duration(days: 6));
    final label = _semanaSelecionada == 0
        ? 'Esta semana'
        : '${inicioSemana.day}/${inicioSemana.month} - ${fimSemana.day}/${fimSemana.month}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white54),
            onPressed: () => setState(() => _semanaSelecionada--),
          ),
          Text(label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              )),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white54),
            onPressed: () => setState(() => _semanaSelecionada++),
          ),
        ],
      ),
    );
  }
  Widget _buildEscalaRow(_EscalaItem item) {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A6E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome e info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.profissional,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    Row(
                      children: [
                        Text(item.especialidade,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.blueLt.withOpacity(0.7),
                            )),
                        if (_unidadeSelecionada == 'Todas') ...[
                          Text(' • ${item.unidade}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.3),
                              )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text('${item.horaInicio}-${item.horaFim}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          // Grid de dias
          Row(
            children: List.generate(7, (i) {
              final ativo = item.diasAtivos[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => item.diasAtivos[i] = !item.diasAtivos[i]);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: ativo
                          ? AppColors.greenLt.withOpacity(0.2)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ativo
                            ? AppColors.greenLt.withOpacity(0.4)
                            : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(dias[i],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: ativo
                                  ? AppColors.greenLt
                                  : Colors.white.withOpacity(0.3),
                            )),
                        const SizedBox(height: 2),
                        Icon(
                          ativo ? Icons.check_circle : Icons.circle_outlined,
                          size: 14,
                          color: ativo
                              ? AppColors.greenLt
                              : Colors.white.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  // ── Tab 2: Cobertura ───────────────────────────────────────
  Widget _buildCobertura() {
    final coberturas = [
      _CoberturaData('UBS Vila Esperança', {
        'Clínica Geral': 1.0,
        'Pediatria': 0.8,
        'Cardiologia': 0.4,
        'Ginecologia': 0.8,
        'Enfermagem': 1.0,
      }),
      _CoberturaData('UBS Centro', {
        'Clínica Geral': 1.0,
        'Dermatologia': 0.6,
        'Ortopedia': 0.4,
      }),
      _CoberturaData('UBS Parque Piauí', {
        'Clínica Geral': 1.0,
        'Pediatria': 0.4,
      }),
      _CoberturaData('UBS Dirceu Arcoverde', {
        'Clínica Geral': 1.0,
        'Ginecologia': 0.8,
        'Enfermagem': 1.0,
        'Psicologia': 0.6,
      }),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Resumo geral
          _buildCoberturaResumo(),
          const SizedBox(height: 16),
          // Por unidade
          ...coberturas.map((c) => _buildCoberturaCard(c)),
        ],
      ),
    );
  }
  Widget _buildCoberturaResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withOpacity(0.2),
            const Color(0xFF0F1B3D),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _coberturaMetrica('78%', 'Cobertura Geral', AppColors.blueLt),
          _dividerVertical(),
          _coberturaMetrica('23', 'Profissionais', AppColors.greenLt),
          _dividerVertical(),
          _coberturaMetrica('5', 'Unidades', const Color(0xFFFFA726)),
        ],
      ),
    );
  }
  Widget _coberturaMetrica(String valor, String label, Color cor) {
    return Expanded(
      child: Column(
        children: [
          Text(valor,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cor,
              )),
          Text(label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              )),
        ],
      ),
    );
  }
  Widget _dividerVertical() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.08),
    );
  }
  Widget _buildCoberturaCard(_CoberturaData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A6E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital, size: 16, color: AppColors.blueLt),
              const SizedBox(width: 8),
              Text(data.unidade,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...data.especialidades.entries.map((e) {
            final cor = e.value >= 0.8
                ? AppColors.greenLt
                : e.value >= 0.5
                    ? const Color(0xFFFFA726)
                    : const Color(0xFFEF5350);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(e.key,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        )),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation(cor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(e.value * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cor,
                      )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  void _adicionarEscala() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adicionar Escala',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
            const SizedBox(height: 8),
            Text('Funcionalidade em desenvolvimento.\nConectar com Firebase para persistência.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entendi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _EscalaItem {
  final String profissional;
  final String especialidade;
  final String unidade;
  final List<bool> diasAtivos;
  final String horaInicio;
  final String horaFim;
  _EscalaItem(this.profissional, this.especialidade, this.unidade,
      this.diasAtivos, this.horaInicio, this.horaFim);
}
class _CoberturaData {
  final String unidade;
  final Map<String, double> especialidades;
  _CoberturaData(this.unidade, this.especialidades);
}
