import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/app_animations.dart';
import '../../services/emergencia_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import 'dashboard_cidadao.dart';
import 'cidadao_escala_screen.dart';
import 'cidadao_fila_screen.dart';
import 'perfil_screen.dart';

class CidadaoEmergenciaScreen extends StatefulWidget {
  const CidadaoEmergenciaScreen({super.key});

  @override
  State<CidadaoEmergenciaScreen> createState() => _CidadaoEmergenciaScreenState();
}

class _CidadaoEmergenciaScreenState extends State<CidadaoEmergenciaScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  
  User? get _user => FirebaseAuth.instance.currentUser;
  
  String _categoriaSelecionada = 'Acidente / Trauma';
  final _descricaoController = TextEditingController();
  final _enderecoController = TextEditingController();

  final List<String> _categorias = [
    'Acidente / Trauma',
    'Mal Súbito / Desmaio',
    'Problema Cardíaco',
    'Problema Respiratório',
    'Obstétrico (Parto)',
    'Outros'
  ];

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    _descricaoController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _onAbaChanged(dynamic aba) {
    if (aba == DrawerAba.emergencia) return;
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
      case DrawerAba.perfil:
        return const PerfilScreen();
      case DrawerAba.emergencia:
        return const CidadaoEmergenciaScreen();
      default:
        return null;
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _solicitarSocorro() async {
    if (_user == null) return;
    if (!_formKey.currentState!.validate()) return;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar SOS?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Isso enviará um pedido de socorro imediato para a central com as informações fornecidas.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR', style: TextStyle(color: AppColors.textTertiary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(100, 45)),
            child: const Text('SOLICITAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EmergenciaService.instance.solicitarSocorro(
          userId: _user!.uid,
          userName: _user!.displayName ?? 'Usuário',
          userPhone: _user!.phoneNumber ?? '',
          categoria: _categoriaSelecionada,
          descricao: _descricaoController.text,
          endereco: _enderecoController.text,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao solicitar: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
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
            onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
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
        onProfilePressed: () => _onAbaChanged(DrawerAba.perfil),
      ),
      Expanded(child: _buildContent()),
    ]);
  }

  Widget _buildContent() {
    return StreamBuilder<EmergenciaRequest?>(
      stream: EmergenciaService.instance.streamMinhaEmergencia(_user?.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final request = snapshot.data;
        if (request == null) return _buildInitialState();
        return _buildActiveState(request);
      },
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              _buildAlertBanner(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 32),
              _buildSOSButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Atenção: Use este canal apenas para emergências reais que necessitem de socorro médico.',
              style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tipo de Emergência', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDim),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categoriaSelecionada,
                dropdownColor: Colors.white,
                style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary, fontSize: 14),
                isExpanded: true,
                items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _categoriaSelecionada = val!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Localização / Endereço', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _enderecoController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Onde você está?',
              fillColor: Colors.white,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Informe o endereço' : null,
          ),
          const SizedBox(height: 20),
          const Text('Descrição Rápida (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descricaoController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Ex: Queda de moto, dor forte no peito...',
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
        child: GestureDetector(
          onTap: _solicitarSocorro,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error,
              boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
              gradient: const LinearGradient(colors: [AppColors.error, Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency_rounded, color: Colors.white, size: 40),
                  Text('SOS', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveState(EmergenciaRequest request) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderDim),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emergency_rounded, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(request.statusLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.error)),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderDim),
                    const SizedBox(height: 12),
                    _detailRow('Categoria', request.categoria),
                    _detailRow('Local', request.endereco),
                    if (request.descricao.isNotEmpty) _detailRow('Info', request.descricao),
                    const SizedBox(height: 24),
                    if (request.status == StatusEmergencia.aguardando) const CircularProgressIndicator(color: AppColors.error),
                    if (request.status == StatusEmergencia.emAtendimento) const Icon(Icons.local_hospital_rounded, size: 48, color: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => EmergenciaService.instance.cancelarSolicitacao(request.id),
                icon: const Icon(Icons.close, color: AppColors.error),
                label: const Text('CANCELAR CHAMADO', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
