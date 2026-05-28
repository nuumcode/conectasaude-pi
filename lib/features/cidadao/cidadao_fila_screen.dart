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
            userName: _firstName,
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
        userName: _firstName,
        userPhoto: _user?.photoURL,
        onLogout: () {},
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
      ),
      Expanded(child: _buildConteudo()),
    ]);
  }

  Widget _buildConteudo() {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final hPad = (screenW * 0.05).clamp(16.0, 24.0);
    final circleSize = (screenW * 0.45).clamp(150.0, 230.0);

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
                
                final meuPaciente = meuSnap.data;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(),
                      const SizedBox(height: 24),
                      if (meuPaciente == null)
                        _buildSemSenhaFlow()
                      else
                        StreamBuilder<List<PacienteNaFila>>(
                          stream: _fila.streamFila(),
                          builder: (context, filaSnap) {
                            final fila = filaSnap.data ?? const <PacienteNaFila>[];
                            return _buildComSenha(
                              meuPaciente: meuPaciente,
                              fila: fila,
                              circleSize: circleSize,
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeaderTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fila de Atendimento',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Gerencie sua vez e acompanhe o progresso.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNaoAutenticado() {
    return const Center(child: Text('Por favor, faça login para continuar.'));
  }

  Widget _buildSemSenhaFlow() {
    return Column(
      children: [
        _buildQuickInfoCard(
          'Agendamento Imediato',
          'Solicite sua senha agora para atendimento clínico.',
          Icons.flash_on_rounded,
          AppColors.primary,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderDim),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nova Solicitação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _buildSelectionField('Unidade de Saúde', 'UBS Novo Oriente'),
              const SizedBox(height: 16),
              _buildSelectionField('Especialidade', 'Clínica Geral'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loadingEntrar ? null : _pegarSenha,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loadingEntrar
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRMAR E GERAR SENHA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDim),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pegarSenha() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loadingEntrar = true);
    
    // Delay realista de 1.5 segundos para simular processamento
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      await _fila.entrarNaFila(
        nome: user.displayName ?? user.email ?? 'Cidadão',
        especialidade: 'Clínica Geral',
        userId: user.uid,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _loadingEntrar = false);
    }
  }

  Widget _buildComSenha({
    required PacienteNaFila meuPaciente,
    required List<PacienteNaFila> fila,
    required double circleSize,
  }) {
    final posicao = FilaService.posicaoNaFila(meuPaciente, fila);
    final foiChamado = meuPaciente.status == StatusFila.emAtendimento;
    final totalFila = fila.where((p) => p.status == StatusFila.aguardando).length + (foiChamado ? 1 : 0);
    final progresso = (totalFila == 0 || posicao <= 0) ? 1.0 : ((totalFila - posicao).clamp(0, totalFila)) / totalFila;

    return Column(
      children: [
        _buildQuickInfoCard(
          foiChamado ? 'Sua Vez Chegou!' : 'Status da Solicitação',
          foiChamado ? 'Dirija-se ao consultório agora.' : 'Acompanhe seu lugar na fila abaixo.',
          foiChamado ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          foiChamado ? AppColors.success : AppColors.primary,
        ),
        const SizedBox(height: 32),
        _buildGlowCircle(circleSize, progresso, foiChamado, meuPaciente.senha, posicao),
        const SizedBox(height: 40),
        _buildDetailedInfoGrid(meuPaciente, posicao, foiChamado),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _confirmarSaida(meuPaciente),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('CANCELAR SOLICITAÇÃO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowCircle(double size, double progress, bool called, String senha, int pos) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (called ? AppColors.success : AppColors.primary).withOpacity(0.1 + _pulseCtrl.value * 0.1),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progress,
                  strokeWidth: 14,
                  bgColor: AppColors.surfaceDim,
                  fgColor: called ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(called ? 'SENHA' : 'POSIÇÃO', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                Text(
                  called ? senha : (pos > 0 ? '$posº' : '—'),
                  style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w900, color: called ? AppColors.success : AppColors.textPrimary, height: 1.1),
                ),
                if (!called)
                  Text('Senha $senha', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInfoGrid(PacienteNaFila meu, int pos, bool called) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          _infoDetailRow(Icons.local_hospital_rounded, 'Unidade', 'UBS Novo Oriente'),
          const Divider(height: 32, color: AppColors.borderDim),
          _infoDetailRow(Icons.person_rounded, 'Médico de Plantão', 'Dr. Ricardo Silva'),
          const Divider(height: 32, color: AppColors.borderDim),
          _infoDetailRow(Icons.medical_services_rounded, 'Especialidade', meu.especialidade),
          const Divider(height: 32, color: AppColors.borderDim),
          _infoDetailRow(Icons.timer_rounded, 'Estimativa', called ? 'Sua Vez!' : '${pos * 6} min'),
        ],
      ),
    );
  }

  Widget _infoDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuickInfoCard(String title, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
                Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSaida(PacienteNaFila pac) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar Solicitação?'),
        content: const Text('Você perderá seu lugar na fila e sua senha atual será invalidada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('MANTER')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CANCELAR AGORA', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) await _fila.sairDaFila(pac.id);
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color bgColor;
  final Color fgColor;

  _ProgressRingPainter({required this.progress, required this.strokeWidth, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final bgPaint = Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    if (progress <= 0) return;
    final fgPaint = Paint()..color = fgColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}