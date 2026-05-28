import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  String _status = 'Aguardando...';

  Future<void> _setup() async {
    setState(() => _status = 'Iniciando...');
    try {
      // UID encontrado no Auth: E2mjNlCAJQRl1O4t5UXzBNWduKy1
      const uid = 'E2mjNlCAJQRl1O4t5UXzBNWduKy1';
      final data = {
        'nome': 'CETIL',
        'perfil': 'admin',
        'email': 'cetilt@conectasaude.com',
      };
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(data);
      setState(() => _status = 'Documento criado com sucesso!');
    } catch (e) {
      setState(() => _status = 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setup,
              child: const Text('Executar Criação do Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
