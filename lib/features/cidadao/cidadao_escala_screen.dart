import 'package:conecta_saude_pi/features/cidadao/cidadao_fila_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:conecta_saude_pi/features/cidadao/dashboard_cidadao.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      foto: 'https://i.pravatar.cc/150?u=ricardo',
      experiencia: '15 anos de experiência em saúde da família.',
      status: 'Atendendo agora',
      crm: 'CRM/PI 12345',
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
      foto: 'https://i.pravatar.cc/150?u=beatriz',
      experiencia: 'Especialista em desenvolvimento infantil.',
      status: 'Disponível',
      crm: 'CRM/PI 54321',
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
      foto: 'https://i.pravatar.cc/150?u=marcos',
      experiencia: 'Mestre em cardiologia preventiva.',
      status: 'Em cirurgia',
      crm: 'CRM/PI 98765',
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
      foto: 'https://i.pravatar.cc/150?u=ana',
      experiencia: 'Atendimento humanizado à mulher.',
      status: 'Atendendo agora',
      crm: 'CRM/PI 11223',
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
      foto: 'https://i.pravatar.cc/150?u=joao',
      experiencia: 'Especialista em traumas e lesões esportivas.',
      status: 'Indisponível',
      crm: 'CRM/PI 44556',
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
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            itemCount: _filtrados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _buildProfessionalCard(_filtrados[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCalendar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escala Virtual',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate).toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildHorizontalCalendar(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por médico ou especialidade...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                filled: true,
                fillColor: AppColors.surfaceDim,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 95,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
          
          final dayName = DateFormat('E', 'pt_BR').format(date).toUpperCase().replaceAll('.', '');
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 68,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : (isToday ? AppColors.primary.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : (isToday ? AppColors.primary.withOpacity(0.2) : AppColors.borderDim),
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.top(4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalCard(_Profissional prof) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderDim, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: AppColors.surfaceDim,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: prof.foto != null 
                            ? CachedNetworkImage(
                                imageUrl: prof.foto!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (context, url, error) => const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 40),
                              )
                            : const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 40),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: prof.status == 'Atendendo agora' ? AppColors.success : (prof.status == 'Indisponível' ? AppColors.error : AppColors.warning),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              prof.nome,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prof.especialidade.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRatingBadge(prof.rating),
                            const SizedBox(width: 8),
                            Text(
                              '${prof.totalAvaliacoes} avaliações',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDim.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildIconText(Icons.location_on_rounded, prof.clinica, isBold: true),
                  const SizedBox(height: 10),
                  _buildIconText(Icons.access_time_rounded, 'Plantão: ${prof.horario}'),
                  const SizedBox(height: 10),
                  _buildIconText(Icons.badge_rounded, prof.crm),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Solicitar Agendamento'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13, 
              color: AppColors.textPrimary, 
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textTertiary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum médico escalado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente selecionar outra data ou\naltere sua busca.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
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
  final String status;
  final String crm;
  
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
    required this.status,
    required this.crm,
  });
}
