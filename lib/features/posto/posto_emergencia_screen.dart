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
      backgroundColor: AppColors.bgBase,
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
            title: 'Central de Emergências',
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
        title: 'Central de Emergências',
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
        
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
        }

        final emergencias = snapshot.data ?? [];
        
        if (emergencias.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.accent.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma emergência ativa no momento',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white60),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emergencias.length,
          itemBuilder: (context, index) => _buildEmergenciaCard(emergencias[index]),
        );
      },
    );
  }

  Widget _buildEmergenciaCard(EmergenciaRequest em) {
    final isAguardando = em.status == StatusEmergencia.aguardando;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isAguardando ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAguardando ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isAguardando ? Colors.red : Colors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(em.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text('Solicitado há ${DateTime.now().difference(em.createdAt).inMinutes} min', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isAguardando ? Colors.red : Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: Text(em.statusLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          // Detalhes do Chamado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.category_outlined, 'Categoria', em.categoria),
                _infoRow(Icons.location_on_outlined, 'Endereço', em.endereco, isBold: true),
                if (em.descricao.isNotEmpty) _infoRow(Icons.description_outlined, 'Descrição', em.descricao),
                if (em.userPhone.isNotEmpty) _infoRow(Icons.phone_outlined, 'Contato', em.userPhone),
              ],
            ),
          ),
          
          // Ações
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (isAguardando)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => EmergenciaService.instance.iniciarAtendimento(em.id),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: const Text('INICIAR ATENDIMENTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => EmergenciaService.instance.finalizarAtendimento(em.id),
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text('FINALIZAR OCORRÊNCIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeep, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}
