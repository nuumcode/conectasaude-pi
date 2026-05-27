import 'package:conecta_saude_pi/features/cidadao/cidadao_fila_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/perfil_screen.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _abaDestaScreen = DrawerAba.agendamentos;
  User? get _user => FirebaseAuth.instance.currentUser;
  String get _firstName {
    final name = _user?.displayName ?? _user?.email ?? 'Usuário';
    return name.split(' ').first;
  }

  final _searchCtrl = TextEditingController();
  int _filtroSelecionado = 0;

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

  void _onAbaChanged(dynamic aba) {
    if (aba == _abaDestaScreen) return;
    final Widget? destino = _resolverAba(aba);
    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    }
  }

  Widget? _resolverAba(dynamic aba) {
    switch (aba) {
      case DrawerAba.inicio:
        return const HomeCidadaoScreen();
      case DrawerAba.agendamentos:
        return const CidadaoEscalaScreen();
      case DrawerAba.fila:
        return const CidadaoFilaScreen();
      case DrawerAba.emergencia:
        return const CidadaoEmergenciaScreen();
      case DrawerAba.perfil:
        return const PerfilScreen();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
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
      Container(width: 1, color: AppColors.borderDim),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _firstName,
            userPhoto: _user?.photoURL,
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
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
        onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
      ),
      Expanded(child: _buildConteudo()),
    ]);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderDim)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          const mapa = [
            DrawerAba.inicio,
            DrawerAba.agendamentos,
            DrawerAba.fila,
            DrawerAba.emergencia,
            DrawerAba.perfil,
          ];
          _onAbaChanged(mapa[i]);
        },
        backgroundColor: AppColors.bgBase,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
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
              icon: Icon(Icons.calendar_today_rounded), label: 'Agendas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded), label: 'Fila'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emergency_rounded), label: 'SOS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;
    final crossCount = width >= 600 ? 3 : 2;
    final hPad = isSmall ? 14.0 : 16.0;
    return Container(
      color: AppColors.bgBase,
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
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(bottom: BorderSide(color: AppColors.borderDim)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Escala Médica',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
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
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar profissional...',
                hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textTertiary),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: false,
              ),
            ),
          ),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
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
                  color: sel ? AppColors.primary : AppColors.bgBase,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? AppColors.primary : AppColors.borderDim),
                ),
                child: Text(
                  _filtros[i],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : AppColors.textSecondary,
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
          color: AppColors.bgBase,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDim),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.person_rounded,
                          size: 52, color: AppColors.primary.withOpacity(0.2)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prof.disponivel ? AppColors.success : AppColors.error,
                          border: Border.all(color: AppColors.bgBase, width: 2),
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prof.nome,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      prof.especialidade,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          '${prof.rating}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'Nenhum profissional encontrado',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _AgendamentoSheet extends StatefulWidget {
  final _Profissional profissional;
  const _AgendamentoSheet({required this.profissional});
  @override
  State<_AgendamentoSheet> createState() => _AgendamentoSheetState();
}

class _AgendamentoSheetState extends State<_AgendamentoSheet> {
  String? _selectedTime;
  final _motivoCtrl = TextEditingController();
  final _horarios = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'
  ];
  
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
        color: AppColors.bgBase,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMedicoSelected(),
                  const SizedBox(height: 24),
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  _buildHorarios(),
                  const SizedBox(height: 24),
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
        color: AppColors.primary,
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
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'Agendar Consulta',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicoSelected() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.surfaceDim,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.profissional.nome, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(widget.profissional.especialidade, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecione a Data', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDim),
          ),
          child: const Center(child: Text('Calendário de Disponibilidade', style: TextStyle(color: AppColors.textSecondary))),
        ),
      ],
    );
  }

  Widget _buildHorarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecione o Horário', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _horarios.map((h) {
            final sel = _selectedTime == h;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = h),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppColors.primary : AppColors.borderDim),
                ),
                child: Text(h, style: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consulta agendada!'), backgroundColor: AppColors.success));
      },
      child: const Text('CONFIRMAR AGENDAMENTO'),
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
