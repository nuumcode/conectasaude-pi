import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/animations/app_animations.dart';
import '../auth/login_admin_screen.dart';
import 'secretaria_dashboard_screen.dart';

class SecretariaEscalaScreen extends StatefulWidget {
  const SecretariaEscalaScreen({super.key});
  @override
  State<SecretariaEscalaScreen> createState() => _SecretariaEscalaScreenState();
}

class _SecretariaEscalaScreenState extends State<SecretariaEscalaScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);
  String _unidadeSelecionada = 'Todas';
  int _semanaSelecionada = 0;
  
  User? get _user => FirebaseAuth.instance.currentUser;

  final _unidades = [
    'Todas',
    'UBS Vila Esperança',
    'UBS Centro',
    'UBS Parque Piauí',
    'UBS Dirceu Arcoverde'
  ];

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginAdminScreen()),
    );
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.escala) return;
    Widget? destino;
    if (aba == DrawerAba.inicio) destino = const SecretariaDashboardScreen();
    
    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Em breve.'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
      drawer: isDesktop
          ? null
          : AppDrawer(
              userName: _user?.displayName ?? 'Administrador',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: DrawerAba.escala,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
              role: UserRole.secretaria,
            ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarEscala,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Administrador',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.escala,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
          role: UserRole.secretaria,
        ),
      ),
      Container(width: 1, color: AppColors.borderDim),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Admin',
            userPhoto: _user?.photoURL,
            title: 'Gestão de Escalas',
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () {},
          ),
          _buildTabs(),
          Expanded(child: _buildTabContent()),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Admin',
        userPhoto: _user?.photoURL,
        title: 'Gestão de Escalas',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      _buildTabs(),
      Expanded(child: _buildTabContent()),
    ]);
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.bgMid,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
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
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildVisaoSemanal(),
        _buildCobertura(),
      ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.borderDim),
                ),
                child: Text(u,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? Colors.white : AppColors.textSecondary,
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
            icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            onPressed: () => setState(() => _semanaSelecionada--),
          ),
          Text(label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              )),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDim),
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
                          color: AppColors.textPrimary,
                        )),
                    Row(
                      children: [
                        Text(item.especialidade,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            )),
                        if (_unidadeSelecionada == 'Todas') ...[
                          Text(' • ${item.unidade}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text('${item.horaInicio}-${item.horaFim}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ativo
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.borderDim,
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
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            )),
                        const SizedBox(height: 2),
                        Icon(
                          ativo ? Icons.check_circle : Icons.circle_outlined,
                          size: 14,
                          color: ativo
                              ? AppColors.primary
                              : AppColors.textHint,
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
            AppColors.primary.withOpacity(0.05),
            AppColors.surfaceDim,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Row(
        children: [
          _coberturaMetrica('78%', 'Cobertura Geral', AppColors.primary),
          _dividerVertical(),
          _coberturaMetrica('23', 'Profissionais', AppColors.success),
          _dividerVertical(),
          _coberturaMetrica('5', 'Unidades', AppColors.warning),
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
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }

  Widget _dividerVertical() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderDim,
    );
  }

  Widget _buildCoberturaCard(_CoberturaData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(data.unidade,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...data.especialidades.entries.map((e) {
            final cor = e.value >= 0.8
                ? AppColors.success
                : e.value >= 0.5
                    ? AppColors.warning
                    : AppColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(e.key,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        )),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceDim,
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
      backgroundColor: AppColors.bgBase,
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
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            const Text(
                'Funcionalidade em desenvolvimento.\nConectar com Firebase para persistência.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
