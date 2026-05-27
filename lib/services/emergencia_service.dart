// lib/services/emergencia_service.dart
//
// Serviço de emergência conectado ao Cloud Firestore.
// Gerencia solicitações de SOS estruturadas em tempo real.

import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusEmergencia { aguardando, emAtendimento, resolvido, cancelado }

extension StatusEmergenciaX on StatusEmergencia {
  String get value => switch (this) {
        StatusEmergencia.aguardando => 'aguardando',
        StatusEmergencia.emAtendimento => 'em_atendimento',
        StatusEmergencia.resolvido => 'resolvido',
        StatusEmergencia.cancelado => 'cancelado',
      };
  static StatusEmergencia fromString(String s) => switch (s) {
        'aguardando' => StatusEmergencia.aguardando,
        'em_atendimento' => StatusEmergencia.emAtendimento,
        'resolvido' => StatusEmergencia.resolvido,
        'cancelado' => StatusEmergencia.cancelado,
        _ => StatusEmergencia.aguardando,
      };
}

class EmergenciaRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String categoria;
  final String descricao;
  final String endereco;
  final StatusEmergencia status;
  final DateTime createdAt;
  final GeoPoint? location;

  EmergenciaRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.categoria,
    required this.descricao,
    required this.endereco,
    required this.status,
    required this.createdAt,
    this.location,
  });

  factory EmergenciaRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return EmergenciaRequest(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? 'Desconhecido',
      userPhone: d['userPhone'] ?? '',
      categoria: d['categoria'] ?? 'Geral',
      descricao: d['descricao'] ?? '',
      endereco: d['endereco'] ?? 'Endereço não informado',
      status: StatusEmergenciaX.fromString(d['status'] ?? 'aguardando'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] as GeoPoint?,
    );
  }

  String get statusLabel => switch (status) {
        StatusEmergencia.aguardando => 'Aguardando Socorro',
        StatusEmergencia.emAtendimento => 'Em Atendimento',
        StatusEmergencia.resolvido => 'Resolvido',
        StatusEmergencia.cancelado => 'Cancelado',
      };
}

class EmergenciaService {
  EmergenciaService._();
  static final EmergenciaService instance = EmergenciaService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _emergenciasRef =>
      _db.collection('emergencias');

  /// O cidadão solicita socorro com informações estruturadas.
  Future<String> solicitarSocorro({
    required String userId,
    required String userName,
    String userPhone = '',
    required String categoria,
    required String descricao,
    required String endereco,
    GeoPoint? location,
  }) async {
    // FIX: Garantir que o campo status seja salvo exatamente como a query do Posto espera.
    final docRef = await _emergenciasRef.add({
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'categoria': categoria,
      'descricao': descricao,
      'endereco': endereco,
      'status': StatusEmergencia.aguardando.value, // 'aguardando'
      'createdAt': FieldValue.serverTimestamp(),
      'location': location,
    });
    return docRef.id;
  }

  /// Stream de solicitações ativas para o Posto.
  Stream<List<EmergenciaRequest>> streamEmergenciasAtivas() {
    // FIX: Removido orderBy temporariamente para testar se o problema é falta de índice
    // ou inconsistência no campo status.
    return _emergenciasRef
        .where('status', whereIn: [
          StatusEmergencia.aguardando.value,
          StatusEmergencia.emAtendimento.value,
        ])
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(EmergenciaRequest.fromDoc).toList();
          // Ordenar manualmente no app até o índice ser criado no Firestore se necessário
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream da emergência atual do usuário.
  Stream<EmergenciaRequest?> streamMinhaEmergencia(String userId) {
    return _emergenciasRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          StatusEmergencia.aguardando.value,
          StatusEmergencia.emAtendimento.value,
        ])
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : EmergenciaRequest.fromDoc(snap.docs.first));
  }

  /// Atualiza o status da emergência.
  Future<void> atualizarStatus(String id, StatusEmergencia status) async {
    await _emergenciasRef.doc(id).update({
      'status': status.value,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Cancela a solicitação (pelo cidadão).
  Future<void> cancelarSolicitacao(String id) =>
      atualizarStatus(id, StatusEmergencia.cancelado);

  /// Inicia atendimento (pelo posto).
  Future<void> iniciarAtendimento(String id) =>
      atualizarStatus(id, StatusEmergencia.emAtendimento);

  /// Finaliza atendimento (pelo posto).
  Future<void> finalizarAtendimento(String id) =>
      atualizarStatus(id, StatusEmergencia.resolvido);
}
