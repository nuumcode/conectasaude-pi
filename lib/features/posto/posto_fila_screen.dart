// lib/features/posto/posto_fila_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../../services/fila_service.dart';
import 'posto_dashboard_screen.dart';
import 'posto_chamar_screen.dart';
import 'posto_ausencia_screen.dart';
import 'posto_emergencia_screen.dart';

class PostoFilaScreen extends StatefulWidget {
  const PostoFilaScreen({super.key});
  @override
  State<PostoFilaScreen> createState() => _PostoFilaScreenState();
}

class _PostoFilaScreenState extends State<PostoFilaScreen> {
  final _filaSvc = FilaService.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  User? get _user => FirebaseAuth.instance.currentUser;

  static const _kPrimary = Color(0xFF1565D8);
  static const _kPrimaryDark = Color(0xFF0D47A1);
  static const _kAccent = Color(0xFF1565D8);
  static const _kBg = Color(0xFFF0F5FF);
  static const _kCardBg = Colors.white;
  static const _kTextPrimary = Color(0xFF1E293B);
  static const _kTextSecondary = Color(0xFF64748B);
  static const _kGreen = Color(0xFF10B981);
  static const _kRed = Color(0xFFEF4444);
  static const _kOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.fila) return;
    Widget? destino;
    if (aba == DrawerAba.inicio) destino = const PostoDashboardScreen();
    if (aba == DrawerAba.chamar) destino = const PostoChamarScreen();
    if (aba == DrawerAba.ausencia) destino = const PostoAusenciaScreen();
    if (aba == DrawerAba.emergencia) destino = const PostoEmergenciaScreen();

    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
  }

  PacienteNaFila? _pacienteAtual(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.emAtendimento).firstOrNull;
  
  List<PacienteNaFila> _filaEspera(List<PacienteNaFila> fila) {
    final lista = fila.where((p) => p.status == StatusFila.aguardando).toList()
      ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: isDesktop ? null : AppDrawer(
        userName: _user?.displayName ?? 'Atendente',
        userEmail: _user?.email ?? '',
        userPhoto: _user?.photoURL,
        abaAtual: DrawerAba.fila,
        onAbaChanged: _onAbaChanged,
        onLogout: _logout,
        role: UserRole.posto,
      ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  Widget _buildDesktop() {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Atendente',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.fila,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
          role: UserRole.posto,
        ),
      ),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Gestor',
            userPhoto: _user?.photoURL,
            title: 'Fila do Posto',
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () {},
          ),
          Expanded(child: _buildStreamContent(true)),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Gestor',
        userPhoto: _user?.photoURL,
        title: 'Fila do Posto',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      Expanded(child: _buildStreamContent(false)),
    ]);
  }

  Widget _buildStreamContent(bool isDesktop) {
    return StreamBuilder<List<PacienteNaFila>>(
      stream: _filaSvc.streamFila(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final fila = snap.data ?? [];
        final isWide = MediaQuery.of(context).size.width >= 768;

        return Column(
          children: [
             _buildHeaderSub(),
            Expanded(
              child: isWide
                  ? _buildWideLayout(fila)
                  : _buildNarrowLayout(fila),
            ),
            _buildBottomStats(fila),
          ],
        );
      },
    );
  }

  Widget _buildHeaderSub() {
    final now = DateTime.now();
    final dateStr = DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR').format(now);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Text(
        dateStr.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildWideLayout(List<PacienteNaFila> fila) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildPacienteAtualCard(fila)),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _buildFilaAoVivo(fila)),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(List<PacienteNaFila> fila) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPacienteAtualCard(fila),
          const SizedBox(height: 16),
          SizedBox(height: 400, child: _buildFilaAoVivo(fila)),
        ],
      ),
    );
  }

  Widget _buildPacienteAtualCard(List<PacienteNaFila> fila) {
    final pac = _pacienteAtual(fila);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: pac != null ? _kPrimary : _kTextSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PACIENTE ATUAL',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pac != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSenhaGrande(pac.senha),
                const SizedBox(width: 24),
                Expanded(child: _buildPacienteInfo(pac)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 24),
            _buildActionButtons(pac),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Nenhum paciente em atendimento',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: _kTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 24),
            _buildActionButtons(null),
          ],
        ],
      ),
    );
  }

  Widget _buildSenhaGrande(String senha) {
    return Column(
      children: [
        const Text('SENHA', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _kTextSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: _kPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kPrimary.withOpacity(0.15))),
          child: Text(senha, style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w800, color: _kPrimary)),
        ),
      ],
    );
  }

  Widget _buildPacienteInfo(PacienteNaFila pac) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pac.nome, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: _kTextPrimary)),
        const SizedBox(height: 8),
        _infoRow(Icons.medical_services_outlined, pac.especialidade),
        const SizedBox(height: 12),
        _timeChip(Icons.schedule, pac.horaFormatada, 'Chegada'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: _kTextSecondary), const SizedBox(width: 8), Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _kTextSecondary)))]);
  }

  Widget _timeChip(IconData icon, String time, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _kTextSecondary),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: _kTextSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildActionButtons(PacienteNaFila? pacAtual) {
    return Column(
      children: [
        if (pacAtual != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _filaSvc.finalizarAtendimento(pacAtual.id),
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('FINALIZAR ATENDIMENTO', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _filaSvc.chamarProximo(),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                icon: const Icon(Icons.campaign_rounded, size: 20),
                label: const Text('CHAMAR PRÓXIMO', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pacAtual == null ? null : () => _filaSvc.atualizarStatus(pacAtual.id, StatusFila.ausente),
                style: OutlinedButton.styleFrom(foregroundColor: _kRed, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFFE2E8F0))),
                icon: const Icon(Icons.person_off_outlined, size: 20),
                label: const Text('AUSÊNCIA', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilaAoVivo(List<PacienteNaFila> fila) {
    final espera = _filaEspera(fila);
    return Container(
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kPrimary.withOpacity(0.1)), boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12), child: Row(children: [const Icon(Icons.queue_rounded, size: 18, color: _kPrimary), const SizedBox(width: 8), const Text('FILA AO VIVO', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary, letterSpacing: 1)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('${espera.length} na fila', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: _kAccent)))])) ,
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: espera.length, separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)), itemBuilder: (_, i) => _buildFilaItem(espera[i], i + 1))),
        ],
      ),
    );
  }

  Widget _buildFilaItem(PacienteNaFila pac, int posicao) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: _kPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(pac.senha, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary)))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pac.nome, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: _kTextPrimary), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text('${pac.especialidade} • ${pac.horaFormatada}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _kTextSecondary))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Text('Aguardando', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _kOrange)))]));
  }

  Widget _buildBottomStats(List<PacienteNaFila> fila) {
    final aguardando = fila.where((p) => p.status == StatusFila.aguardando).length;
    final atendidos = fila.where((p) => p.status == StatusFila.atendido).length;
    final emAtendimento = fila.where((p) => p.status == StatusFila.emAtendimento).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(color: _kCardBg, border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.person_rounded, '$emAtendimento', 'Em atendimento', _kAccent),
          _statItem(Icons.schedule_rounded, '$aguardando', 'Aguardando', _kOrange),
          _statItem(Icons.check_circle_rounded, '$atendidos', 'Atendidos', _kGreen),
          _statItem(Icons.groups_rounded, '${fila.length}', 'Fila completa', _kPrimary),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: color))]), const SizedBox(height: 2), Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w500, color: _kTextSecondary), textAlign: TextAlign.center)]));
  }
}
