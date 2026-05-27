import 'package:conecta_saude_pi/features/posto/posto_emergencia_screen.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/animations/app_animations.dart';
import '../auth/login_admin_screen.dart';
import 'posto_dashboard_screen.dart';
import 'posto_fila_screen.dart';
import 'posto_chamar_screen.dart';

class PostoAusenciaScreen extends StatefulWidget {
  const PostoAusenciaScreen({super.key});
  @override
  State<PostoAusenciaScreen> createState() => _PostoAusenciaScreenState();
}

class _PostoAusenciaScreenState extends State<PostoAusenciaScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppFadeRoute(page: const LoginAdminScreen()),
    );
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.ausencia) return;
    Widget? destino;
    if (aba == DrawerAba.inicio) destino = const PostoDashboardScreen();
    if (aba == DrawerAba.chamar) destino = const PostoChamarScreen();
    if (aba == DrawerAba.fila) destino = const PostoFilaScreen();
    if (aba == DrawerAba.emergencia) destino = const PostoEmergenciaScreen();

    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Em breve.'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  final List<_Ausencia> _ausencias = [
    _Ausencia('Raimundo Nonato', 'A-10', 'Clínica Geral', '09:02', '09:20', 1),
    _Ausencia('Tereza Cristina', 'B-03', 'Pediatria', '08:15', '08:45', 2),
    _Ausencia('José Almeida', 'A-08', 'Cardiologia', '07:50', '08:30', 3),
    _Ausencia('Sandra Mota', 'B-07', 'Ginecologia', '08:30', '09:10', 1),
    _Ausencia('Marcos Vinicius', 'A-12', 'Clínica Geral', '09:10', '09:35', 1),
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW >= 700;

    final hoje = _ausencias.where((a) => a.chamadas < 3).toList();
    final perdidas = _ausencias.where((a) => a.chamadas >= 3).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
      drawer: isDesktop
          ? null
          : AppDrawer(
              userName: _user?.displayName ?? 'Gestor de Posto',
              userEmail: _user?.email ?? '',
              userPhoto: _user?.photoURL,
              abaAtual: DrawerAba.ausencia,
              onAbaChanged: _onAbaChanged,
              onLogout: _logout,
              role: UserRole.posto,
            ),
      body: isDesktop
          ? _buildDesktop(hoje, perdidas)
          : _buildMobile(hoje, perdidas),
    );
  }

  Widget _buildDesktop(List<_Ausencia> hoje, List<_Ausencia> perdidas) {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Gestor de Posto',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.ausencia,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
          role: UserRole.posto,
        ),
      ),
      Container(width: 1, color: AppColors.borderDim),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Gestor',
            userPhoto: _user?.photoURL,
            title: 'Gestão de Ausências',
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () {},
          ),
          Expanded(child: _buildScrollableContent(hoje, perdidas)),
        ]),
      ),
    ]);
  }

  Widget _buildMobile(List<_Ausencia> hoje, List<_Ausencia> perdidas) {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Gestor',
        userPhoto: _user?.photoURL,
        title: 'Gestão de Ausências',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      Expanded(child: _buildScrollableContent(hoje, perdidas)),
    ]);
  }

  Widget _buildScrollableContent(
      List<_Ausencia> hoje, List<_Ausencia> perdidas) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumo(),
          const SizedBox(height: 24),
          _sectionTitle('Pacientes ausentes (reconvocáveis)', hoje.length),
          const SizedBox(height: 12),
          ...hoje.map((a) => _buildAusenciaCard(a, reconvocavel: true)),
          const SizedBox(height: 28),
          _sectionTitle('Perderam a vez (3 chamadas)', perdidas.length),
          const SizedBox(height: 12),
          ...perdidas.map((a) => _buildAusenciaCard(a, reconvocavel: false)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.person_off_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_ausencias.length} ausências hoje',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                Text(
                  '${_ausencias.where((a) => a.chamadas < 3).length} reconvocáveis • ${_ausencias.where((a) => a.chamadas >= 3).length} perderam a vez',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
        ),
      ],
    );
  }

  Widget _buildAusenciaCard(_Ausencia aus, {required bool reconvocavel}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Row(
        children: [
          // Info paciente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(aus.senha,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(aus.nome,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(aus.especialidade,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(width: 8),
                    Text('Chamado: ${aus.horaChamada}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${aus.chamadas}/3 chamadas',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: aus.chamadas >= 3
                                ? AppColors.error
                                : AppColors.warning,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ações
          if (reconvocavel) ...[
            const SizedBox(width: 10),
            Column(
              children: [
                _actionBtn(
                    'Reconvocar', Icons.campaign_rounded, AppColors.success,
                    () {
                  setState(() => aus.chamadas++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reconvocando ${aus.nome}...'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }),
                const SizedBox(height: 6),
                _actionBtn('Fim da fila', Icons.low_priority_rounded,
                    AppColors.warning, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${aus.nome} movido para o fim da fila'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Perdeu a vez',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  )),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: cor),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cor,
                )),
          ],
        ),
      ),
    );
  }
}

class _Ausencia {
  final String nome;
  final String senha;
  final String especialidade;
  final String horaChegada;
  final String horaChamada;
  int chamadas;
  _Ausencia(this.nome, this.senha, this.especialidade, this.horaChegada,
      this.horaChamada, this.chamadas);
}
