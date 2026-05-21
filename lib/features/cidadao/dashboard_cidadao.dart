import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

// ── Índice das abas do BottomNav / Drawer ───────────────────────────
enum _Aba { inicio, agendamentos, prontuarios, mensagens, mais }

class HomeCidadaoScreen extends StatefulWidget {
  const HomeCidadaoScreen({super.key});

  @override
  State<HomeCidadaoScreen> createState() => _HomeCidadaoScreenState();
}

class _HomeCidadaoScreenState extends State<HomeCidadaoScreen>
    with SingleTickerProviderStateMixin {
  _Aba _abaAtual = _Aba.inicio;

  // Stagger de entrada da home
  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  // Dados mockados do usuário (substituir por Firestore)
  User? get _user => FirebaseAuth.instance.currentUser;
  String get _firstName {
    final name = _user?.displayName ?? _user?.email ?? 'Usuário';
    return name.split(' ').first;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Stagger helper ──────────────────────────────────────────────
  Widget _stagger(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(
        (i * 0.10).clamp(0.0, 0.5),
        ((i * 0.10) + 0.50).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    final slide = Tween(begin: 20.0, end: 0.0).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(
        (i * 0.10).clamp(0.0, 0.5),
        ((i * 0.10) + 0.50).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    ));
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
          offset: Offset(0, slide.value),
          child: child,
        ),
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────────────
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginCidadaoScreen()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      // Drawer lateral (mobile)
      drawer: isDesktop
          ? null
          : AppDrawer(
              userName: _user?.displayName ?? 'Usuário',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: _abaAtual,
              onAbaChanged: (a) => setState(() => _abaAtual = a),
              onLogout: _logout,
            ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  // ── Layout Desktop ───────────────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        // Drawer fixo lateral
        SizedBox(
          width: 260,
          child: AppDrawer(
            userName: _user?.displayName ?? 'Usuário',
            userEmail: _user?.email ?? '',
            userPhoto: _user?.photoURL,
            abaAtual: _abaAtual,
            onAbaChanged: (a) => setState(() => _abaAtual = a),
            onLogout: _logout,
            isFixed: true,
          ),
        ),
        // Separador
        Container(width: 1, color: const Color(0xFFE2E8F0)),
        // Conteúdo principal
        Expanded(
          child: Column(
            children: [
              AppHeader(
                userName: _firstName,
                userPhoto: _user?.photoURL,
                onLogout: _logout,
                onMenuPressed: null, // sem hamburguer no desktop
              ),
              Expanded(child: _buildConteudo()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Layout Mobile ────────────────────────────────────────────────
  Widget _buildMobile() {
    return Column(
      children: [
        AppHeader(
          userName: _firstName,
          userPhoto: _user?.photoURL,
          onLogout: _logout,
          onMenuPressed: () => Scaffold.of(context).openDrawer(),
        ),
        Expanded(child: _buildConteudo()),
      ],
    );
  }

  // ── Conteúdo scrollável ──────────────────────────────────────────
  Widget _buildConteudo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stagger(0,
                _buildSectionLabel(Icons.show_chart_rounded, 'Resumo rápido')),
            const SizedBox(height: 12),
            _stagger(1, _buildResumoRapido()),
            const SizedBox(height: 28),
            _stagger(
                2,
                _buildSectionLabel(
                    Icons.rocket_launch_rounded, 'Ações rápidas')),
            const SizedBox(height: 12),
            _stagger(3, _buildAcoesRapidas()),
            const SizedBox(height: 28),
            _stagger(
                4,
                _buildSectionLabel(
                  Icons.notifications_none_rounded,
                  'Notificações recentes',
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text('Ver todas',
                        style: TextStyle(
                            color: AppColors.primaryDeep,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 12),
            _stagger(5, _buildNotificacoes()),
          ],
        ),
      ),
    );
  }

  // ── Label de seção ───────────────────────────────────────────────
  Widget _buildSectionLabel(IconData icon, String label, {Widget? trailing}) =>
      Row(children: [
        Icon(icon, color: AppColors.bgMid, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.bgBase)),
        const Spacer(),
        if (trailing != null) trailing,
      ]);

  // ── Resumo rápido (3 cards) ──────────────────────────────────────
  Widget _buildResumoRapido() {
    final cards = [
      _ResumoData(
        icon: Icons.calendar_today_rounded,
        titulo: 'Próximo agendamento',
        valor: '24/05/2025',
        sub: 'Sábado, 09:00',
        rodape: 'UBS Centro',
        rodapeIcon: Icons.location_on_outlined,
        cor: AppColors.bgMid,
      ),
      _ResumoData(
        icon: Icons.verified_user_outlined,
        titulo: 'Situação de vacinação',
        valor: 'Em dia',
        sub: '',
        rodape: 'Tudo certo!',
        rodapeIcon: Icons.check_circle_outline_rounded,
        cor: AppColors.accentDeep,
      ),
      _ResumoData(
        icon: Icons.description_outlined,
        titulo: 'Documentos pendentes',
        valor: '2',
        sub: '',
        rodape: 'Ver documentos',
        rodapeIcon: Icons.arrow_forward_ios_rounded,
        cor: AppColors.primaryDeep,
        onRodapeTap: () {},
      ),
    ];

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 500 ? 3 : 1;
      if (cols == 3) {
        return Row(
            children: cards
                .map((d) => Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ResumoCard(data: d),
                    )))
                .toList());
      }
      return Column(
          children: cards
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResumoCard(data: d),
                  ))
              .toList());
    });
  }

  // ── Ações rápidas (2×2 grid) ────────────────────────────────────
  Widget _buildAcoesRapidas() {
    final acoes = [
      _AcaoData(
        icon: Icons.calendar_month_rounded,
        label: 'Agendar\nconsulta',
        destaque: false,
        onTap: () {},
      ),
      _AcaoData(
        icon: Icons.folder_shared_rounded,
        label: 'Ver meus\nprontuários',
        destaque: false,
        onTap: () {},
      ),
      _AcaoData(
        icon: Icons.groups_rounded,
        label: 'Fila\nvirtual',
        destaque: false,
        onTap: () {},
      ),
      _AcaoData(
        icon: Icons.emergency_rounded,
        label: 'Emergência',
        destaque: true,
        onTap: () {},
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: acoes.map((a) => _AcaoTile(data: a)).toList(),
    );
  }

  // ── Notificações recentes ────────────────────────────────────────
  Widget _buildNotificacoes() {
    final items = [
      _NotifData(
        icon: Icons.calendar_today_rounded,
        titulo: 'Consulta agendada',
        sub:
            'Sua consulta foi agendada para 24/05/2025 às 09:00 na UBS Centro.',
        data: '10/05/2025',
        lida: false,
      ),
      _NotifData(
        icon: Icons.verified_user_outlined,
        titulo: 'Vacinação atualizada',
        sub: 'Seu cartão de vacinação foi atualizado com sucesso.',
        data: '07/05/2025',
        lida: false,
      ),
      _NotifData(
        icon: Icons.description_outlined,
        titulo: 'Documento pendente',
        sub: 'Você tem 2 documentos pendentes. Envie para evitar bloqueios.',
        data: '07/05/2025',
        lida: true,
      ),
    ];

    return Column(
      children: items
          .map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotifCard(data: n),
              ))
          .toList(),
    );
  }

  // ── BottomNavigationBar (mobile) ─────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: BottomNavigationBar(
        currentIndex: _abaAtual.index,
        onTap: (i) => setState(() => _abaAtual = _Aba.values[i]),
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
              icon:
                  _BadgeIcon(icon: Icons.chat_bubble_outline_rounded, count: 2),
              label: 'Mensagens'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded), label: 'Mais'),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  DATA MODELS (internos)
// ───────────────────────────────────────────────────────────────────

class _ResumoData {
  final IconData icon;
  final String titulo, valor, sub, rodape;
  final IconData rodapeIcon;
  final Color cor;
  final VoidCallback? onRodapeTap;
  const _ResumoData({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.sub,
    required this.rodape,
    required this.rodapeIcon,
    required this.cor,
    this.onRodapeTap,
  });
}

class _AcaoData {
  final IconData icon;
  final String label;
  final bool destaque;
  final VoidCallback onTap;
  const _AcaoData(
      {required this.icon,
      required this.label,
      required this.destaque,
      required this.onTap});
}

class _NotifData {
  final IconData icon;
  final String titulo, sub, data;
  final bool lida;
  const _NotifData(
      {required this.icon,
      required this.titulo,
      required this.sub,
      required this.data,
      required this.lida});
}

// ───────────────────────────────────────────────────────────────────
//  CARD DE RESUMO
// ───────────────────────────────────────────────────────────────────

class _ResumoCard extends StatelessWidget {
  final _ResumoData data;
  const _ResumoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.cor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.cor, size: 22),
          ),
          const SizedBox(height: 12),
          // Título
          Text(data.titulo,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          // Valor
          Text(data.valor,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bgBase)),
          if (data.sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(data.sub,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 12),
          // Rodapé
          GestureDetector(
            onTap: data.onRodapeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: data.cor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(data.rodapeIcon, size: 13, color: data.cor),
                const SizedBox(width: 5),
                Text(data.rodape,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: data.cor)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  TILE DE AÇÃO RÁPIDA
// ───────────────────────────────────────────────────────────────────

class _AcaoTile extends StatelessWidget {
  final _AcaoData data;
  const _AcaoTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = data.destaque ? AppColors.bgMid : Colors.white;
    final fg = data.destaque ? Colors.white : AppColors.bgBase;
    final iconBg = data.destaque
        ? Colors.white.withOpacity(0.15)
        : AppColors.bgMid.withOpacity(0.08);

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  data.destaque ? Colors.transparent : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: data.destaque
                    ? AppColors.bgMid.withOpacity(0.25)
                    : const Color(0x08000000),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon,
                color: data.destaque ? Colors.white : AppColors.bgMid,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(data.label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.3)),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14,
              color: data.destaque ? Colors.white70 : const Color(0xFF94A3B8)),
        ]),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  CARD DE NOTIFICAÇÃO
// ───────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final _NotifData data;
  const _NotifCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ícone
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgMid.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(data.icon, color: AppColors.bgMid, size: 18),
        ),
        const SizedBox(width: 12),
        // Texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(data.titulo,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.bgBase)),
                ),
                Text(data.data,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF94A3B8))),
                if (!data.lida) ...[
                  const SizedBox(width: 6),
                  Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: AppColors.primaryDeep,
                          shape: BoxShape.circle)),
                ],
              ]),
              const SizedBox(height: 4),
              Text(data.sub,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
//  BADGE ICON (BottomNav com contador)
// ───────────────────────────────────────────────────────────────────

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (count > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AppColors.primaryDeep, shape: BoxShape.circle),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      );
}
