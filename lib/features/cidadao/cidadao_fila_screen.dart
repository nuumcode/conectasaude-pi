import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/dashboard_cidadao.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_escala_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/perfil_screen.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../services/fila_service.dart';

class CidadaoFilaScreen extends StatefulWidget {
  const CidadaoFilaScreen({super.key});

  @override
  State<CidadaoFilaScreen> createState() => _CidadaoFilaScreenState();
}

class _CidadaoFilaScreenState extends State<CidadaoFilaScreen>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _abaDestaScreen = DrawerAba.fila;
  final _fila = FilaService.instance;

  bool _loadingEntrar = false;
  bool _bannerVisivel = true;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

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
        currentIndex: 2,
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
              icon: Icon(Icons.emergency_rounded),
              label: 'SOS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final isSmall = screenW < 360;
    final hPad = (screenW * 0.05).clamp(16.0, double.infinity);
    final circleSize = (screenW * 0.42).clamp(130.0, 200.0);

    return Container(
      color: AppColors.bgBase,
      child: _userId == null
          ? _buildNaoAutenticado()
          : StreamBuilder<PacienteNaFila?>(
              stream: _fila.streamMeuPaciente(_userId!),
              builder: (context, meuSnap) {
                if (meuSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (meuSnap.hasError) {
                  return _buildErro(meuSnap.error);
                }

                final meuPaciente = meuSnap.data;

                if (meuPaciente == null) {
                  return LayoutBuilder(
                    builder: (_, constraints) => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: hPad, vertical: screenH * 0.02),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight - (screenH * 0.04)),
                        child: _buildSemSenha(isSmall, screenH),
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<PacienteNaFila>>(
                  stream: _fila.streamFila(),
                  builder: (context, filaSnap) {
                    final fila = filaSnap.data ?? const <PacienteNaFila>[];

                    return LayoutBuilder(
                      builder: (_, constraints) => SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: screenH * 0.02),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight:
                                  constraints.maxHeight - (screenH * 0.04)),
                          child: _buildComSenha(
                            meuPaciente: meuPaciente,
                            fila: fila,
                            isSmall: isSmall,
                            isLarge: screenW > 420,
                            screenH: screenH,
                            circleSize: circleSize,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildErro(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Erro ao carregar a fila:\n$error',
          style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNaoAutenticado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 64, color: AppColors.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'Você precisa estar autenticado',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Faça login novamente para acompanhar sua posição na fila.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Ir para o login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemSenha(bool isSmall, double screenH) {
    return Column(
      children: [
        SizedBox(height: screenH * 0.04),
        Icon(Icons.confirmation_number_outlined,
            size: 80, color: AppColors.primary.withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text(
          'Você ainda não está na fila',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: screenH * 0.04),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _loadingEntrar ? null : _pegarSenha,
            icon: _loadingEntrar
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(_loadingEntrar ? 'Aguarde...' : 'Pegar Senha'),
          ),
        ),
      ],
    );
  }

  Future<void> _pegarSenha() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_loadingEntrar) return;
    setState(() => _loadingEntrar = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _fila.entrarNaFila(
        nome: user.displayName ?? user.email ?? 'Cidadão',
        especialidade: 'Clínica Geral',
        userId: user.uid,
      );
    } on JaNaFilaException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(e.message, style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao entrar na fila: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingEntrar = false);
    }
  }

  Widget _buildComSenha({
    required PacienteNaFila meuPaciente,
    required List<PacienteNaFila> fila,
    required bool isSmall,
    required bool isLarge,
    required double screenH,
    required double circleSize,
  }) {
    final posicao = FilaService.posicaoNaFila(meuPaciente, fila);
    final foiChamado = meuPaciente.status == StatusFila.emAtendimento;

    final totalFila =
        fila.where((p) => p.status == StatusFila.aguardando).length +
            (foiChamado ? 1 : 0);

    final progresso = (totalFila == 0 || posicao <= 0)
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
          progresso: progresso,
          foiChamado: foiChamado,
          senha: meuPaciente.senha,
        ),
        SizedBox(height: screenH * 0.025),
        _buildInfoRow(
          isSmall: isSmall,
          isLarge: isLarge,
          tempoEstimado: posicao > 0 ? posicao * 5 : null,
          especialidade: meuPaciente.especialidade,
          foiChamado: foiChamado,
        ),
        SizedBox(height: screenH * 0.022),
        _buildPessoasAFrente(meuPaciente, fila, isSmall),
        SizedBox(height: screenH * 0.018),
        _buildRealTimeCard(isSmall),
        SizedBox(height: screenH * 0.028),
        _buildBotaoSairFila(meuPaciente, isSmall),
        const SizedBox(height: 12),
        Text(
          'Você pode voltar à fila a qualquer momento.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isSmall ? 10 : 11,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: screenH * 0.02),
      ],
    );
  }

  Widget _buildNotificacaoBanner(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active,
                size: isSmall ? 14 : 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Você será notificado quando chegar sua vez.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _bannerVisivel = false),
            child: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
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
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              color: AppColors.textSecondary,
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
                        bgColor: AppColors.surfaceDim,
                        fgColor: AppColors.primary,
                        glowOpacity: 0.1 + _pulseCtrl.value * 0.08,
                      ),
                    ),
                  ),
                  foiChamado
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.success,
                                size: 48),
                            const SizedBox(height: 4),
                            Text(
                              'SUA VEZ!',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: circleSize * 0.09,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        )
                      : RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [
                            TextSpan(
                              text: posicao > 0 ? '$posicao' : '—',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: circleSize * 0.32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            if (posicao > 0)
                              const TextSpan(
                                text: 'º',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
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
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
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
              child: const Text(
                'Dirija-se ao consultório',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
    required int? tempoEstimado,
    required String especialidade,
    required bool foiChamado,
  }) {
    final tempoLabel =
        (tempoEstimado != null && tempoEstimado > 0) ? '$tempoEstimado' : '—';
    final tempoSublabel =
        (tempoEstimado != null && tempoEstimado > 0) ? 'minutos' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                'Estimativa',
                tempoLabel,
                tempoSublabel,
                AppColors.primary,
                isSmall,
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.borderDim),
            Expanded(
              child: _infoColumn(
                Icons.medical_services_outlined,
                'Serviço',
                especialidade,
                '',
                AppColors.textPrimary,
                isSmall,
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.borderDim),
            Expanded(child: _infoColumnStatus(isSmall, foiChamado)),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(IconData icon, String label, String value, String sublabel,
      Color iconColor, bool isSmall) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isSmall ? 16 : 18, color: iconColor),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }

  Widget _infoColumnStatus(bool isSmall, bool foiChamado) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('Status',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 2),
        Text(
          foiChamado ? 'Chamado' : 'Ativo',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próximos na Fila',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...aFrente.asMap().entries.map(
                (e) => _buildPessoaItem(e.key + 1, e.value.senha, isSmall),
              ),
        ],
      ),
    );
  }

  Widget _buildPessoaItem(int posicao, String senha, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Senha $senha',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.trending_up_rounded,
              size: 16, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildRealTimeCard(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.sync_rounded, size: 22, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atualizações Automáticas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Acompanhe sua vez sem precisar atualizar a página.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoSairFila(PacienteNaFila pac, bool isSmall) {
    return OutlinedButton.icon(
      onPressed: () => _confirmarSaida(pac),
      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
      label: const Text('SAIR DA FILA'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Future<void> _confirmarSaida(PacienteNaFila pac) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da fila?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text('Você perderá sua posição atual e precisará pegar uma nova senha depois.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIM, SAIR', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok == true) {
      await _fila.sairDaFila(pac.id);
    }
  }
}

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

    if (progress <= 0) return;

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

    final endAngle = -math.pi / 2 + sweepAngle;
    final endX = center.dx + radius * math.cos(endAngle);
    final endY = center.dy + radius * math.sin(endAngle);
    final glowPaint = Paint()
      ..color = fgColor.withOpacity(glowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(endX, endY), strokeWidth * 1.2, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.glowOpacity != glowOpacity;
}
