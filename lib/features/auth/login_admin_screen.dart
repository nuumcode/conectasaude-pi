// ═══════════════════════════════════════════════════════════════════
//  login_admin_screen.dart  —  ConectaSaúdePI
//
//  LÓGICA DE ACESSO ADMIN:
//    1. Admin digita apenas o USUÁRIO (ex: "joao.silva")
//    2. Sistema compõe o e-mail: joao.silva@admin.conectasaudepi
//    3. Firebase Auth valida usuário + senha
//    4. Firestore verifica: usuarios/{uid}.perfil == 'admin'
//    5. Se admin → /admin/home  |  Se não → erro de acesso negado
//
//  COMO CADASTRAR UM ADMIN (você faz isso manualmente):
//    1. Firebase Console → Authentication → Add user
//       E-mail: joao.silva@admin.conectasaudepi
//       Senha:  (defina você)
//    2. Firestore → usuarios → {uid} → criar documento:
//       {
//         "nome": "João Silva",
//         "perfil": "admin",
//         "cargo": "Secretário de Saúde",   // opcional
//         "uid": "{uid}",
//         "email": "joao.silva@admin.conectasaudepi"
//       }
//
//  DOMÍNIO FAKE: @admin.conectasaudepi
//    Nunca aparece na tela — só interno no sistema.
//    O admin só vê/digita o "usuário" (parte antes do @)
//
//  DEPENDÊNCIAS: firebase_auth, cloud_firestore, app_theme, app_animations
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

// Domínio interno — invisível ao usuário
const _kDominio = '@admin.conectasaudepi';

// ───────────────────────────────────────────────────────────────────
class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});
  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController(); // só o "usuário" sem @dominio
  final _senhaCtrl = TextEditingController();

  bool _senhaVis = false;
  bool _loading = false;
  String? _erro;

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Anima entrada do formulário
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _senhaCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Stagger helper ─────────────────────────────────────────────
  Widget _s(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(
        (i * 0.15).clamp(0.0, 0.5),
        ((i * 0.15) + 0.55).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    final slide = Tween(begin: 18.0, end: 0.0).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(
        (i * 0.15).clamp(0.0, 0.5),
        ((i * 0.15) + 0.55).clamp(0.0, 1.0),
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

  // ── Verificação de perfil admin no Firestore ───────────────────
  Future<bool> _verificarAdmin(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      return doc.exists && doc.data()?['perfil'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────
  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _erro = null;
    });

    // Compõe o e-mail interno com o domínio fake
    final usuario = _usuarioCtrl.text.trim().toLowerCase();
    final emailInterno = '$usuario$_kDominio';

    try {
      // 1. Autentica no Firebase
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailInterno,
        password: _senhaCtrl.text,
      );

      // 2. Verifica perfil admin no Firestore
      final isAdmin = await _verificarAdmin(cred.user!.uid);

      if (!isAdmin) {
        // Loga mas não tem perfil admin — desloga e nega acesso
        await FirebaseAuth.instance.signOut();
        setState(() {
          _erro =
              'Acesso negado. Este usuário não tem permissão de administrador.';
          _loading = false;
        });
        return;
      }

      // 3. Registra último acesso
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'ultimoAcesso': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Não bloqueia o acesso
      }

      // 4. Redireciona para o painel admin
      if (mounted) Navigator.of(context).pushReplacementNamed('/admin/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } catch (_) {
      setState(() => _erro = 'Erro ao conectar. Verifique sua rede.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Tradução de erros ──────────────────────────────────────────
  String _traduzirErro(String code) => switch (code) {
        'user-not-found' => 'Usuário não encontrado.',
        'wrong-password' => 'Senha incorreta.',
        'invalid-credential' => 'Usuário ou senha inválidos.',
        'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
        'network-request-failed' => 'Sem conexão. Verifique sua rede.',
        'user-disabled' => 'Este acesso foi desativado.',
        _ => 'Falha na autenticação. Tente novamente.',
      };

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(children: [
        // Fundo — mais sóbrio que o cidadão (sem orbs coloridos)
        _buildFundo(),

        // Linha topo
        const Positioned(top: 0, left: 0, right: 0, child: AppTopLine()),

        // Conteúdo centralizado
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 56),

                      // ── Ícone de cadeado + identidade ───────────
                      _s(0, _buildIdentidade()),
                      const SizedBox(height: 36),

                      // ── Título ──────────────────────────────────
                      _s(1, _buildTitulo()),
                      const SizedBox(height: 28),

                      // ── Erro ────────────────────────────────────
                      if (_erro != null) ...[
                        _s(1, _buildErroBox()),
                        const SizedBox(height: 12),
                      ],

                      // ── Campo: usuário ──────────────────────────
                      _s(2, _buildCampoUsuario()),
                      const SizedBox(height: 14),

                      // ── Campo: senha ────────────────────────────
                      _s(2, _buildCampoSenha()),
                      const SizedBox(height: 28),

                      // ── Botão entrar ────────────────────────────
                      _s(3, _buildBotaoEntrar()),
                      const SizedBox(height: 32),

                      // ── Rodapé ──────────────────────────────────
                      _s(4, _buildRodape()),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Fundo sóbrio (mais escuro, menos orbs) ─────────────────────
  Widget _buildFundo() {
    return Positioned.fill(
      child: Stack(children: [
        // Gradiente mais fechado — aspecto corporativo
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.2,
              colors: [Color(0xFF0A1B4A), AppColors.bgBase],
            ),
          ),
        ),
        // Linhas de grade sutis (aspecto de painel de sistema)
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),
        // Pontinho de luz no topo — discreto
        Positioned(
          top: -120,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Identidade visual (cadeado + logo) ─────────────────────────
  Widget _buildIdentidade() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cadeado animado
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.25), width: 1.5),
            color: AppColors.primary.withOpacity(0.06),
          ),
          child: Stack(alignment: Alignment.center, children: [
            // Glow de fundo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
            const Icon(
              Icons.lock_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Nome do sistema
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: [
            const TextSpan(
              text: 'Conecta',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: -0.3),
            ),
            TextSpan(
              text: 'Saúde',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueLt,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                        color: AppColors.blueLt.withOpacity(0.4),
                        blurRadius: 10)
                  ]),
            ),
            TextSpan(
              text: 'PI',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenLt,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                        color: AppColors.greenLt.withOpacity(0.5),
                        blurRadius: 10)
                  ]),
            ),
          ]),
        ),

        const SizedBox(height: 4),

        // Badge "Painel Administrativo"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.20)),
            color: AppColors.primary.withOpacity(0.06),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_outlined,
                size: 11, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 5),
            Text(
              'PAINEL ADMINISTRATIVO',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withOpacity(0.7),
                  letterSpacing: 1.6),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Título ─────────────────────────────────────────────────────
  Widget _buildTitulo() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Acesso restrito',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('Informe seu usuário e senha para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.45))),
        ],
      );

  // ── Caixa de erro ───────────────────────────────────────────────
  Widget _buildErroBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_erro!,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.error,
                    height: 1.4)),
          ),
        ]),
      );

  // ── Campo Usuário ───────────────────────────────────────────────
  Widget _buildCampoUsuario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Usuário',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.45),
                letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _usuarioCtrl,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'seu.usuario',
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textTertiary, size: 19),
            // Mostra o domínio fake ao lado — só visual, não editável
            suffix: Text(
              _kDominio,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.primary.withOpacity(0.40),
                  fontWeight: FontWeight.w500),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Informe seu usuário';
            if (v.trim().contains(' ')) return 'Usuário não pode ter espaços';
            if (v.trim().contains('@')) return 'Digite só o usuário, sem @';
            return null;
          },
        ),
      ],
    );
  }

  // ── Campo Senha ─────────────────────────────────────────────────
  Widget _buildCampoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Senha',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.45),
                letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _senhaCtrl,
          obscureText: !_senhaVis,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _entrar(),
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textTertiary, size: 19),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _senhaVis = !_senhaVis),
              icon: Icon(
                _senhaVis
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textTertiary,
                size: 19,
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Informe sua senha';
            if (v.length < 6) return 'Senha mínima: 6 caracteres';
            return null;
          },
        ),
      ],
    );
  }

  // ── Botão entrar ────────────────────────────────────────────────
  Widget _buildBotaoEntrar() => SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _loading
                ? null
                : const LinearGradient(
                    colors: [AppColors.primaryDeep, Color(0xFF1A5CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _loading ? AppColors.surfaceMid : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: _loading
                ? null
                : [
                    BoxShadow(
                        color: AppColors.primaryDeep.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _entrar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize:
                  const Size(double.infinity, AppDimensions.buttonHeight),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            ),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.lock_open_rounded,
                    size: 18, color: Colors.white),
            label: Text(
              _loading ? 'Autenticando...' : 'Acessar painel',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ),
      );

  // ── Rodapé ──────────────────────────────────────────────────────
  Widget _buildRodape() => Column(
        children: [
          // Linha divisória
          Row(children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.07))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ACESSO MONITORADO',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.15),
                      letterSpacing: 2)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.07))),
          ]),
          const SizedBox(height: 12),
          // Aviso de acesso
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.info_outline_rounded,
                size: 12, color: Colors.white.withOpacity(0.18)),
            const SizedBox(width: 6),
            Text(
              'Acesso exclusivo para administradores autorizados',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.18)),
            ),
          ]),
        ],
      );
}

// ───────────────────────────────────────────────────────────────────
//  _GridPainter — grade de linhas sutis no fundo (aspecto de sistema)
// ───────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
