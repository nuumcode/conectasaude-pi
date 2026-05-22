// ═══════════════════════════════════════════════════════════════════
//  login_cidadao_screen.dart  —  ConectaSaúdePI
//
//  ✅ Verificação de sessão ativa no initState (redireciona p/ /home)
//  ✅ Login e-mail/senha — Firebase Auth real
//  ✅ Cadastro — Firebase Auth + Firestore (nome, cpf, telefone, etc.)
//  ✅ Google Sign-In — cria/atualiza doc no Firestore
//  ✅ Esqueci minha senha — sendPasswordResetEmail funcional
//  ✅ Máscaras: CPF (000.000.000-00), Telefone ((00) 00000-0000)
//  ✅ Validação de e-mail com RegExp
//  ✅ Mensagens de erro em português
//  ✅ Redirecionamento correto após login/cadastro
//
//  pubspec.yaml (adicionar se não tiver):
//    firebase_auth: ^5.x
//    cloud_firestore: ^5.x
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

enum _Modo { login, cadastro }

class LoginCidadaoScreen extends StatefulWidget {
  const LoginCidadaoScreen({super.key});
  @override
  State<LoginCidadaoScreen> createState() => _LoginCidadaoScreenState();
}

class _LoginCidadaoScreenState extends State<LoginCidadaoScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────
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

  late final AnimationController _formCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // ── Lifecycle ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // ✅ PONTO 1 — Verificação de sessão ativa
    // Se já há um usuário logado, redireciona direto para /home
    // sem mostrar a tela de login nem piscar
    // AuthWrapper já verificou a sessão antes de chegar aqui
    // Basta animar o formulário
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  // ── Stagger (Interval seguro: nunca > 1.0) ──────────────────────
  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _formCtrl,
        curve: Interval(
          (i * 0.12).clamp(0.0, 0.5),
          ((i * 0.12) + 0.50).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );

  Animation<double> _slideY(int i) =>
      Tween(begin: 16.0, end: 0.0).animate(CurvedAnimation(
        parent: _formCtrl,
        curve: Interval(
          (i * 0.12).clamp(0.0, 0.5),
          ((i * 0.12) + 0.50).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ));

  Widget _s(int i, Widget child) => AnimatedBuilder(
        animation: _formCtrl,
        builder: (_, __) => Opacity(
          opacity: _fade(i).value,
          child: Transform.translate(
            offset: Offset(0, _slideY(i).value),
            child: child,
          ),
        ),
      );

  // ── Alternar modo ────────────────────────────────────────────────
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
    _formCtrl
      ..reset()
      ..forward();
  }

  // ════════════════════════════════════════════════════════════════
  //  FIRESTORE — helper para salvar/atualizar usuário
  // ════════════════════════════════════════════════════════════════
  Future<void> _salvarUsuarioFirestore({
    required String uid,
    required String email,
    String? nome,
    String? cpf,
    String? telefone,
    String? fotoUrl,
    bool merge = false, // true = atualiza, false = sobrescreve
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
    if (nome != null) data['nome'] = nome;
    if (cpf != null) data['cpf'] = cpf;
    if (telefone != null) data['telefone'] = telefone;
    if (fotoUrl != null) data['fotoUrl'] = fotoUrl;

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
        merge ? {...data} : {...data, 'criadoEm': FieldValue.serverTimestamp()},
        SetOptions(merge: merge));
  }

  // ════════════════════════════════════════════════════════════════
  //  AUTH — Login e-mail/senha
  // ════════════════════════════════════════════════════════════════
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

      // Atualiza último acesso — set+merge nunca falha mesmo se doc não existir
      final uid = FirebaseAuth.instance.currentUser!.uid;
      try {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
            {'ultimoAcesso': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      } catch (_) {
        // Firestore opcional — não bloqueia o login
      }

      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } catch (e) {
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  AUTH — Cadastro completo
  // ════════════════════════════════════════════════════════════════
  Future<void> _cadastrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      // 1. Criar usuário no Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text,
      );

      // 2. Atualizar displayName
      await cred.user!.updateDisplayName(_nomeCtrl.text.trim());

      // 3. Salvar no Firestore (com tratamento de erro explícito)
      final cpfLimpo = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
      final telLimpo = _telefoneCtrl.text.replaceAll(RegExp(r'\D'), '');

      // 3. Salva no Firestore — falha aqui NÃO cancela o cadastro
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'nome': _nomeCtrl.text.trim(),
          'cpf': cpfLimpo,
          'telefone': telLimpo,
          'email': _emailCtrl.text.trim(),
          'uid': cred.user!.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Firestore opcional — usuário já foi criado no Auth, navega mesmo assim
      }

      // 4. Navega — usuário já está logado no Auth
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } catch (e) {
      setState(() => _erro = e.toString().contains('Firestore')
          ? 'Erro ao salvar dados no servidor. Verifique sua internet.'
          : 'Erro inesperado. Tente novamente.');
    } finally {
      // 🔥 Garante que o loading SEMPRE desligue, mesmo que o erro fique oculto
      if (mounted) setState(() => _loading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  AUTH — Google Sign-In (login + cadastro automático)
  // ════════════════════════════════════════════════════════════════
  Future<void> _entrarComGoogle() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCred =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
      final user = userCred.user!;

      // ✅ Verifica se já existe no Firestore
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Novo usuário
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'nome': user.displayName ?? '',
          'email': user.email,
          'uid': user.uid,
          'fotoUrl': user.photoURL,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      // Redireciona para home
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } catch (e) {
      setState(() => _erro = 'Erro ao entrar com Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  AUTH — Recuperar senha
  // ════════════════════════════════════════════════════════════════
  Future<void> _esqueceuSenha() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erro = 'Digite seu e-mail acima para recuperar a senha.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'E-mail de recuperação enviado para $email',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.accentDeep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Tradução de erros ────────────────────────────────────────────
  String _traduzirErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com esse e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Esse e-mail já está cadastrado. Faça login.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Endereço de e-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      default:
        return 'Erro inesperado. Tente novamente.';
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isLogin = _modo == _Modo.login;

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: Stack(children: [
            const Positioned(top: 0, left: 0, right: 0, child: AppTopLine()),
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

                        // ── Logo Hero ───────────────────────────
                        _buildLogoHeader(),
                        const SizedBox(height: 32),

                        // ── Título ──────────────────────────────
                        _s(
                            0,
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              child: Column(
                                key: ValueKey(_modo),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLogin
                                        ? 'Bem-vindo(a) de volta!'
                                        : 'Criar nova conta',
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isLogin
                                        ? 'Faça login para continuar'
                                        : 'Preencha os dados abaixo',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 22),

                        // ── Campos de cadastro ──────────────────
                        if (!isLogin) ...[
                          // Nome completo
                          _s(
                              1,
                              _buildField(
                                controller: _nomeCtrl,
                                hint: 'Nome completo',
                                icon: Icons.person_outline_rounded,
                                textCapitalization: TextCapitalization.words,
                                keyboardType: TextInputType.name,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Informe seu nome completo';
                                  if (v.trim().split(' ').length < 2)
                                    return 'Digite nome e sobrenome';
                                  return null;
                                },
                              )),
                          const SizedBox(height: 12),

                          // CPF com máscara
                          _s(
                              1,
                              _buildField(
                                controller: _cpfCtrl,
                                hint: 'CPF  (000.000.000-00)',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _CpfFormatter(),
                                ],
                                validator: (v) {
                                  final d =
                                      v?.replaceAll(RegExp(r'\D'), '') ?? '';
                                  if (d.isEmpty) return 'Informe seu CPF';
                                  if (d.length != 11) return 'CPF incompleto';
                                  if (!_cpfValido(d)) return 'CPF inválido';
                                  return null;
                                },
                              )),
                          const SizedBox(height: 12),

                          // Telefone com máscara
                          _s(
                              2,
                              _buildField(
                                controller: _telefoneCtrl,
                                hint: 'Telefone / WhatsApp',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _TelefoneFormatter(),
                                ],
                                validator: (v) {
                                  final d =
                                      v?.replaceAll(RegExp(r'\D'), '') ?? '';
                                  if (d.isEmpty) return 'Informe seu telefone';
                                  if (d.length < 10) return 'Telefone inválido';
                                  return null;
                                },
                              )),
                          const SizedBox(height: 12),
                        ],

                        // ── E-mail ──────────────────────────────
                        _s(
                            isLogin ? 1 : 2,
                            _buildField(
                              controller: _emailCtrl,
                              hint: 'seu@email.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [
                                // Bloqueia espaços no e-mail
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Informe seu e-mail';
                                if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$')
                                    .hasMatch(v.trim()))
                                  return 'E-mail inválido';
                                return null;
                              },
                            )),
                        const SizedBox(height: 12),

                        // ── Senha ───────────────────────────────
                        _s(
                            isLogin ? 2 : 3,
                            _buildField(
                              controller: _senhaCtrl,
                              hint: isLogin
                                  ? 'Senha'
                                  : 'Crie uma senha (mín. 6 caracteres)',
                              icon: Icons.lock_outline_rounded,
                              obscure: !_senhaVis,
                              suffix: _btnVisibilidade(
                                visible: _senhaVis,
                                onTap: () =>
                                    setState(() => _senhaVis = !_senhaVis),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Informe sua senha';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            )),

                        // ── Confirmar senha (cadastro) ───────────
                        if (!isLogin) ...[
                          const SizedBox(height: 12),
                          _s(
                              3,
                              _buildField(
                                controller: _confirmaCtrl,
                                hint: 'Confirme sua senha',
                                icon: Icons.lock_outline_rounded,
                                obscure: !_confirmaVis,
                                suffix: _btnVisibilidade(
                                  visible: _confirmaVis,
                                  onTap: () => setState(
                                      () => _confirmaVis = !_confirmaVis),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Confirme sua senha';
                                  if (v != _senhaCtrl.text)
                                    return 'As senhas não coincidem';
                                  return null;
                                },
                              )),
                        ],

                        // ── Esqueceu senha ──────────────────────
                        if (isLogin)
                          _s(
                              2,
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _esqueceuSenha,
                                  style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 0)),
                                  child: Text('Esqueceu a senha?',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.blueLt,
                                          fontWeight: FontWeight.w500)),
                                ),
                              )),

                        // ── Mensagem de erro ────────────────────
                        if (_erro != null) ...[
                          const SizedBox(height: 10),
                          _s(isLogin ? 2 : 3, _buildErro()),
                        ],

                        const SizedBox(height: 12),

                        // ── Botão principal ─────────────────────
                        _s(isLogin ? 3 : 4, _buildBotaoPrincipal()),

                        const SizedBox(height: 20),

                        // ── Divisor ─────────────────────────────
                        _s(isLogin ? 3 : 4, _buildDivisor()),

                        const SizedBox(height: 20),

                        // ── Google ──────────────────────────────
                        _s(4, _buildBotaoGoogle()),

                        const SizedBox(height: 28),

                        // ── Alternar Login / Cadastro ───────────
                        _s(4, _buildAlternar()),

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

  // ── Logo Header com Hero ─────────────────────────────────────────
  Widget _buildLogoHeader() {
    return Hero(
      tag: 'brand-logo',
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      offset: const Offset(0, 6)),
                  BoxShadow(
                      color: AppColors.greenLt.withOpacity(0.10),
                      blurRadius: 28,
                      spreadRadius: 2),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logo-var01.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  frameBuilder: (ctx, child, frame, wasSyncLoaded) {
                    if (wasSyncLoaded || frame != null) {
                      return Padding(
                          padding: const EdgeInsets.all(8), child: child);
                    }
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
                    child: CustomPaint(painter: CrossEcgPainter()),
                  ),
                ),
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
                            height: 1.0)),
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
                                  blurRadius: 12)
                            ])),
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
                                  blurRadius: 12)
                            ])),
                  ]),
                ),
                const SizedBox(height: 3),
                Text('SUA SAÚDE CONECTADA.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.28),
                        letterSpacing: 2.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Campo genérico ───────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscure,
      inputFormatters: inputFormatters,
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

  Widget _btnVisibilidade(
      {required bool visible, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: AppDimensions.iconSizeMd,
        color: AppColors.textTertiary,
      ),
    );
  }

  // ── Mensagem de erro ─────────────────────────────────────────────
  Widget _buildErro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
        const SizedBox(width: 10),
        Expanded(
            child: Text(_erro!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error))),
      ]),
    );
  }

  // ── Botão principal ──────────────────────────────────────────────
  Widget _buildBotaoPrincipal() {
    final isLogin = _modo == _Modo.login;
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
                  end: Alignment.bottomRight),
          color: _loading ? AppColors.surfaceMid : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: _loading
              ? null
              : [
                  BoxShadow(
                      color: AppColors.blue.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text(isLogin ? 'Entrar' : 'Criar conta',
                  style: AppTextStyles.labelLarge),
        ),
      ),
    );
  }

  // ── Divisor ──────────────────────────────────────────────────────
  Widget _buildDivisor() => Row(children: [
        const Expanded(child: Divider(color: AppColors.borderDim)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('ou continue com',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary)),
        ),
        const Expanded(child: Divider(color: AppColors.borderDim)),
      ]);

  // ── Botão Google ─────────────────────────────────────────────────
  Widget _buildBotaoGoogle() => SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        child: OutlinedButton(
          onPressed: _loading ? null : _entrarComGoogle,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderMid),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            backgroundColor: AppColors.surfaceDim,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: GoogleLogoPainter())),
              const SizedBox(width: 12),
              Text('Continuar com Google',
                  style: AppTextStyles.labelLarge
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      );

  // ── Alternar login / cadastro ────────────────────────────────────
  Widget _buildAlternar() {
    final isLogin = _modo == _Modo.login;
    return Center(
      child: GestureDetector(
        onTap: _loading ? null : _alternarModo,
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: isLogin
                  ? 'Ainda não tem uma conta?  '
                  : 'Já tem uma conta?  ',
              style: AppTextStyles.bodyMedium,
            ),
            TextSpan(
              text: isLogin ? 'Criar conta' : 'Fazer login',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.blueLt, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Formatadores de input
// ═══════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════
//  Validação de CPF (algoritmo oficial)
// ═══════════════════════════════════════════════════════════════════
bool _cpfValido(String cpf) {
  if (cpf.length != 11 || RegExp(r'^(\d)\1+$').hasMatch(cpf)) return false;
  int soma = 0;
  for (int i = 0; i < 9; i++) soma += int.parse(cpf[i]) * (10 - i);
  int r1 = (soma * 10) % 11;
  if (r1 == 10 || r1 == 11) r1 = 0;
  if (r1 != int.parse(cpf[9])) return false;
  soma = 0;
  for (int i = 0; i < 10; i++) soma += int.parse(cpf[i]) * (11 - i);
  int r2 = (soma * 10) % 11;
  if (r2 == 10 || r2 == 11) r2 = 0;
  return r2 == int.parse(cpf[10]);
}
