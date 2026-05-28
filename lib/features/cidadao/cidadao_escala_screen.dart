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
import 'package:intl/intl.dart';
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
  
  DateTime _selectedDate = DateTime.now();
  final _searchCtrl = TextEditingController();

  final _profissionais = <_Profissional>[
    _Profissional(
      nome: 'Dr. Ricardo Silva',
      especialidade: 'Clínica Geral',
      clinica: 'UBS Novo Oriente',
      rating: 4.9,
      totalAvaliacoes: 450,
      disponivel: true,
      diasTrabalho: [1, 3, 5], // Seg, Qua, Sex
      horario: '08:00 - 17:00',
      foto: null,
      experiencia: '15 anos de experiência em saúde da família.',
    ),
    _Profissional(
      nome: 'Dra. Beatriz Santos',
      especialidade: 'Pediatra',
      clinica: 'UBS Novo Oriente',
      rating: 4.8,
      totalAvaliacoes: 320,
      disponivel: true,
      diasTrabalho: [2, 4], // Ter, Qui
      horario: '07:00 - 13:00',
      foto: null,
      experiencia: 'Especialista em desenvolvimento infantil.',
    ),
    _Profissional(
      nome: 'Dr. Marcos Oliveira',
      especialidade: 'Cardiologista',
      clinica: 'UBS Novo Oriente',
      rating: 4.7,
      totalAvaliacoes: 180,
      disponivel: true,
      diasTrabalho: [3], // Quarta
      horario: '13:00 - 19:00',
      foto: null,
      experiencia: 'Mestre em cardiologia preventiva.',
    ),
    _Profissional(
      nome: 'Dra. Ana Costa',
      especialidade: 'Ginecologista',
      clinica: 'UBS Santa Maria',
      rating: 4.9,
      totalAvaliacoes: 290,
      disponivel: true,
      diasTrabalho: [1, 2, 3, 4, 5],
      horario: '08:00 - 17:00',
      foto: null,
      experiencia: 'Atendimento humanizado à mulher.',
    ),
    _Profissional(
      nome: 'Dr. João Pereira',
      especialidade: 'Ortopedista',
      clinica: 'UBS Parque Brasil',
      rating: 4.6,
      totalAvaliacoes: 150,
      disponivel: true,
      diasTrabalho: [5], // Sexta
      horario: '08:00 - 12:00',
      foto: null,
      experiencia: 'Especialista em traumas e lesões esportivas.',
    ),
  ];

  List<_Profissional> get _filtrados {
    final query = _searchCtrl.text.toLowerCase();
    final dayOfWeek = _selectedDate.weekday;

    return _profissionais.where((p) {
      final matchesQuery = p.nome.toLowerCase().contains(query) ||
          p.especialidade.toLowerCase().contains(query) ||
          p.clinica.toLowerCase().contains(query);
      final matchesDay = p.diasTrabalho.contains(dayOfWeek);
      return matchesQuery && matchesDay;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      case DrawerAba.inicio: return const HomeCidadaoScreen();
      case DrawerAba.agendamentos: return const CidadaoEscalaScreen();
      case DrawerAba.fila: return const CidadaoFilaScreen();
      case DrawerAba.emergencia: return const CidadaoEmergenciaScreen();
      case DrawerAba.perfil: return const PerfilScreen();
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
      drawer: isDesktop ? null : AppDrawer(
        userName: _user?.displayName ?? 'Usuário',
        userEmail: _user?.email ?? '',
        userPhoto: _user?.photoURL,
        abaAtual: _abaDestaScreen,
        onAbaChanged: _onAbaChanged,
        onLogout: () {},
      ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
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
          onLogout: () {},
          isFixed: true,
        ),
      ),
      Container(width: 1, color: AppColors.borderDim),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Usuário',
            userPhoto: _user?.photoURL,
            onLogout: () {},
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
        userName: _user?.displayName?.split(' ').first ?? 'Usuário',
        userPhoto: _user?.photoURL,
        onLogout: () {},
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
      ),
      Expanded(child: _buildConteudo()),
    ]);
  }

  Widget _buildConteudo() {
    return Column(
      children: [
        _buildHeaderCalendar(),
        Expanded(
          child: _filtrados.isEmpty ? _buildEmpty() : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _filtrados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (_, i) => _buildLargeScaleCard(_filtrados[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCalendar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escala de Atendimento',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const Text(
            'Selecione um dia para ver os médicos disponíveis.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildHorizontalCalendar(),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Próximas 2 semanas
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
          
          final dayName = DateFormat('E', 'pt_BR').format(date).toUpperCase().replaceAll('.', '');
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderDim),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLargeScaleCard(_Profissional prof) {
    final isNovoOriente = prof.clinica == 'UBS Novo Oriente';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isNovoOriente ? AppColors.primary.withOpacity(0.3) : AppColors.borderDim, width: isNovoOriente ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 35),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(prof.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          if (isNovoOriente)
                            const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                      Text(prof.especialidade, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(prof.clinica, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: AppColors.surfaceDim.withOpacity(0.5),
            child: Column(
              children: [
                _buildInfoRow(Icons.access_time_filled_rounded, 'Horário de Plantão', prof.horario),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.info_outline_rounded, 'Informações', prof.experiencia),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Ver Perfil Completo'),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DISPONÍVEL HOJE',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontFamily: 'Poppins')),
                TextSpan(text: value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 60, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Nenhum médico escalado para este dia.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ],
      ),
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
  final List<int> diasTrabalho;
  final String horario;
  final String? foto;
  final String experiencia;
  
  _Profissional({
    required this.nome,
    required this.especialidade,
    required this.clinica,
    required this.rating,
    required this.totalAvaliacoes,
    required this.disponivel,
    required this.diasTrabalho,
    required this.horario,
    this.foto,
    required this.experiencia,
  });
}
