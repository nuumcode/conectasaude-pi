// lib/features/cidadao/minha_fila/cidadao_fila_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/dashboard_cidadao.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_escala_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/perfil_screen.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import '../../services/fila_service.dart';

class CidadaoFilaScreen extends StatefulWidget {
  const CidadaoFilaScreen({super.key});
  @override
  State<CidadaoFilaScreen> createState() => _CidadaoFilaScreenState();
}

class _CidadaoFilaScreenState extends State<CidadaoFilaScreen>
    with TickerProviderStateMixin {
  // ── Layout / scaffold ──────────────────────────────────────────
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _abaDestaScreen = DrawerAba.fila;
  // ── Fila ───────────────────────────────────────────────────────
  final _fila = FilaService.instance;
  bool _bannerVisivel = true;
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  // Cores auxiliares
  static const _blueBg = Color(0xFFEDF4FF);
  static const _blueCard = Color(0xFFF5F9FF);
  static const _bgMain = Color(0xFFF0F5FC);
  static const _textDark = Color(0xFF1A2138);
  static const _textMuted = Color(0xFF7B8794);
  static const _dividerColor = Color(0xFFDDE5EF);
  // ── Auth ───────────────────────────────────────────────────────
  User? get _user => FirebaseAuth.instance.currentUser;
  String? get _userId => _user?.uid;
  String get _firstName {
    final name = _user?.displayName ?? _user?.email ?? 'Usuário';
    return name.split(' ').first;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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

  Widget? _resolverAba(dynamic aba) {
    switch (aba) {
      case DrawerAba.inicio:
        return const HomeCidadaoScreen();
      case DrawerAba.agendamentos:
        return const CidadaoEscalaScreen();
      case DrawerAba.fila:
        return const CidadaoFilaScreen();
      case DrawerAba.perfil:
        return const PerfilScreen();
      default:
        return null;
    }
  }

  // ── Build ────────────────────────────────────────────────────────
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: BottomNavigationBar(
        currentIndex:
            2, // índice da aba Fila — ajuste se o seu BottomNav usar outra posição
        onTap: (i) {
          const mapa = [
            DrawerAba.inicio,
            DrawerAba.agendamentos,
            DrawerAba.fila,
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
              icon: Icon(Icons.groups_rounded), label: 'Fila'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Mensagens'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded), label: 'Mais'),
        ],
      ),
    );
  }

  // ── Conteúdo (lógica da fila preservada) ─────────────────────────
  Widget _buildConteudo() {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final isSmall = screenW < 360;
    final hPad = screenW * 0.05 < 16 ? 16.0 : screenW * 0.05;
    final circleSize = (screenW * 0.42).clamp(130.0, 200.0);
    return Container(
      color: _bgMain,
      child: _userId == null
          ? const Center(
              child: Text('Você precisa estar autenticado.',
                  style: TextStyle(fontFamily: 'Poppins')))
          : StreamBuilder<List<PacienteNaFila>>(
              stream: _fila.streamFila(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erro ao carregar a fila: ${snap.error}',
                        style: const TextStyle(fontFamily: 'Poppins'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final fila = snap.data ?? const [];
                final meuPaciente =
                    fila.where((p) => p.userId == _userId).firstOrNull;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: screenH * 0.02,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - (screenH * 0.04),
                        ),
                        child: meuPaciente == null
                            ? _buildSemSenha(isSmall, screenH)
                            : _buildComSenha(
                                meuPaciente: meuPaciente,
                                fila: fila,
                                isSmall: isSmall,
                                isLarge: screenW > 420,
                                screenH: screenH,
                                circleSize: circleSize,
                              ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // ── Posição calculada a partir do snapshot ─────────────────
  int _calcularPosicao(PacienteNaFila meu, List<PacienteNaFila> fila) {
    if (meu.status == StatusFila.emAtendimento) return 0;
    if (meu.status != StatusFila.aguardando) return -1;
    final aguardando = fila
        .where((p) => p.status == StatusFila.aguardando)
        .toList()
      ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));
    final idx = aguardando.indexWhere((p) => p.id == meu.id);
    return idx + 1;
  }

  // ─────────────────────────────────────────────────────────────
  //  Tela quando o cidadão AINDA NÃO PEGOU senha
  // ─────────────────────────────────────────────────────────────
  Widget _buildSemSenha(bool isSmall, double screenH) {
    return Column(
      children: [
        SizedBox(height: screenH * 0.04),
        Icon(Icons.confirmation_number_outlined,
            size: 80, color: AppColors.blue.withOpacity(0.7)),
        const SizedBox(height: 16),
        const Text(
          'Você ainda não está na fila',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pegue uma senha para começar a acompanhar sua posição em tempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _textMuted,
            ),
          ),
        ),
        SizedBox(height: screenH * 0.04),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _pegarSenha,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Pegar Senha',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.blue.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pegarSenha() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _fila.entrarNaFila(
        nome: user.displayName ?? user.email ?? 'Cidadão',
        especialidade: 'Clínica Geral',
        userId: user.uid,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar na fila: $e')),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Tela quando JÁ TEM senha
  // ─────────────────────────────────────────────────────────────
  Widget _buildComSenha({
    required PacienteNaFila meuPaciente,
    required List<PacienteNaFila> fila,
    required bool isSmall,
    required bool isLarge,
    required double screenH,
    required double circleSize,
  }) {
    final posicao = _calcularPosicao(meuPaciente, fila);
    final foiChamado = meuPaciente.status == StatusFila.emAtendimento;
    final totalFila =
        fila.where((p) => p.status == StatusFila.aguardando).length +
            (foiChamado ? 1 : 0);
    final progresso = totalFila == 0
        ? 1.0
        : ((totalFila - posicao).clamp(0, totalFila)) / totalFila;
    return Column(
      children: [
        SizedBox(height: screenH * 0.015),
        if (_bannerVisivel) _buildNotificacaoBanner(isSmall),
        if (_bannerVisivel) SizedBox(height: screenH * 0.025),
        _buildPosicaoCircular(
          circleSize: circleSize,
          isSmall: isSmall,
          posicao: posicao,
          progresso: progresso.toDouble(),
          foiChamado: foiChamado,
          senha: meuPaciente.senha,
        ),
        SizedBox(height: screenH * 0.025),
        _buildInfoRow(
          isSmall: isSmall,
          isLarge: isLarge,
          tempoEstimado: posicao * 5,
          especialidade: meuPaciente.especialidade,
          foiChamado: foiChamado,
        ),
        SizedBox(height: screenH * 0.022),
        _buildPessoasAFrente(meuPaciente, fila, isSmall),
        SizedBox(height: screenH * 0.018),
        _buildRealTimeCard(isSmall),
        SizedBox(height: screenH * 0.028),
        _buildBotaoSairFila(meuPaciente, isSmall),
        SizedBox(height: screenH * 0.01),
        Text(
          'Você pode voltar à fila a qualquer momento.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isSmall ? 10 : 11,
            color: _textMuted,
          ),
        ),
        SizedBox(height: screenH * 0.02),
      ],
    );
  }

  // ── Logo ────────────────────────────────────────────────────
  Widget _buildLogoSection(bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(
                text: 'Conecta',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 14 : 17,
                  fontWeight: FontWeight.w300,
                  color: _textDark,
                  height: 1.2,
                )),
            TextSpan(
                text: '\nSaúde',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 14 : 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                  height: 1.3,
                )),
            TextSpan(
                text: 'PI',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 14 : 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  height: 1.3,
                )),
          ]),
        ),
      ],
    );
  }

  Widget _buildNotificacaoBanner(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmall ? 28 : 32,
            height: isSmall ? 28 : 32,
            decoration: const BoxDecoration(
              color: AppColors.navyDeep,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active,
                size: isSmall ? 14 : 16, color: Colors.white),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(
            child: Text(
              'Você será notificado quando chegar sua vez.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _bannerVisivel = false),
            child: const Icon(Icons.close, size: 18, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPosicaoCircular({
    required double circleSize,
    required bool isSmall,
    required int posicao,
    required double progresso,
    required bool foiChamado,
    required String senha,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmall ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            foiChamado ? 'Sua senha:' : 'Sua Posição:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          SizedBox(height: isSmall ? 14 : 20),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: progresso,
                        strokeWidth: isSmall ? 6 : 8,
                        bgColor: _blueBg,
                        fgColor: AppColors.blue,
                        glowOpacity: 0.1 + _pulseCtrl.value * 0.08,
                      ),
                    ),
                  ),
                  foiChamado
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppColors.success,
                                size: circleSize * 0.25),
                            const SizedBox(height: 4),
                            Text('SUA VEZ!',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: circleSize * 0.09,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                )),
                            Text(senha,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: circleSize * 0.08,
                                  fontWeight: FontWeight.w600,
                                  color: _textMuted,
                                )),
                          ],
                        )
                      : RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [
                            TextSpan(
                              text: '$posicao',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: circleSize * 0.32,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                                height: 1.1,
                              ),
                            ),
                            TextSpan(
                              text: 'º',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: circleSize * 0.13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue,
                                height: 1.0,
                              ),
                            ),
                          ]),
                        ),
                ],
              ),
            ),
          ),
          SizedBox(height: isSmall ? 8 : 12),
          if (!foiChamado)
            Text(
              'na fila  •  Senha $senha',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
          if (foiChamado)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Dirija-se ao consultório',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isSmall ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required bool isSmall,
    required bool isLarge,
    required int tempoEstimado,
    required String especialidade,
    required bool foiChamado,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 14 : 18,
        horizontal: isSmall ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _infoColumn(
                Icons.access_time_rounded,
                'Tempo Estimado',
                '$tempoEstimado',
                'minutos',
                AppColors.blue,
                isSmall,
              ),
            ),
            _buildDottedDivider(),
            Expanded(
              child: _infoColumn(
                Icons.medical_services_outlined,
                'Especialidade',
                especialidade,
                '',
                _textDark,
                isSmall,
              ),
            ),
            _buildDottedDivider(),
            Expanded(child: _infoColumnStatus(isSmall, foiChamado)),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedDivider() => CustomPaint(
        size: const Size(1, 50),
        painter: _DottedLinePainter(color: _dividerColor),
      );
  Widget _infoColumn(IconData icon, String label, String value, String sublabel,
      Color iconColor, bool isSmall) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isSmall ? 16 : 20, color: iconColor),
        SizedBox(height: isSmall ? 4 : 6),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 9 : 10,
              color: _textMuted,
            )),
        SizedBox(height: isSmall ? 2 : 4),
        Text(value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
        if (sublabel.isNotEmpty)
          Text(sublabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 9 : 10,
                color: _textMuted,
              )),
      ],
    );
  }

  Widget _infoColumnStatus(bool isSmall, bool foiChamado) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isSmall ? 8 : 10,
          height: isSmall ? 8 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(height: isSmall ? 4 : 6),
        Text('Status',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 9 : 10,
              color: _textMuted,
            )),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          foiChamado ? 'Chamado' : 'Ativo',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isSmall ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
        Text(
          foiChamado ? 'É sua vez!' : 'Fila ativa',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isSmall ? 8 : 9,
            color: _textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPessoasAFrente(
      PacienteNaFila meu, List<PacienteNaFila> fila, bool isSmall) {
    if (meu.status != StatusFila.aguardando) return const SizedBox.shrink();
    final aguardando = fila
        .where((p) => p.status == StatusFila.aguardando)
        .toList()
      ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));
    final meuIdx = aguardando.indexWhere((p) => p.id == meu.id);
    if (meuIdx <= 0) return const SizedBox.shrink();
    final aFrente = aguardando.sublist(0, meuIdx).take(3).toList();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pessoas à sua frente:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: _textDark,
              )),
          const SizedBox(height: 6),
          const Divider(color: _dividerColor, height: 1),
          const SizedBox(height: 10),
          ...aFrente.asMap().entries.map(
                (e) => _buildPessoaItem(e.key + 1, e.value.senha, isSmall),
              ),
        ],
      ),
    );
  }

  Widget _buildPessoaItem(int posicao, String senha, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: isSmall ? 30 : 34,
            height: isSmall ? 30 : 34,
            decoration: const BoxDecoration(
              color: _blueBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded,
                size: isSmall ? 15 : 17, color: AppColors.blue),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Senha $senha',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    )),
                Text('Posição: $posicao',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 9 : 10,
                      color: _textMuted,
                    )),
              ],
            ),
          ),
          Icon(Icons.monitor_heart_outlined,
              size: isSmall ? 18 : 20, color: AppColors.blueLt),
        ],
      ),
    );
  }

  Widget _buildRealTimeCard(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: _blueCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueLt.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart_outlined,
              size: isSmall ? 20 : 24, color: AppColors.blue),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atualizações em tempo real',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    )),
                const SizedBox(height: 2),
                Text(
                    'Conectado ao posto. Esta página atualiza automaticamente quando o atendente chama um paciente.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 9 : 10,
                      color: _textMuted,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoSairFila(PacienteNaFila pac, bool isSmall) {
    return SizedBox(
      width: double.infinity,
      height: isSmall ? 46 : 52,
      child: ElevatedButton.icon(
        onPressed: () => _confirmarSaida(pac),
        icon: Icon(Icons.exit_to_app_rounded, size: isSmall ? 16 : 18),
        label: Text('Sair da Fila',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 13 : 14,
              fontWeight: FontWeight.w600,
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.blue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarSaida(PacienteNaFila pac) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da fila?',
            style: TextStyle(
              color: _textDark,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            )),
        content: const Text(
          'Você perderá sua posição na fila. Poderá entrar novamente depois.',
          style: TextStyle(
            color: _textMuted,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancelar', style: TextStyle(color: _textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sim, sair',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ))),
        ],
      ),
    );
    if (ok == true) {
      await _fila.sairDaFila(pac.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Painters
// ─────────────────────────────────────────────────────────────
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color bgColor;
  final Color fgColor;
  final double glowOpacity;
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.bgColor,
    required this.fgColor,
    required this.glowOpacity,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
    if (progress > 0) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);
      final glowPaint = Paint()
        ..color = fgColor.withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(endX, endY), strokeWidth * 1.2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.glowOpacity != glowOpacity;
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashH = 3.0;
    const gapH = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashH),
        paint,
      );
      startY += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}
