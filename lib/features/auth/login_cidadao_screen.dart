// ═══════════════════════════════════════════════════════════════════
//  login_cidadao_screen.dart  —  ConectaSaúdePI
//
//  ✅ Login e-mail/senha — Firebase Auth real
//  ✅ Cadastro — Firebase Auth + Firestore
//  ✅ Google Sign-In — funcional
//  ✅ Animações padronizadas com AppEntrance e AppFadeSwitcher
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/app_brand_logo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

enum _Modo { login, cadastro }

class LoginCidadaoScreen extends StatefulWidget {
  const LoginCidadaoScreen({super.key});
  @override
  State<LoginCidadaoScreen> createState() => _LoginCidadaoScreenState();
}

class _LoginCidadaoScreenState extends State<LoginCidadaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _senhaVis = false;
  bool _confirmaVis = false;
  bool _loading = false;
  String? _erro;
  _Modo _modo = _Modo.login;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  void _alternarModo() {
    setState(() {
      _modo = _modo == _Modo.login ? _Modo.cadastro : _Modo.login;
      _erro = null;
      _formKey.currentState?.reset();
      _nomeCtrl.clear();
      _cpfCtrl.clear();
      _telefoneCtrl.clear();
      _senhaCtrl.clear();
      _confirmaCtrl.clear();
    });
  }

  // ── AUTH ──────────────────────────────────────────────────────────
  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text,
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cadastrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text,
      );
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'nome': _nomeCtrl.text.trim(),
        'cpf': _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
        'telefone': _telefoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
        'email': _emailCtrl.text.trim(),
        'uid': cred.user!.uid,
        'perfil': 'cidadao',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final googleProvider = GoogleAuthProvider();
      final userCred =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
      final user = userCred.user!;
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'nome': user.displayName ?? '',
          'email': user.email,
          'uid': user.uid,
          'perfil': 'cidadao',
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => _erro = 'Erro ao entrar com Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'E-mail não cadastrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'E-mail já em uso.';
      default:
        return 'Erro ao processar. Tente novamente.';
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLogin = _modo == _Modo.login;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: AppBackground(
        child: SafeArea(
          child: Stack(children: [
            const Positioned(top: 0, left: 0, right: 0, child: AppTopLine()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 52),
                        const AppEntrance(
                          child: AppBrandLogo(
                              size: 56,
                              showText: true,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              isLight: true),
                        ),
                        const SizedBox(height: 32),
                        AppFadeSwitcher(
                          child: Column(
                            key: ValueKey(_modo),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  isLogin
                                      ? 'Bem-vindo(a) de volta!'
                                      : 'Criar nova conta',
                                  style: AppTextStyles.headlineLarge
                                      .copyWith(color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                  isLogin
                                      ? 'Faça login para continuar'
                                      : 'Preencha os dados abaixo',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (!isLogin) ...[
                          _fieldEntrance(
                              0,
                              _buildField(
                                  controller: _nomeCtrl,
                                  hint: 'Nome completo',
                                  icon: Icons.person_outline_rounded,
                                  textCapitalization:
                                      TextCapitalization.words)),
                          const SizedBox(height: 12),
                          _fieldEntrance(
                              1,
                              _buildField(
                                  controller: _cpfCtrl,
                                  hint: 'CPF',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _CpfFormatter()
                                  ])),
                          const SizedBox(height: 12),
                          _fieldEntrance(
                              2,
                              _buildField(
                                  controller: _telefoneCtrl,
                                  hint: 'Telefone',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _TelefoneFormatter()
                                  ])),
                          const SizedBox(height: 12),
                        ],
                        _fieldEntrance(
                            isLogin ? 0 : 3,
                            _buildField(
                                controller: _emailCtrl,
                                hint: 'E-mail',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress)),
                        const SizedBox(height: 12),
                        _fieldEntrance(
                            isLogin ? 1 : 4,
                            _buildField(
                              controller: _senhaCtrl,
                              hint: 'Senha',
                              icon: Icons.lock_outline_rounded,
                              obscure: !_senhaVis,
                              suffix: IconButton(
                                icon: Icon(
                                    _senhaVis
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppColors.textTertiary),
                                onPressed: () =>
                                    setState(() => _senhaVis = !_senhaVis),
                              ),
                            )),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          AppEntrance(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.2)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_erro!,
                                        style: AppTextStyles.caption
                                            .copyWith(color: AppColors.error))),
                              ]),
                            ),
                          ),
                        ],
                        if (!isLogin) ...[
                          const SizedBox(height: 12),
                          _fieldEntrance(
                              5,
                              _buildField(
                                controller: _confirmaCtrl,
                                hint: 'Confirmar Senha',
                                icon: Icons.lock_outline_rounded,
                                obscure: !_confirmaVis,
                                suffix: IconButton(
                                  icon: Icon(
                                      _confirmaVis
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppColors.textTertiary),
                                  onPressed: () => setState(
                                      () => _confirmaVis = !_confirmaVis),
                                ),
                              )),
                        ],
                        const SizedBox(height: 24),
                        AppEntrance(
                          delay: const Duration(milliseconds: 400),
                          child: _buildBotaoPrincipal(),
                        ),
                        const SizedBox(height: 20),
                        AppEntrance(
                          delay: const Duration(milliseconds: 500),
                          child: _buildBotaoGoogle(),
                        ),
                        const SizedBox(height: 28),
                        AppEntrance(
                          delay: const Duration(milliseconds: 600),
                          child: _buildAlternar(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _fieldEntrance(int index, Widget child) {
    return AppEntrance(
      delay: Duration(milliseconds: 100 + (index * 50)),
      child: child,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          fillColor: Colors.transparent,
          filled: true,
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          suffixIcon: suffix,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBotaoPrincipal() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A72FF), Color(0xFF41F1F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1A72FF).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: ElevatedButton(
          onPressed:
              _loading ? null : (_modo == _Modo.login ? _entrar : _cadastrar),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_modo == _Modo.login ? 'Entrar' : 'Criar Conta',
                  style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildBotaoGoogle() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _loading ? null : _entrarComGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: const BorderSide(color: Colors.white24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: GoogleLogoPainter())),
            const SizedBox(width: 12),
            Text('Entrar com Google',
                style: AppTextStyles.labelLarge
                    .copyWith(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternar() {
    return Center(
      child: TextButton(
        onPressed: _alternarModo,
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            children: [
              TextSpan(
                  text: _modo == _Modo.login
                      ? 'Não tem uma conta? '
                      : 'Já tem uma conta? '),
              TextSpan(
                  text: _modo == _Modo.login ? 'Criar agora' : 'Entrar',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue neo) {
    var t = neo.text.replaceAll(RegExp(r'\D'), '');
    if (t.length > 11) t = t.substring(0, 11);
    final b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      if (i == 3 || i == 6) b.write('.');
      if (i == 9) b.write('-');
      b.write(t[i]);
    }
    final s = b.toString();
    return TextEditingValue(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue neo) {
    var t = neo.text.replaceAll(RegExp(r'\D'), '');
    if (t.length > 11) t = t.substring(0, 11);
    final b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      if (i == (t.length == 11 ? 7 : 6)) b.write('-');
      b.write(t[i]);
    }
    final s = b.toString();
    return TextEditingValue(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
