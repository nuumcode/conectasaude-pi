// lib/features/cidadao/minha_fila/cidadao_fila_screen.dart
//
// Fila Virtual do Cidadão — agora ouvindo o Firestore em tempo real.
// A posição é calculada a partir do snapshot completo da fila;
// quando o atendente muda algo no posto, esta tela atualiza sozinha.
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/fila_service.dart';
class CidadaoFilaScreen extends StatefulWidget {
  const CidadaoFilaScreen({super.key});
  @override
  State<CidadaoFilaScreen> createState() => _CidadaoFilaScreenState();
}
class _CidadaoFilaScreenState extends State<CidadaoFilaScreen>
    with TickerProviderStateMixin {
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
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final isSmall = screenW < 360;
    final isLarge = screenW > 420;
    final hPad = screenW * 0.05 < 16 ? 16.0 : screenW * 0.05;
    final circleSize = (screenW * 0.42).clamp(130.0, 200.0);
    return Scaffold(
      backgroundColor: _bgMain,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        elevation: 0,
        title: Text('Fila Virtual',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
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
                                  isLarge: isLarge,
                                  screenH: screenH,
                                  circleSize: circleSize,
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
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
    return idx + 1; // 1-based
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
        _buildLogoSection(isSmall),
        SizedBox(height: screenH * 0.018),
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
        Container(
          width: isSmall ? 34 : 40,
          height: isSmall ? 34 : 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [AppColors.navyMid, AppColors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded,
              color: Colors.white, size: isSmall ? 18 : 22),
        ),
        SizedBox(width: isSmall ? 8 : 10),
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
            child: Icon(Icons.close, size: 18, color: _textMuted),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: const Text('Cancelar',
                  style: TextStyle(color: _textMuted))),
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
//  Painters (mantidos do original)
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
