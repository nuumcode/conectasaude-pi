// lib/services/fila_service.dart
//
// Serviço de fila virtual conectado ao Cloud Firestore.
//
// Estrutura no Firestore:
//   filas/{filaId}/pacientes/{pacienteId}
//
// Tanto a CidadaoFilaScreen quanto a PostoFilaScreen consomem os mesmos
// snapshots — qualquer alteração é propagada em tempo real.
import 'package:cloud_firestore/cloud_firestore.dart';
// ─────────────────────────────────────────────────────────────
//  Status
// ─────────────────────────────────────────────────────────────
enum StatusFila { aguardando, emAtendimento, atendido, ausente }
extension StatusFilaX on StatusFila {
  String get value => switch (this) {
        StatusFila.aguardando => 'aguardando',
        StatusFila.emAtendimento => 'em_atendimento',
        StatusFila.atendido => 'atendido',
        StatusFila.ausente => 'ausente',
      };
  static StatusFila fromString(String s) => switch (s) {
        'aguardando' => StatusFila.aguardando,
        'em_atendimento' => StatusFila.emAtendimento,
        'atendido' => StatusFila.atendido,
        'ausente' => StatusFila.ausente,
        _ => StatusFila.aguardando,
      };
}
// ─────────────────────────────────────────────────────────────
//  Modelo
// ─────────────────────────────────────────────────────────────
class PacienteNaFila {
  final String id;
  final String nome;
  final String senha;
  final String especialidade;
  final StatusFila status;
  final DateTime horaChegada;
  final String? userId;
  var sus;
  var cpf;
  PacienteNaFila({
    required this.id,
    required this.nome,
    required this.senha,
    required this.especialidade,
    required this.status,
    required this.horaChegada,
    this.userId,
  });
  factory PacienteNaFila.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PacienteNaFila(
      id: doc.id,
      nome: (d['nome'] as String?) ?? 'Sem nome',
      senha: (d['senha'] as String?) ?? '---',
      especialidade: (d['especialidade'] as String?) ?? 'Clínica Geral',
      status: StatusFilaX.fromString((d['status'] as String?) ?? 'aguardando'),
      horaChegada: (d['horaChegada'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: d['userId'] as String?,
    );
  }
  String get statusLabel => switch (status) {
        StatusFila.aguardando => 'Aguardando',
        StatusFila.emAtendimento => 'Em atendimento',
        StatusFila.atendido => 'Atendido',
        StatusFila.ausente => 'Ausente',
      };
  String get horaFormatada {
    final h = horaChegada.hour.toString().padLeft(2, '0');
    final m = horaChegada.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  String get chamadaFormatada => '$senha - $nome';
}
// ─────────────────────────────────────────────────────────────
//  Serviço
// ─────────────────────────────────────────────────────────────
class FilaService {
  FilaService._();
  static final FilaService instance = FilaService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Identificador da fila atualmente ativa.
  String _filaId = 'ubs_centro_clinica_geral';
  String get filaId => _filaId;
  void setFila(String id) => _filaId = id;
  // ── Referências ───────────────────────────────────────────
  DocumentReference<Map<String, dynamic>> get _filaRef =>
      _db.collection('filas').doc(_filaId);
  CollectionReference<Map<String, dynamic>> get _pacientesRef =>
      _filaRef.collection('pacientes');
  // ── Streams ───────────────────────────────────────────────
  /// Toda a fila, ordenada por chegada.
  /// Usado pela PostoFilaScreen e CidadaoFilaScreen.
  Stream<List<PacienteNaFila>> streamFila() {
    return _pacientesRef
        .orderBy('horaChegada')
        .snapshots()
        .map((snap) => snap.docs.map(PacienteNaFila.fromDoc).toList());
  }
  /// Apenas o paciente do usuário atual (para a tela do cidadão).
  Stream<PacienteNaFila?> streamMeuPaciente(String userId) {
    return _pacientesRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['aguardando', 'em_atendimento'])
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : PacienteNaFila.fromDoc(snap.docs.first));
  }
  // ── Ações do cidadão ──────────────────────────────────────
  /// O cidadão pega uma senha. Retorna o paciente criado.
  Future<PacienteNaFila> entrarNaFila({
    required String nome,
    required String especialidade,
    required String userId,
  }) async {
    return _db.runTransaction<PacienteNaFila>((tx) async {
      final filaSnap = await tx.get(_filaRef);
      final atual = (filaSnap.data()?['proximaSenha'] as int?) ?? 1;
      final senha = 'A-${atual.toString().padLeft(2, '0')}';
      tx.set(_filaRef, {
        'proximaSenha': atual + 1,
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final docRef = _pacientesRef.doc();
      final hora = DateTime.now();
      tx.set(docRef, {
        'nome': nome,
        'senha': senha,
        'especialidade': especialidade,
        'status': StatusFila.aguardando.value,
        'horaChegada': Timestamp.fromDate(hora),
        'userId': userId,
      });
      return PacienteNaFila(
        id: docRef.id,
        nome: nome,
        senha: senha,
        especialidade: especialidade,
        status: StatusFila.aguardando,
        horaChegada: hora,
        userId: userId,
      );
    });
  }
  /// O cidadão sai da fila (remove o documento).
  Future<void> sairDaFila(String pacienteId) async {
    await _pacientesRef.doc(pacienteId).delete();
  }
  // ── Ações do posto ────────────────────────────────────────
  /// Atualiza o status de um paciente.
  Future<void> atualizarStatus(String pacienteId, StatusFila novoStatus) async {
    await _pacientesRef.doc(pacienteId).update({
      'status': novoStatus.value,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
  /// Finaliza o atendimento atual — marca como atendido.
  Future<void> finalizarAtendimento(String pacienteId) =>
      atualizarStatus(pacienteId, StatusFila.atendido);
  /// Chama o próximo paciente aguardando (mais antigo na fila).
  ///
  /// Comportamento:
  /// - Se já existe paciente "em atendimento", finaliza ele (vira "atendido")
  ///   antes de chamar o próximo.
  /// - Usa transação para evitar race condition (dois atendentes clicando
  ///   "Chamar Próximo" ao mesmo tempo não chamam o mesmo paciente).
  /// - Retorna o paciente recém-chamado, ou null se a fila estava vazia.
  Future<PacienteNaFila?> chamarProximo() async {
    // 1. Busca o próximo aguardando (mais antigo)
    final aguardandoQuery = await _pacientesRef
        .where('status', isEqualTo: StatusFila.aguardando.value)
        .orderBy('horaChegada')
        .limit(1)
        .get();
    // 2. Busca paciente atualmente em atendimento (se houver)
    final emAtendimentoQuery = await _pacientesRef
        .where('status', isEqualTo: StatusFila.emAtendimento.value)
        .limit(1)
        .get();
    if (aguardandoQuery.docs.isEmpty) return null;
    final proximoRef = aguardandoQuery.docs.first.reference;
    final atualRef = emAtendimentoQuery.docs.isEmpty
        ? null
        : emAtendimentoQuery.docs.first.reference;
    // 3. Transação atômica: finaliza o atual + promove o próximo
    return _db.runTransaction<PacienteNaFila>((tx) async {
      // Releitura dentro da transação para garantir consistência
      final proximoSnap = await tx.get(proximoRef);
      if (!proximoSnap.exists) {
        throw StateError('Paciente sumiu antes de ser chamado.');
      }
      // Finaliza atendimento anterior, se houver
      if (atualRef != null) {
        tx.update(atualRef, {
          'status': StatusFila.atendido.value,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }
      // Promove o próximo
      tx.update(proximoRef, {
        'status': StatusFila.emAtendimento.value,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      // Reconstrói o paciente já com o status novo
      final data = Map<String, dynamic>.from(proximoSnap.data() ?? {});
      data['status'] = StatusFila.emAtendimento.value;
      return PacienteNaFila(
        id: proximoSnap.id,
        nome: (data['nome'] as String?) ?? 'Sem nome',
        senha: (data['senha'] as String?) ?? '---',
        especialidade: (data['especialidade'] as String?) ?? 'Clínica Geral',
        status: StatusFila.emAtendimento,
        horaChegada:
            (data['horaChegada'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userId: data['userId'] as String?,
      );
    });
  }
  /// Adiciona um paciente fictício (botão de simulação no posto).
  Future<void> simularNovoPaciente() async {
    final fakeId = 'sim_${DateTime.now().millisecondsSinceEpoch}';
    await entrarNaFila(
      nome: 'Paciente Simulado',
      especialidade: 'Clínica Geral',
      userId: fakeId,
    );
  }
  // ── Contadores síncronos a partir de uma lista ────────────
  static int aguardando(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.aguardando).length;
  static int atendidos(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.atendido).length;
  static int ausentes(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.ausente).length;
  static int emAtendimento(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.emAtendimento).length;
}
