import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '/core/animations/app_animations.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_escala_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_fila_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/cidadao_emergencia_screen.dart';
import 'package:conecta_saude_pi/features/cidadao/dashboard_cidadao.dart';
import 'package:conecta_saude_pi/features/widgets/app_drawer.dart';
import 'package:conecta_saude_pi/features/widgets/app_header.dart';
import 'package:conecta_saude_pi/features/auth/login_cidadao_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;

  String _cpf = '—';
  String _telefone = '—';
  String _dataNascimento = '—';
  String _tipoSanguineo = '—';
  String _alergias = 'Nenhuma registrada';
  String _convenio = 'SUS';
  String _contatoEmergNome = '—';
  String _contatoEmergParentesco = '';
  String _contatoEmergFone = '';

  bool _prefNotificacoes = true;
  bool _prefPrivacidade = false;

  User? get _user => FirebaseAuth.instance.currentUser;
  String get _userName => _user?.displayName ?? 'Cidadão';
  String get _userEmail => _user?.email ?? '—';
  String? get _userPhoto => _user?.photoURL;
  String get _firstName => _userName.split(' ').first;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = _user;
    if (u == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final snap = await _firestore.collection('usuarios').doc(u.uid).get();
      if (snap.exists) {
        final d = snap.data()!;
        _cpf = (d['cpf'] ?? '—') as String;
        _telefone = (d['telefone'] ?? '—') as String;
        _dataNascimento = (d['dataNascimento'] ?? '—') as String;
        _tipoSanguineo = (d['tipoSanguineo'] ?? '—') as String;
        _alergias = (d['alergias'] ?? 'Nenhuma registrada') as String;
        _convenio = (d['convenio'] ?? 'SUS') as String;
        _contatoEmergNome = (d['contatoEmergNome'] ?? '—') as String;
        _contatoEmergParentesco =
            (d['contatoEmergParentesco'] ?? '') as String;
        _contatoEmergFone = (d['contatoEmergFone'] ?? '') as String;
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginCidadaoScreen()),
    );
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.perfil) return;
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

  // ── Editar perfil (modal) ────────────────────────────────────────
  Future<void> _abrirEdicaoPerfil() async {
    final result = await showModalBottomSheet<_PerfilFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PerfilEditSheet(),
    );
    if (result == null) return;
    await _salvarPerfil(result);
  }

  Future<void> _abrirEdicaoEmergencia() async {
    final result = await showModalBottomSheet<_EmergenciaFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmergenciaEditSheet(
        nome: _contatoEmergNome,
        parentesco: _contatoEmergParentesco,
        fone: _contatoEmergFone,
      ),
    );
    if (result == null) return;
    await _salvarEmergencia(result);
  }

  Future<void> _salvarPerfil(_PerfilFormResult r) async {
    final u = _user;
    if (u == null) return;
    setState(() => _loading = true);
    try {
      if (r.nome.isNotEmpty && r.nome != _userName) {
        await u.updateDisplayName(r.nome);
      }
      await _firestore.collection('usuarios').doc(u.uid).set({
        'cpf': r.cpf,
        'telefone': r.telefone,
        'dataNascimento': r.dataNascimento,
        'tipoSanguineo': r.tipoSanguineo,
        'alergias': r.alergias,
        'convenio': r.convenio,
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await u.reload();

      if (!mounted) return;
      setState(() {
        _cpf = r.cpf.isEmpty ? '—' : r.cpf;
        _telefone = r.telefone.isEmpty ? '—' : r.telefone;
        _dataNascimento =
            r.dataNascimento.isEmpty ? '—' : r.dataNascimento;
        _tipoSanguineo = r.tipoSanguineo.isEmpty ? '—' : r.tipoSanguineo;
        _alergias =
            r.alergias.isEmpty ? 'Nenhuma registrada' : r.alergias;
        _convenio = r.convenio.isEmpty ? 'SUS' : r.convenio;
      });
      _toast('Perfil atualizado com sucesso!', sucesso: true);
    } catch (e) {
      _toast('Erro ao salvar: $e', sucesso: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvarEmergencia(_EmergenciaFormResult r) async {
    final u = _user;
    if (u == null) return;
    setState(() => _loading = true);
    try {
      await _firestore.collection('usuarios').doc(u.uid).set({
        'contatoEmergNome': r.nome,
        'contatoEmergParentesco': r.parentesco,
        'contatoEmergFone': r.fone,
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _contatoEmergNome = r.nome.isEmpty ? '—' : r.nome;
        _contatoEmergParentesco = r.parentesco;
        _contatoEmergFone = r.fone;
      });
      _toast('Contato de emergência atualizado!', sucesso: true);
    } catch (e) {
      _toast('Erro ao salvar: $e', sucesso: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {required bool sucesso}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            sucesso ? AppColors.success : AppColors.error,
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
      drawer: isDesktop ? null : _drawer(),
      body: isDesktop ? _desktop() : _mobile(),
    );
  }

  AppDrawer _drawer({bool fixed = false}) => AppDrawer(
        userName: _userName,
        userEmail: _userEmail,
        userPhoto: _userPhoto,
        abaAtual: DrawerAba.perfil,
        onAbaChanged: _onAbaChanged,
        onLogout: _logout,
        isFixed: fixed,
      );

  Widget _desktop() {
    return Row(children: [
      SizedBox(width: 260, child: _drawer(fixed: true)),
      Container(width: 1, color: AppColors.borderDim),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _firstName,
            userPhoto: _userPhoto,
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
          ),
          Expanded(child: _conteudo(true)),
        ]),
      ),
    ]);
  }

  Widget _mobile() {
    return Column(children: [
      AppHeader(
        userName: _firstName,
        userPhoto: _userPhoto,
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
      ),
      Expanded(child: _conteudo(false)),
    ]);
  }

  // ════════════════════════════════════════════════════════════════
  Widget _conteudo(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 16,
        20,
        isDesktop ? 24 : 16,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(Icons.person_outline_rounded, 'Meu Perfil'),
              const SizedBox(height: 12),
              _heroCard(isDesktop),
              const SizedBox(height: 16),
              _twoCols(
                isDesktop,
                _cardPessoais(),
                _cardSaude(),
              ),
              const SizedBox(height: 16),
              _twoCols(
                isDesktop,
                _cardEmergencia(),
                _cardPreferencias(),
              ),
              const SizedBox(height: 20),
              _ctaSeguranca(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _twoCols(bool isDesktop, Widget a, Widget b) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [a, const SizedBox(height: 16), b],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 16),
          Expanded(child: b),
        ],
      ),
    );
  }

  Widget _label(IconData icon, String label) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]);

  // ── Hero ─────────────────────────────────────────────────────────
  Widget _heroCard(bool isDesktop) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatar(),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Paciente',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gerencie suas informações pessoais e de saúde no SUS.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _abrirEdicaoPerfil,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Editar perfil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final hasPhoto = _userPhoto != null && _userPhoto!.trim().isNotEmpty;
    return Stack(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDim, width: 2),
          ),
          child: ClipOval(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.surfaceDim,
              backgroundImage: hasPhoto ? NetworkImage(_userPhoto!) : null,
              onBackgroundImageError: hasPhoto
                  ? (e, s) => debugPrint('Falha foto perfil: $e')
                  : null,
              child: !hasPhoto
                  ? Text(
                      _userName.isNotEmpty
                          ? _userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bgBase, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardPessoais() => _Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardTitle(Icons.badge_outlined, 'Informações pessoais'),
              const SizedBox(height: 12),
              _infoRow(Icons.fingerprint_rounded, 'CPF', _cpf),
              _infoRow(Icons.email_outlined, 'E-mail', _userEmail),
              _infoRow(Icons.phone_outlined, 'Telefone', _telefone),
              _infoRow(Icons.cake_outlined, 'Data de nascimento',
                  _dataNascimento),
            ],
          ),
        ),
      );

  Widget _cardSaude() => _Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardTitle(
                  Icons.favorite_border_rounded, 'Informações de saúde'),
              const SizedBox(height: 12),
              _infoRow(Icons.bloodtype_outlined, 'Tipo sanguíneo',
                  _tipoSanguineo,
                  accent: AppColors.error),
              _infoRow(Icons.warning_amber_rounded, 'Alergias', _alergias,
                  accent: AppColors.warning),
              _infoRow(Icons.medical_information_outlined, 'Convênio',
                  _convenio,
                  accent: AppColors.primary),
            ],
          ),
        ),
      );

  Widget _cardEmergencia() => _Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardTitle(
                  Icons.emergency_share_outlined, 'Contato de emergência'),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _contatoEmergNome.isEmpty ? '—' : _contatoEmergNome,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_contatoEmergParentesco.isNotEmpty)
                        Text(
                          _contatoEmergParentesco,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (_contatoEmergFone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _contatoEmergFone,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _abrirEdicaoEmergencia,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Atualizar contato',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.borderDim),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _cardPreferencias() => _Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardTitle(Icons.tune_rounded, 'Preferências'),
              const SizedBox(height: 8),
              _switchRow(
                Icons.notifications_active_outlined,
                'Notificações',
                'Lembretes de consultas e mensagens',
                _prefNotificacoes,
                (v) => setState(() => _prefNotificacoes = v),
              ),
              const Divider(height: 18, color: AppColors.borderDim),
              _switchRow(
                Icons.lock_outline_rounded,
                'Privacidade',
                'Controle quem acessa seus dados',
                _prefPrivacidade,
                (v) => setState(() => _prefPrivacidade = v),
              ),
            ],
          ),
        ),
      );

  Widget _ctaSeguranca() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bgBase.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: AppColors.bgBase, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sua saúde, sua prioridade',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bgBase,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mantenha sua conta protegida e seus dados sempre atualizados.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.bgBase.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Segurança da conta em breve.'),
                  duration: Duration(seconds: 1),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgBase,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ver segurança',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle(IconData icon, String title) => Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
      ]);

  Widget _infoRow(IconData icon, String label, String valor,
      {Color accent = AppColors.primary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  valor,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(IconData icon, String titulo, String subtitulo, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(subtitulo,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDim),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _PerfilFormResult {
  final String nome, cpf, telefone, dataNascimento;
  final String tipoSanguineo, alergias, convenio;
  const _PerfilFormResult({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.dataNascimento,
    required this.tipoSanguineo,
    required this.alergias,
    required this.convenio,
  });
}

class _EmergenciaFormResult {
  final String nome, parentesco, fone;
  const _EmergenciaFormResult({
    required this.nome,
    required this.parentesco,
    required this.fone,
  });
}

class _PerfilEditSheet extends StatefulWidget {
  const _PerfilEditSheet();

  @override
  State<_PerfilEditSheet> createState() => _PerfilEditSheetState();
}

class _PerfilEditSheetState extends State<_PerfilEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _cpfCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _nascCtrl;
  late final TextEditingController _alergCtrl;
  late final TextEditingController _convCtrl;
  String _tipoSang = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _cpfCtrl = TextEditingController();
    _telCtrl = TextEditingController();
    _nascCtrl = TextEditingController();
    _alergCtrl = TextEditingController();
    _convCtrl = TextEditingController();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    _nomeCtrl.text = u.displayName ?? '';
    try {
      final snap = await _firestore.collection('usuarios').doc(u.uid).get();
      if (snap.exists) {
        final d = snap.data()!;
        _cpfCtrl.text = (d['cpf'] ?? '') as String;
        _telCtrl.text = (d['telefone'] ?? '') as String;
        _nascCtrl.text = (d['dataNascimento'] ?? '') as String;
        _alergCtrl.text = (d['alergias'] ?? '') as String;
        _convCtrl.text = (d['convenio'] ?? '') as String;
        _tipoSang = (d['tipoSanguineo'] ?? '') as String;
      }
    } catch (e) {
      debugPrint('Erro: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telCtrl.dispose();
    _nascCtrl.dispose();
    _alergCtrl.dispose();
    _convCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_PerfilFormResult(
      nome: _nomeCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      telefone: _telCtrl.text.trim(),
      dataNascimento: _nascCtrl.text.trim(),
      tipoSanguineo: _tipoSang,
      alergias: _alergCtrl.text.trim(),
      convenio: _convCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgBase,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              _SheetHeader(
                titulo: 'Editar perfil',
                subtitulo: 'Atualize seus dados pessoais e de saúde.',
                onClose: () => Navigator.of(context).pop(),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionHeader(
                              icon: Icons.badge_outlined,
                              titulo: 'Dados pessoais'),
                          _Field(
                            controller: _nomeCtrl,
                            label: 'Nome completo',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe seu nome'
                                : null,
                          ),
                          _Field(
                            controller: _cpfCtrl,
                            label: 'CPF',
                            icon: Icons.fingerprint_rounded,
                            keyboardType: TextInputType.number,
                            hint: '000.000.000-00',
                          ),
                          _Field(
                            controller: _telCtrl,
                            label: 'Telefone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            hint: '(86) 9 9999-9999',
                          ),
                          _Field(
                            controller: _nascCtrl,
                            label: 'Data de nascimento',
                            icon: Icons.cake_outlined,
                            hint: 'DD/MM/AAAA',
                          ),
                          const SizedBox(height: 8),
                          const _SectionHeader(
                              icon: Icons.favorite_border_rounded,
                              titulo: 'Saúde'),
                          _Dropdown(
                            label: 'Tipo sanguíneo',
                            icon: Icons.bloodtype_outlined,
                            value: _tipoSang,
                            items: const ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                            onChanged: (v) =>
                                setState(() => _tipoSang = v ?? ''),
                          ),
                          _Field(
                            controller: _alergCtrl,
                            label: 'Alergias',
                            icon: Icons.warning_amber_rounded,
                            hint: 'Ex.: Dipirona, amendoim',
                            maxLines: 2,
                          ),
                          _Field(
                            controller: _convCtrl,
                            label: 'Convênio',
                            icon: Icons.medical_information_outlined,
                            hint: 'SUS, Unimed, etc.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              _SheetActions(onCancel: () => Navigator.of(context).pop(), onSave: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergenciaEditSheet extends StatefulWidget {
  final String nome, parentesco, fone;
  const _EmergenciaEditSheet({
    required this.nome,
    required this.parentesco,
    required this.fone,
  });

  @override
  State<_EmergenciaEditSheet> createState() => _EmergenciaEditSheetState();
}

class _EmergenciaEditSheetState extends State<_EmergenciaEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl =
      TextEditingController(text: widget.nome == '—' ? '' : widget.nome);
  late final _parentCtrl = TextEditingController(text: widget.parentesco);
  late final _foneCtrl = TextEditingController(text: widget.fone);

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _parentCtrl.dispose();
    _foneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_EmergenciaFormResult(
      nome: _nomeCtrl.text.trim(),
      parentesco: _parentCtrl.text.trim(),
      fone: _foneCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgBase,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            _SheetHeader(
              titulo: 'Contato de emergência',
              subtitulo:
                  'Pessoa que será contatada caso precise de atendimento.',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Field(
                      controller: _nomeCtrl,
                      label: 'Nome',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                    ),
                    _Field(
                      controller: _parentCtrl,
                      label: 'Parentesco',
                      icon: Icons.diversity_3_outlined,
                      hint: 'Mãe, pai, cônjuge...',
                    ),
                    _Field(
                      controller: _foneCtrl,
                      label: 'Telefone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: '(86) 9 9999-9999',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe um telefone'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            _SheetActions(
                onCancel: () => Navigator.of(context).pop(), onSave: _submit),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderDim,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}

class _SheetHeader extends StatelessWidget {
  final String titulo, subtitulo;
  final VoidCallback onClose;
  const _SheetHeader({
    required this.titulo,
    required this.subtitulo,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textTertiary, size: 22),
          ),
        ],
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  const _SheetActions({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderDim)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderDim),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text(
                'Salvar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String titulo;
  const _SectionHeader({required this.icon, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            titulo,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialText;
  final String label;
  final IconData icon;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;

  const _Field({
    this.controller,
    this.initialText,
    required this.label,
    required this.icon,
    this.hint,
    this.helper,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialText : null,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          isDense: true,
          filled: true,
          fillColor: AppColors.bgBase,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
          helperStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderDim),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderDim),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : '',
        dropdownColor: AppColors.bgBase,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        items: items
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.isEmpty ? 'Selecione...' : s,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight:
                          s.isEmpty ? FontWeight.w500 : FontWeight.w600,
                      color: s.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          isDense: true,
          filled: true,
          fillColor: AppColors.bgBase,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderDim),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderDim),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}
