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
import '../../core/widgets/app_brand_logo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';

// Domínio interno — invisível ao usuário por padrão
const _kDominio = '@conectasaude.com';

// ───────────────────────────────────────────────────────────────────
class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});
  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController(); // Usuário ou e-mail completo
  final _senhaCtrl = TextEditingController();

  bool _senhaVis = false;
  bool _loading = false;
  String? _erro;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  Future<void> _checkAlreadyLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final perfil = await _obterPerfil(user.uid);
      if (mounted && perfil != null) {
        if (perfil == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin/home');
        } else if (perfil == 'posto') {
          Navigator.of(context).pushReplacementNamed('/posto/home');
        }
      }
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // ── Verificação de perfil admin/posto no Firestore ────────────────
  Future<String?> _obterPerfil(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      final perfil = doc.data()?['perfil'] as String?;
      if (perfil == 'admin' || perfil == 'posto') return perfil;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Lógica de Transformação de Usuário ──────────────────────────
  /// Converte o username digitado para o e-mail completo do Firebase.
  /// Se já contiver '@', usa o valor direto (backward compatibility).
  String _processarIdentidade(String input) {
    final raw = input.trim().toLowerCase().replaceAll(' ', '');

    // Se contém @, assume que é um e-mail completo e não transforma
    if (raw.contains('@')) return raw;

    // Caso contrário, aplica a regra de negócio: username + @conectasaude.com
    return '$raw$_kDominio';
  }

  // ── Login ──────────────────────────────────────────────────────
  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _erro = null;
    });

    // 1. Processa a identidade (Username -> Email)
    final emailAuth = _processarIdentidade(_usuarioCtrl.text);

    try {
      // 2. Autentica no Firebase
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailAuth,
        password: _senhaCtrl.text,
      );

      // 3. Verifica perfil no Firestore
      final perfil = await _obterPerfil(cred.user!.uid);

      if (perfil == null) {
        // Loga mas não tem perfil autorizado — desloga e nega acesso
        await FirebaseAuth.instance.signOut();
        setState(() {
          _erro =
              'Acesso negado. Este usuário não tem permissão administrativa.';
          _loading = false;
        });
        return;
      }

      // 4. Registra último acesso
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'ultimoAcesso': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Não bloqueia o acesso por erro no registro de log
      }

      // 5. Redireciona para o painel correspondente
      if (mounted) {
        if (perfil == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin/home');
        } else if (perfil == 'posto') {
          Navigator.of(context).pushReplacementNamed('/posto/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _traduzirErro(e.code));
    } catch (_) {
      setState(() => _erro = 'Erro ao conectar. Verifique sua rede.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Tradução de erros (User-Friendly) ──────────────────────────
  String _traduzirErro(String code) => switch (code) {
        'user-not-found' => 'Usuário não encontrado.',
        'wrong-password' => 'Senha incorreta.',
        'invalid-credential' => 'Usuário ou senha inválidos.',
        'invalid-email' => 'Formato de usuário inválido.',
        'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
        'network-request-failed' => 'Sem conexão. Verifique sua rede.',
        'user-disabled' => 'Este acesso foi desativado.',
        _ => 'Falha na autenticação. Tente novamente.',
      };

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      backgroundColor: AppColors.bgBase,
      body: AppBackground(
        child: SafeArea(
          child: Stack(children: [
            // Linha topo
            const Positioned(top: 0, left: 0, right: 0, child: AppTopLine()),

            // Conteúdo centralizado
            Center(
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
                        AppEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: _buildIdentidade()),
                        const SizedBox(height: 36),

                        // ── Título ──────────────────────────────────
                        AppEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: _buildTitulo()),
                        const SizedBox(height: 28),

                        // ── Erro ────────────────────────────────────
                        if (_erro != null) ...[
                          AppEntrance(child: _buildErroBox()),
                          const SizedBox(height: 12),
                        ],

                        // ── Campo: usuário (Username) ───────────────
                        AppEntrance(
                            delay: const Duration(milliseconds: 300),
                            child: _buildCampoUsuario()),
                        const SizedBox(height: 14),

                        // ── Campo: senha ────────────────────────────
                        AppEntrance(
                            delay: const Duration(milliseconds: 400),
                            child: _buildCampoSenha()),
                        const SizedBox(height: 28),

                        // ── Botão entrar ────────────────────────────
                        AppEntrance(
                            delay: const Duration(milliseconds: 500),
                            child: _buildBotaoEntrar()),
                        const SizedBox(height: 32),

                        // ── Rodapé ──────────────────────────────────
                        AppEntrance(
                            delay: const Duration(milliseconds: 600),
                            child: _buildRodape()),
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

  // ── Identidade visual (UNIFICADA COM HERO) ─────────────────────
  Widget _buildIdentidade() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Centralizada com Hero
        const AppBrandLogo(size: 72, showText: true, isLight: true),

        const SizedBox(height: 16),

        // Badge "Painel Administrativo"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            color: Colors.white.withOpacity(0.08),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_outlined,
                size: 11, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 5),
            Text(
              'PAINEL ADMINISTRATIVO',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.6),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Título ─────────────────────────────────────────────────────
  Widget _buildTitulo() => const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Acesso restrito',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          SizedBox(height: 4),
          Text('Informe seu usuário e senha para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: Colors.white70)),
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

  // ── Campo Usuário (Username) ────────────────────────────────────
  Widget _buildCampoUsuario() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextFormField(
        controller: _usuarioCtrl,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Usuário ou e-mail',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          fillColor: Colors.transparent,
          filled: true,
          prefixIcon: const Icon(Icons.person_outline_rounded,
              color: Colors.white70, size: 19),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Informe seu usuário';

          final raw = v.trim();
          if (raw.contains(' ')) return 'O usuário não pode conter espaços';

          // Se for e-mail completo (contém @), valida formato básico
          if (raw.contains('@')) {
            if (!raw.contains('.') || raw.length < 5) {
              return 'E-mail inválido';
            }
          } else {
            // Se for só username, valida caracteres permitidos (letras, números, _)
            final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
            if (!usernameRegex.hasMatch(raw)) {
              return 'Use apenas letras, números ou underscore (_)';
            }
          }
          return null;
        },
      ),
    );
  }

  // ── Campo Senha ─────────────────────────────────────────────────
  Widget _buildCampoSenha() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextFormField(
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
          hintText: 'Sua senha de acesso',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          fillColor: Colors.transparent,
          filled: true,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: Colors.white70, size: 19),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _senhaVis = !_senhaVis),
            icon: Icon(
              _senhaVis
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white70,
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
                    colors: [Color(0xFF1A72FF), Color(0xFF1AFFA4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _loading ? Colors.white.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: _loading
                ? null
                : [
                    BoxShadow(
                        color: const Color(0xFF1A72FF).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _entrar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
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
              style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
      );

  // ── Rodapé ──────────────────────────────────────────────────────
  Widget _buildRodape() => Column(
        children: [
          // Linha divisória
          Row(children: [
            const Expanded(child: Divider(color: Colors.white10)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ACESSO MONITORADO',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2)),
            ),
            const Expanded(child: Divider(color: Colors.white10)),
          ]),
          const SizedBox(height: 12),
          // Aviso de acesso
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.info_outline_rounded,
                size: 12, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 6),
            Text(
              'Acesso exclusivo para administradores autorizados',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.4)),
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
      ..color = AppColors.borderDim.withOpacity(0.5)
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
