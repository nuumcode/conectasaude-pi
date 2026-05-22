// lib/services/fila_service.dart
//
// Serviço de fila virtual conectado ao Cloud Firestore.
// Substitui a versão in-memory baseada em ChangeNotifier.
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
}
// ─────────────────────────────────────────────────────────────
//  Serviço
// ─────────────────────────────────────────────────────────────
class FilaService {
  FilaService._();
  static final FilaService instance = FilaService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Identificador da fila atualmente ativa.
  /// Pode ser `postoId`, `postoId_especialidade`, etc.
  /// Trocar via [setFila] quando o usuário escolher outro posto/especialidade.
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
  /// Usado pela PostoFilaScreen.
  Stream<List<PacienteNaFila>> streamFila() {
    return _pacientesRef
        .orderBy('horaChegada')
        .snapshots()
        .map((snap) => snap.docs.map(PacienteNaFila.fromDoc).toList());
  }
  /// Apenas o paciente do usuário atual (para a tela do cidadão).
  /// Retorna null se ele ainda não pegou senha.
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
      // Atualiza/cria o documento da fila
      tx.set(_filaRef, {
        'proximaSenha': atual + 1,
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Cria o paciente
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
  /// Atualiza o status de um paciente — usado pela PostoFilaScreen.
  Future<void> atualizarStatus(String pacienteId, StatusFila novoStatus) async {
    await _pacientesRef.doc(pacienteId).update({
      'status': novoStatus.value,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
  /// Chama o próximo paciente aguardando (mais antigo na fila).
  /// Retorna o paciente que foi marcado como em atendimento, ou null.
  Future<PacienteNaFila?> chamarProximo() async {
    final query = await _pacientesRef
        .where('status', isEqualTo: StatusFila.aguardando.value)
        .orderBy('horaChegada')
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    await doc.reference.update({
      'status': StatusFila.emAtendimento.value,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return PacienteNaFila.fromDoc(doc);
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
  // (usados pelos widgets que já recebem a lista via StreamBuilder)
  static int aguardando(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.aguardando).length;
  static int atendidos(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.atendido).length;
  static int ausentes(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.ausente).length;
  static int emAtendimento(List<PacienteNaFila> fila) =>
      fila.where((p) => p.status == StatusFila.emAtendimento).length;
}
