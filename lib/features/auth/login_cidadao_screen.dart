// ═══════════════════════════════════════════════════════════════════
//  login_cidadao_screen.dart  —  ConectaSaúdePI
//  (Login + Cadastro com Firebase Auth + Google Sign-In)
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

enum AuthMode { login, signup }

class LoginCidadaoScreen extends StatefulWidget {
  const LoginCidadaoScreen({super.key});
  @override
  State<LoginCidadaoScreen> createState() => _LoginCidadaoScreenState();
}

class _LoginCidadaoScreenState extends State<LoginCidadaoScreen>
    with SingleTickerProviderStateMixin {
  // Controladores
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _senhaVisivel = false;
  bool _loading = false;
  AuthMode _mode = AuthMode.login;

  // Stagger do formulário
  late final AnimationController _formCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 680), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  // ── Stagger helper ──────────────────────────────────────────────

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _formCtrl,
        curve: Interval(
          (i * 0.12).clamp(0.0, 0.5),
          ((i * 0.12) + 0.50).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );

  Animation<double> _slideY(int i) => Tween(begin: 16.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _formCtrl,
          curve: Interval(
            (i * 0.12).clamp(0.0, 0.5),
            ((i * 0.12) + 0.50).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  Widget _stagger(int i, Widget child) => AnimatedBuilder(
        animation: _formCtrl,
        builder: (_, __) => Opacity(
          opacity: _fade(i).value,
          child: Transform.translate(
            offset: Offset(0, _slideY(i).value),
            child: child,
          ),
        ),
      );

  // ── Ações Firebase ──────────────────────────────────────────────

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      // Usa a função personalizada para mensagens específicas
      _mostrarErro(_tratarErroAuth(e));
    } catch (e) {
      // Captura qualquer outro erro inesperado (ex.: problemas de rede fora do Firebase)
      _mostrarErro('Erro inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cadastrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      // Criar usuário no Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );

      // Salvar dados extras no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'nome': _nomeCtrl.text.trim(),
        'cpf': _cpfCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'uid': cred.user!.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Navegar para a home após cadastro
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_tratarErroAuth(e));
    } catch (e) {
      _mostrarErro('Erro inesperado: ${e.toString()}'); // ✅ seguro
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() => _loading = true);
    try {
      // Google Sign-In
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Usuário cancelou '
        return;
      }
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);

      // Verificar se o usuário já tem dados no Firestore; se não, criar registro
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCred.user!.uid)
          .get();
      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCred.user!.uid)
            .set({
          'nome': googleUser.displayName ?? '',
          'email': googleUser.email,
          'uid': userCred.user!.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_tratarErroAuth(e));
    } catch (e) {
      _mostrarErro('Erro ao entrar com Google: ${e.toString()}'); // ✅ seguro
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Utilitários ─────────────────────────────────────────────────

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _tratarErroAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      default:
        return e.message ?? 'Erro de autenticação.';
    }
  }

  // ── UI ───────────────────────────────────────────────────────────

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.signup : AuthMode.login;
      _formKey.currentState?.reset();
      // Limpa campos opcionais
      _nomeCtrl.clear();
      _cpfCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLogin = _mode == AuthMode.login;

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: Stack(children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppTopLine(),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 52),

                        // Logo
                        _buildLogoHeader(),
                        const SizedBox(height: 36),

                        // Título e subtítulo
                        _stagger(
                          0,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLogin
                                    ? 'Bem-vindo(a) de volta!'
                                    : 'Criar conta',
                                style: AppTextStyles.headlineLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLogin
                                    ? 'Faça login para continuar'
                                    : 'Preencha os dados para se cadastrar',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Campos dinâmicos ──────────────────

                        const SizedBox(height: 12),
                        // Nome (só no cadastro)
                        if (!isLogin)
                          _stagger(
                            1,
                            _buildField(
                              controller: _nomeCtrl,
                              hint: 'Nome completo',
                              icon: Icons.person_outline_rounded,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Informe seu nome';
                                return null;
                              },
                            ),
                          ),

                        const SizedBox(height: 12),
                        // CPF (só no cadastro)
                        if (!isLogin)
                          _stagger(
                            1,
                            _buildField(
                              controller: _cpfCtrl,
                              hint: 'CPF (apenas números)',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Informe seu CPF';
                                if (v.length != 11)
                                  return 'CPF deve ter 11 dígitos';
                                return null;
                              },
                            ),
                          ),

                        const SizedBox(height: 12),
                        // E-mail
                        _stagger(
                          isLogin ? 1 : 2,
                          _buildField(
                            controller: _emailCtrl,
                            hint: 'seu@email.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Informe seu e-mail';
                              if (!v.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Senha
                        _stagger(
                          isLogin ? 2 : 3,
                          _buildField(
                            controller: _senhaCtrl,
                            hint: isLogin ? 'Senha' : 'Crie uma senha',
                            icon: Icons.lock_outline_rounded,
                            obscure: !_senhaVisivel,
                            suffix: IconButton(
                              onPressed: () => setState(
                                  () => _senhaVisivel = !_senhaVisivel),
                              icon: Icon(
                                _senhaVisivel
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: AppDimensions.iconSizeMd,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Informe sua senha';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                        ),

                        // Link "Esqueceu senha?" só no login
                        if (isLogin)
                          _stagger(
                            2,
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: recuperação de senha
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 0),
                                ),
                                child: Text(
                                  'Esqueceu a senha?',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.blueLt,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Botão principal
                        _stagger(
                          isLogin ? 3 : 4,
                          _buildBotaoPrincipal(),
                        ),

                        const SizedBox(height: 20),

                        // Divisor
                        _stagger(
                          isLogin ? 3 : 4,
                          _buildDivisor(),
                        ),

                        const SizedBox(height: 20),

                        // Botão Google
                        _stagger(
                          isLogin ? 4 : 5,
                          _buildBotaoGoogle(),
                        ),

                        const SizedBox(height: 32),

                        // Alternância entre login e cadastro
                        _stagger(
                          isLogin ? 4 : 5,
                          Center(
                            child: GestureDetector(
                              onTap: _toggleMode,
                              child: Text(
                                isLogin
                                    ? 'Ainda não tem uma conta?  Criar conta'
                                    : 'Já tem uma conta?  Fazer login',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.blueLt,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
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

  // ── Widgets auxiliares ──────────────────────────────────────────

  Widget _buildLogoHeader() {
    return Hero(
      tag: 'brand-logo',
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2B6B), AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.40),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.greenLt.withOpacity(0.10),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _LogoImage(size: 56),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(children: [
                    const TextSpan(
                      text: 'Conecta',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: 'Saúde',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blueLt,
                        letterSpacing: -0.3,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: AppColors.blueLt.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: 'PI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenLt,
                        letterSpacing: -0.3,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: AppColors.greenLt.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 3),
                Text(
                  'SUA SAÚDE CONECTADA.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.28),
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon,
            color: AppColors.textTertiary, size: AppDimensions.iconSizeMd),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }

  Widget _buildBotaoPrincipal() {
    final bool isLogin = _mode == AuthMode.login;
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _loading
              ? null
              : const LinearGradient(
                  colors: [AppColors.blue, Color(0xFF1A5CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _loading ? AppColors.surfaceMid : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: _loading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : (isLogin ? _entrar : _cadastrar),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize:
                const Size(double.infinity, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  isLogin ? 'Entrar' : 'Cadastrar',
                  style: AppTextStyles.labelLarge,
                ),
        ),
      ),
    );
  }

  Widget _buildDivisor() {
    return Row(children: [
      const Expanded(child: Divider(color: AppColors.borderDim)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          'ou continue com',
          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ),
      const Expanded(child: Divider(color: AppColors.borderDim)),
    ]);
  }

  Widget _buildBotaoGoogle() {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: _loading ? null : _entrarComGoogle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderMid),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          backgroundColor: AppColors.surfaceDim,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              'Entrar com Google',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _LogoImage — carrega asset com fallback suave ────────────────

class _LogoImage extends StatelessWidget {
  final double size;
  const _LogoImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo-var01.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return Padding(padding: const EdgeInsets.all(8), child: child);
        }
        // Fallback suave: apenas um retângulo com a cor de fundo do ícone
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0D2B6B),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0D2B6B),
        ),
      ),
    );
  }
}
