import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import '../../services/emergencia_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import 'posto_dashboard_screen.dart';
import 'posto_fila_screen.dart';
import 'posto_chamar_screen.dart';
import 'posto_ausencia_screen.dart';

class PostoEmergenciaScreen extends StatefulWidget {
  const PostoEmergenciaScreen({super.key});

  @override
  State<PostoEmergenciaScreen> createState() => _PostoEmergenciaScreenState();
}

class _PostoEmergenciaScreenState extends State<PostoEmergenciaScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  User? get _user => FirebaseAuth.instance.currentUser;

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.emergencia) return;
    Widget? destino;
    if (aba == DrawerAba.inicio) destino = const PostoDashboardScreen();
    if (aba == DrawerAba.chamar) destino = const PostoChamarScreen();
    if (aba == DrawerAba.ausencia) destino = const PostoAusenciaScreen();
    if (aba == DrawerAba.fila) destino = const PostoFilaScreen();

    if (destino != null) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: destino));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : AppDrawer(
        userName: _user?.displayName ?? 'Gestor de Posto',
        userEmail: _user?.email ?? '',
        userPhoto: _user?.photoURL,
        abaAtual: DrawerAba.emergencia,
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
          userName: _user?.displayName ?? 'Gestor de Posto',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.emergencia,
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
            title: 'Chamadas de Emergência',
            onLogout: _logout,
            onMenuPressed: null,
            onProfilePressed: () {},
          ),
          Expanded(child: _buildContent()),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    return Column(children: [
      AppHeader(
        userName: _user?.displayName?.split(' ').first ?? 'Gestor',
        userPhoto: _user?.photoURL,
        title: 'Chamadas de Emergência',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      Expanded(child: _buildContent()),
    ]);
  }

  Widget _buildContent() {
    return StreamBuilder<List<EmergenciaRequest>>(
      stream: EmergenciaService.instance.streamEmergenciasAtivas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final emergencias = snapshot.data ?? [];
        
        if (emergencias.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma emergência ativa',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emergencias.length,
          itemBuilder: (context, index) {
            final em = emergencias[index];
            return _buildEmergenciaCard(em);
          },
        );
      },
    );
  }

  Widget _buildEmergenciaCard(EmergenciaRequest em) {
    final isAguardando = em.status == StatusEmergencia.aguardando;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAguardando ? const Color(0xFFFFF1F1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAguardando ? Colors.red.withOpacity(0.2) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAguardando ? Colors.red : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      em.userName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Solicitado em: ${em.createdAt.hour}:${em.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAguardando ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  em.statusLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isAguardando)
                ElevatedButton.icon(
                  onPressed: () => EmergenciaService.instance.iniciarAtendimento(em.id),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('ATENDER', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                ),
              if (!isAguardando)
                ElevatedButton.icon(
                  onPressed: () => EmergenciaService.instance.finalizarAtendimento(em.id),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text('FINALIZAR', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeep, elevation: 0),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
