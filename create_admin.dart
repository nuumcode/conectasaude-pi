import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  const uid = 'E2mjNlCAJQRl1O4t5UXzBNWduKy1';
  final data = {
    'nome': 'CETIL',
    'perfil': 'admin',
    'email': 'cetilt@conectasaude.com',
  };
  
  print('Iniciando criação do usuário admin...');
  try {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(data);
    print('Documento criado com sucesso!');
  } catch (e) {
    print('Erro ao criar documento: $e');
  }
}
