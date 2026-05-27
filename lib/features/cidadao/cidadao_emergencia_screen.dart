import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import '../../services/emergencia_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import 'dashboard_cidadao.dart';

class CidadaoEmergenciaScreen extends StatefulWidget {
  const CidadaoEmergenciaScreen({super.key});

  @override
  State<CidadaoEmergenciaScreen> createState() => _CidadaoEmergenciaScreenState();
}

class _CidadaoEmergenciaScreenState extends State<CidadaoEmergenciaScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  User? get _user => FirebaseAuth.instance.currentUser;
  
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.emergencia) return;
    if (aba == DrawerAba.inicio) {
      Navigator.of(context).pushReplacement(AppFadeRoute(page: const HomeCidadaoScreen()));
    } else {
       // Outras rotas seriam tratadas aqui ou voltando ao dashboard
       Navigator.of(context).pushReplacement(AppFadeRoute(page: const HomeCidadaoScreen()));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _solicitarSocorro() async {
    if (_user == null) return;
    
    // Mostrar confirmação rápida
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar SOS?'),
        content: const Text('Isso enviará um pedido de socorro imediato para a central do posto.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SOLICITAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await EmergenciaService.instance.solicitarSocorro(
        userId: _user!.uid,
        userName: _user!.displayName ?? 'Usuário',
        userPhone: _user!.phoneNumber ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDF2F2), // Vermelho bem clarinho
      drawer: isDesktop ? null : AppDrawer(
        userName: _user?.displayName ?? 'Usuário',
        userEmail: _user?.email ?? '',
        userPhoto: _user?.photoURL,
        abaAtual: DrawerAba.emergencia,
        onAbaChanged: _onAbaChanged,
        onLogout: _logout,
      ),
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  Widget _buildDesktop() {
    return Row(children: [
      SizedBox(
        width: 260,
        child: AppDrawer(
          userName: _user?.displayName ?? 'Usuário',
          userEmail: _user?.email ?? '',
          userPhoto: _user?.photoURL,
          abaAtual: DrawerAba.emergencia,
          onAbaChanged: _onAbaChanged,
          onLogout: _logout,
          isFixed: true,
        ),
      ),
      Expanded(
        child: Column(children: [
          AppHeader(
            userName: _user?.displayName?.split(' ').first ?? 'Usuário',
            userPhoto: _user?.photoURL,
            title: 'Emergência SOS',
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
        userName: _user?.displayName?.split(' ').first ?? 'Usuário',
        userPhoto: _user?.photoURL,
        title: 'Emergência SOS',
        onLogout: _logout,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () {},
      ),
      Expanded(child: _buildContent()),
    ]);
  }

  Widget _buildContent() {
    return StreamBuilder<EmergenciaRequest?>(
      stream: EmergenciaService.instance.streamMinhaEmergencia(_user?.uid ?? ''),
      builder: (context, snapshot) {
        final request = snapshot.data;
        
        if (request == null) {
          return _buildInitialState();
        }
        
        return _buildActiveState(request);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Você está em uma emergência?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Clique no botão abaixo para enviar sua localização e solicitar socorro imediato do posto de saúde mais próximo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 60),
            _buildSOSButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: GestureDetector(
        onTap: _solicitarSocorro,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
            gradient: const LinearGradient(
              colors: [Colors.red, Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveState(EmergenciaRequest request) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.emergency_rounded, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    request.statusLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sua solicitação foi enviada. Mantenha a calma, o socorro está a caminho.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (request.status == StatusEmergencia.aguardando)
                    const CircularProgressIndicator(color: Colors.red),
                  if (request.status == StatusEmergencia.emAtendimento)
                     const Icon(Icons.local_hospital_rounded, size: 48, color: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () => EmergenciaService.instance.cancelarSolicitacao(request.id),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('CANCELAR SOLICITAÇÃO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
