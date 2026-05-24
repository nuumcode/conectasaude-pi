// ═══════════════════════════════════════════════════════════════════
//  cidadao_escala_screen.dart  —  ConectaSaúdePI
//
//  ✅ Usa AppDrawer + AppHeader (mesmo padrão do HomeCidadaoScreen)
//  ✅ Drawer mobile / Drawer fixo desktop
//  ✅ BottomNav mobile com navegação entre telas
//  ✅ Conteúdo de Escala Médica preservado dentro do layout reutilizável
// ═══════════════════════════════════════════════════════════════════
import 'package:conecta_saude_pi/features/cidadao/cidadao_fila_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/dashboard_cidadao.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

class CidadaoEscalaScreen extends StatefulWidget {
  const CidadaoEscalaScreen({super.key});
  @override
  State<CidadaoEscalaScreen> createState() => _CidadaoEscalaScreenState();
}

class _CidadaoEscalaScreenState extends State<CidadaoEscalaScreen> {
  // ── Layout / scaffold ──────────────────────────────────────────
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _abaDestaScreen = DrawerAba.agendamentos;
  User? get _user => FirebaseAuth.instance.currentUser;
  String get _firstName {
    final name = _user?.displayName ?? _user?.email ?? 'Usuário';
    return name.split(' ').first;
  }

  // ── Estado da escala ───────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  int _filtroSelecionado = 0;
  // Paleta local (mantida do design original)
  static const _kPrimary = Color(0xFF1565D8);
  static const _kBg = Color(0xFFF0F5FF);
  static const _kCardBg = Colors.white;
  static const _kTextPrimary = Color(0xFF1E293B);
  static const _kTextSecondary = Color(0xFF64748B);
  static const _kDivider = Color(0xFFE2E8F0);
  static const _kStar = Color(0xFFFFC107);
  static const _kGreen = Color(0xFF10B981);
  static const _kRed = Color(0xFFEF4444);
  final _filtros = [
    'Especialidade',
    'Localização',
    'Avaliação',
    'Disponibilidade'
  ];
  final _profissionais = <_Profissional>[
    _Profissional(
      nome: 'Dra. Ana Clar',
      especialidade: 'Clínica Geral',
      clinica: 'Clínica Bem Estar',
      rating: 4.9,
      totalAvaliacoes: 128,
      disponivel: true,
    ),
    _Profissional(
      nome: 'Dr. João Rica',
      especialidade: 'Cardiologista',
      clinica: 'Instituto do Coração',
      rating: 4.7,
      totalAvaliacoes: 86,
      disponivel: false,
    ),
    _Profissional(
      nome: 'Dra. Mariana',
      especialidade: 'Pediatra',
      clinica: 'Clínica Infantil',
      rating: 4.9,
      totalAvaliacoes: 153,
      disponivel: true,
    ),
    _Profissional(
      nome: 'Dra. Marvana O',
      especialidade: 'Pediatra',
      clinica: 'Clínica Infantil Feliz',
      rating: 4.8,
      totalAvaliacoes: 99,
      disponivel: true,
    ),
    _Profissional(
      nome: 'Dr. Paulo',
      especialidade: 'Ortopedista',
      clinica: 'OrtoPrime Clínica',
      rating: 4.6,
      totalAvaliacoes: 72,
      disponivel: false,
    ),
    _Profissional(
      nome: 'Dra. Fernanda',
      especialidade: 'Dermatologista',
      clinica: 'Clínica Derma & Saúde',
      rating: 4.8,
      totalAvaliacoes: 110,
      disponivel: true,
    ),
    _Profissional(
      nome: 'Dra. Fernanda A',
      especialidade: 'Clínica Geral',
      clinica: 'Clínica Derma & Saúde',
      rating: 4.7,
      totalAvaliacoes: 95,
      disponivel: true,
    ),
  ];
  List<_Profissional> get _filtrados {
    final query = _searchCtrl.text.toLowerCase();
    if (query.isEmpty) return _profissionais;
    return _profissionais
        .where((p) =>
            p.nome.toLowerCase().contains(query) ||
            p.especialidade.toLowerCase().contains(query) ||
            p.clinica.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Logout ──────────────────────────────────────────────────────
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginCidadaoScreen()),
    );
  }

  // ── Navegação ───────────────────────────────────────────────────
  void _onAbaChanged(dynamic aba) {
    if (aba == _abaDestaScreen) return;
    final Widget? destino = _resolverAba(aba);
    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Em breve.'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  /// Mapeia qualquer [DrawerAba] para a tela correspondente.
  /// Retorna null para abas ainda não implementadas.
  Widget? _resolverAba(dynamic aba) {
    switch (aba) {
      case DrawerAba.inicio:
        return const HomeCidadaoScreen();
      case DrawerAba.agendamentos:
        return const CidadaoEscalaScreen();
      case DrawerAba.fila:
        return const CidadaoFilaScreen();
      // Abas futuras — adicione aqui quando as telas existirem:
      // case DrawerAba.prontuarios:   return const CidadaoProntuariosScreen();
      // case DrawerAba.vacinacao:     return const CidadaoVacinacaoScreen();
      // case DrawerAba.mensagens:     return const CidadaoMensagensScreen();
      // case DrawerAba.notificacoes:  return const CidadaoNotificacoesScreen();
      // case DrawerAba.emergencia:    return const CidadaoEmergenciaScreen();
      default:
        return null;
    }
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7FB),
      drawer: isDesktop
          ? null
          : AppDrawer(
              userName: _user?.displayName ?? 'Usuário',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: _abaDestaScreen,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
            ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildDesktop() {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Usuário',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: _abaDestaScreen,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
        ),
      ),
      Container(width: 1, color: const Color(0xFFE2E8F0)),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _firstName,
            userPhoto: _user?.photoURL,
            onLogout: _logout,
            onMenuPressed: null,
          ),
          Expanded(child: _buildConteudo()),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _firstName,
        userPhoto: _user?.photoURL,
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      Expanded(child: _buildConteudo()),
    ]);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Agendamentos
        onTap: (i) {
          const mapa = [
            DrawerAba.inicio,
            DrawerAba.agendamentos,
            DrawerAba.prontuarios,
            DrawerAba.mensagens,
            DrawerAba.mais,
          ];
          _onAbaChanged(mapa[i]);
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.bgMid,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'Poppins', fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded), label: 'Agendamentos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined), label: 'Prontuários'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Mensagens'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded), label: 'Mais'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Conteúdo (preserva a UI original)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildConteudo() {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;
    final crossCount = width >= 600 ? 3 : 2;
    final hPad = isSmall ? 14.0 : 16.0;
    return Container(
      color: _kBg,
      child: Column(
        children: [
          _buildTituloEFiltros(isSmall, hPad),
          Expanded(
            child: _filtrados.isEmpty
                ? _buildEmpty()
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _filtrados.length,
                    itemBuilder: (_, i) => _buildDoctorGridCard(_filtrados[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloEFiltros(bool isSmall, double hPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Escala Médica',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _buildSearchBar(isSmall),
          const SizedBox(height: 12),
          _buildFiltros(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isSmall) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: _kTextPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, especialidade ou clínica',
                hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: _kTextSecondary),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: _kTextSecondary),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text('Filtrar',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filtros.length,
        itemBuilder: (_, i) {
          final sel = i == _filtroSelecionado;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filtroSelecionado = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _kPrimary : _kDivider),
                ),
                child: Text(
                  _filtros[i],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : _kTextSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorGridCard(_Profissional prof) {
    return GestureDetector(
      onTap: prof.disponivel ? () => _openAgendamento(prof) : null,
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: prof.disponivel ? _kPrimary.withOpacity(0.12) : _kDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kPrimary.withOpacity(0.08),
                      _kPrimary.withOpacity(0.03)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.person_rounded,
                          size: 52, color: _kPrimary.withOpacity(0.4)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prof.disponivel ? _kGreen : _kRed,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: (prof.disponivel ? _kGreen : _kRed)
                                  .withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prof.nome,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prof.especialidade,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      prof.clinica,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: _kTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < prof.rating.floor();
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 12,
                            color: _kStar,
                          );
                        }),
                        const SizedBox(width: 3),
                        Text(
                          '${prof.rating}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _kTextPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: prof.disponivel ? _kGreen : _kRed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prof.disponivel ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: prof.disponivel ? _kGreen : _kRed,
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

  void _openAgendamento(_Profissional prof) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgendamentoSheet(profissional: prof),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 48, color: _kPrimary.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum profissional encontrado',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kTextPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tente buscar com outros termos',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Bottom Sheet — Agendar Consulta (preservado do original)
// ─────────────────────────────────────────────────────────────
class _AgendamentoSheet extends StatefulWidget {
  final _Profissional profissional;
  const _AgendamentoSheet({required this.profissional});
  @override
  State<_AgendamentoSheet> createState() => _AgendamentoSheetState();
}

class _AgendamentoSheetState extends State<_AgendamentoSheet> {
  static const _kPrimary = Color(0xFF1565D8);
  static const _kPrimaryDark = Color(0xFF0D47A1);
  static const _kBg = Color(0xFFF0F5FF);
  static const _kTextPrimary = Color(0xFF1E293B);
  static const _kTextSecondary = Color(0xFF64748B);
  static const _kDivider = Color(0xFFE2E8F0);
  static const _kGreen = Color(0xFF10B981);
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedTime;
  String _tipoConsulta = 'Consulta';
  final _motivoCtrl = TextEditingController();
  final _horarios = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00'
  ];
  final _diasDisponiveis = [3, 5, 7, 10, 12, 14, 17, 19, 21, 24, 26, 28];
  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildSheetHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepSection(
                      1, 'Selecionar Médico', _buildMedicoSelected()),
                  const SizedBox(height: 20),
                  _buildStepSection(2, 'Selecionar Data', _buildCalendar()),
                  const SizedBox(height: 20),
                  _buildStepSection(3, 'Selecionar Horário', _buildHorarios()),
                  const SizedBox(height: 20),
                  _buildStepSection(
                      4, 'Tipo de Consulta', _buildTipoConsulta()),
                  const SizedBox(height: 20),
                  _buildStepSection(
                      5, 'Descrição / Motivo da Consulta', _buildMotivo()),
                  const SizedBox(height: 28),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Agendar Consulta',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSection(int step, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _kPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: content,
        ),
      ],
    );
  }

  Widget _buildMedicoSelected() {
    final prof = widget.profissional;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrimary.withOpacity(0.1),
            ),
            child: const Icon(Icons.person_rounded, size: 22, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prof.nome,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary),
                ),
                Text(
                  '${prof.especialidade} • ${prof.clinica}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _kTextSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 20, color: _kGreen),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final monthNames = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedMonth == 1) {
                      _selectedMonth = 12;
                      _selectedYear--;
                    } else {
                      _selectedMonth--;
                    }
                  });
                },
                child: const Icon(Icons.chevron_left_rounded,
                    color: _kPrimary, size: 22),
              ),
              Text(
                '${monthNames[_selectedMonth]} $_selectedYear',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                  });
                },
                child: const Icon(Icons.chevron_right_rounded,
                    color: _kPrimary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _kTextSecondary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(6, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayOfWeek) {
                  final dayIndex = week * 7 + dayOfWeek - (firstWeekday - 1);
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const SizedBox(width: 32, height: 32);
                  }
                  final isSelected = _selectedDate.day == dayIndex &&
                      _selectedDate.month == _selectedMonth &&
                      _selectedDate.year == _selectedYear;
                  final isAvailable = _diasDisponiveis.contains(dayIndex);
                  final isToday = dayIndex == DateTime.now().day &&
                      _selectedMonth == DateTime.now().month &&
                      _selectedYear == DateTime.now().year;
                  return GestureDetector(
                    onTap: isAvailable
                        ? () => setState(() => _selectedDate =
                            DateTime(_selectedYear, _selectedMonth, dayIndex))
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimary
                            : isToday
                                ? _kPrimary.withOpacity(0.1)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$dayIndex',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : !isAvailable
                                    ? _kTextSecondary.withOpacity(0.4)
                                    : _kTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Dias disponíveis',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorarios() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _horarios.map((h) {
        final sel = _selectedTime == h;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = h),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? _kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? _kPrimary : _kDivider),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: _kPrimary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Text(
              h,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? Colors.white : _kTextPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipoConsulta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kDivider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tipoConsulta,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: _kTextPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextSecondary),
          items: ['Consulta', 'Retorno', 'Exame', 'Emergência']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _tipoConsulta = v!),
        ),
      ),
    );
  }

  Widget _buildMotivo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kDivider),
      ),
      child: TextField(
        controller: _motivoCtrl,
        maxLines: 3,
        style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 13, color: _kTextPrimary),
        decoration: const InputDecoration(
          hintText: 'Descreva o motivo da consulta...',
          hintStyle: TextStyle(
              fontFamily: 'Poppins', fontSize: 12, color: _kTextSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Consulta agendada com sucesso!',
                      style: TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: _kGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Agendar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: _kDivider),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancelar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _Profissional {
  final String nome;
  final String especialidade;
  final String clinica;
  final double rating;
  final int totalAvaliacoes;
  final bool disponivel;
  _Profissional({
    required this.nome,
    required this.especialidade,
    required this.clinica,
    required this.rating,
    required this.totalAvaliacoes,
    required this.disponivel,
  });
}
