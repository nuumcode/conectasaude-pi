// lib/services/fila_service.dart
//
// Serviço de fila virtual conectado ao Cloud Firestore.
//
// Estrutura no Firestore:
//   filas/{filaId}/pacientes/{pacienteId}
//
// Tanto a CidadaoFilaScreen quanto a PostoFilaScreen consomem os mesmos
// snapshots — qualquer alteração é propagada em tempo real.
//
// ÍNDICES COMPOSTOS NECESSÁRIOS no Firestore (criar via console):
//   1. pacientes: status (ASC) + horaChegada (ASC)
//      → usado por chamarProximo() e queries de filtro por status.
//   2. pacientes: userId (ASC) + status (ASC)
//      → usado por streamMeuPaciente().
// O console do Firebase oferece um link "criar índice" no erro
// "failed-precondition" da primeira execução de cada query.
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
//  Exceções tipadas — evitam catch(e) com string comparison
// ─────────────────────────────────────────────────────────────

/// Lançada quando o usuário tenta entrar na fila mais de uma vez.
class JaNaFilaException implements Exception {
  final String message;
  const JaNaFilaException([this.message = 'Você já está na fila.']);
  @override
  String toString() => message;
}

/// Lançada quando a fila está vazia e não há próximo paciente.
class FilaVaziaException implements Exception {
  const FilaVaziaException();
  @override
  String toString() => 'Nenhum paciente aguardando na fila.';
}

/// Lançada quando há concorrência e o paciente foi chamado por outro atendente.
class ConflitoChamadaException implements Exception {
  const ConflitoChamadaException();
  @override
  String toString() => 'Este paciente já foi chamado por outro atendente.';
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
  final String? sus;
  final String? cpf;

  const PacienteNaFila({
    required this.id,
    required this.nome,
    required this.senha,
    required this.especialidade,
    required this.status,
    required this.horaChegada,
    this.userId,
    this.sus,
    this.cpf,
  });

  factory PacienteNaFila.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PacienteNaFila(
      id: doc.id,
      nome: (d['nome'] as String?) ?? 'Sem nome',
      senha: (d['senha'] as String?) ?? '---',
      especialidade: (d['especialidade'] as String?) ?? 'Clínica Geral',
      status: StatusFilaX.fromString((d['status'] as String?) ?? 'aguardando'),
      horaChegada:
          (d['horaChegada'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: d['userId'] as String?,
      sus: d['sus'] as String?,
      cpf: d['cpf'] as String?,
    );
  }

  /// Cria uma cópia com campos substituídos.
  PacienteNaFila copyWith({
    String? id,
    String? nome,
    String? senha,
    String? especialidade,
    StatusFila? status,
    DateTime? horaChegada,
    String? userId,
    String? sus,
    String? cpf,
  }) {
    return PacienteNaFila(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      senha: senha ?? this.senha,
      especialidade: especialidade ?? this.especialidade,
      status: status ?? this.status,
      horaChegada: horaChegada ?? this.horaChegada,
      userId: userId ?? this.userId,
      sus: sus ?? this.sus,
      cpf: cpf ?? this.cpf,
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

  /// Texto de apresentação da senha + nome (ex: "A-01 - Maria Silva").
  String get senhaComNome => '$senha - $nome';

  @Deprecated('Use senhaComNome — chamadaFormatada é nome confuso.')
  String get chamadaFormatada => senhaComNome;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PacienteNaFila && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PacienteNaFila(id: $id, nome: $nome, senha: $senha, status: ${status.value})';
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
  void setFila(String id) {
    assert(id.trim().isNotEmpty, 'filaId não pode ser vazio.');
    _filaId = id.trim();
  }

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
        .map((snap) => snap.docs.map(PacienteNaFila.fromDoc).toList())
        .handleError((Object err, StackTrace st) {
      debugPrint('[FilaService] streamFila erro: $err\n$st');
      // Relança para que o StreamBuilder exiba o estado de erro.
      throw err;
    });
  }

  /// Apenas o paciente do usuário atual (para a tela do cidadão).
  /// Exige índice composto userId + status no Firestore.
  Stream<PacienteNaFila?> streamMeuPaciente(String userId) {
    assert(userId.trim().isNotEmpty, 'userId não pode ser vazio.');
    return _pacientesRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          StatusFila.aguardando.value,
          StatusFila.emAtendimento.value,
        ])
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : PacienteNaFila.fromDoc(snap.docs.first))
        .handleError((Object err, StackTrace st) {
          debugPrint('[FilaService] streamMeuPaciente erro: $err\n$st');
          throw err;
        });
  }

  /// Calcula a posição do paciente na fila (1-based).
  /// Retorna 0 se ele já foi chamado (em atendimento).
  /// Retorna -1 se não está aguardando nem sendo atendido.
  static int posicaoNaFila(PacienteNaFila meu, List<PacienteNaFila> fila) {
    if (meu.status == StatusFila.emAtendimento) return 0;
    if (meu.status != StatusFila.aguardando) return -1;

    final aguardando = fila
        .where((p) => p.status == StatusFila.aguardando)
        .toList()
      ..sort((a, b) => a.horaChegada.compareTo(b.horaChegada));

    final idx = aguardando.indexWhere((p) => p.id == meu.id);
    return idx < 0 ? -1 : idx + 1;
  }

  // ── Ações do cidadão ──────────────────────────────────────

  /// O cidadão pega uma senha. Retorna o paciente criado.
  ///
  /// Lança [JaNaFilaException] se o userId já tiver um registro
  /// aguardando ou em atendimento — evita senhas duplicadas.
  Future<PacienteNaFila> entrarNaFila({
    required String nome,
    required String especialidade,
    required String userId,
  }) async {
    assert(userId.trim().isNotEmpty, 'userId não pode ser vazio.');
    assert(especialidade.trim().isNotEmpty, 'especialidade não pode ser vazia.');

    final nomeLimpo = _sanitizarNome(nome);

    // Verifica duplicata ANTES da transação para feedback rápido.
    // A transação abaixo é a proteção definitiva (race-condition safe).
    final existente = await _pacientesRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          StatusFila.aguardando.value,
          StatusFila.emAtendimento.value,
        ])
        .limit(1)
        .get();

    if (existente.docs.isNotEmpty) {
      throw const JaNaFilaException();
    }

    return _db.runTransaction<PacienteNaFila>((tx) async {
      final filaSnap = await tx.get(_filaRef);
      final atual = (filaSnap.data()?['proximaSenha'] as int?) ?? 1;
      final senha = 'A-${atual.toString().padLeft(2, '0')}';

      tx.set(
        _filaRef,
        {
          'proximaSenha': atual + 1,
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final docRef = _pacientesRef.doc();
      final hora = DateTime.now();

      tx.set(docRef, {
        'nome': nomeLimpo,
        'senha': senha,
        'especialidade': especialidade.trim(),
        'status': StatusFila.aguardando.value,
        'horaChegada': Timestamp.fromDate(hora),
        'userId': userId,
      });

      return PacienteNaFila(
        id: docRef.id,
        nome: nomeLimpo,
        senha: senha,
        especialidade: especialidade.trim(),
        status: StatusFila.aguardando,
        horaChegada: hora,
        userId: userId,
      );
    });
  }

  /// Remove espaços nas pontas, colapsa espaços internos e limita o tamanho.
  static String _sanitizarNome(String nome) {
    final limpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpo.isEmpty) return 'Cidadão';
    return limpo.length > 80 ? limpo.substring(0, 80) : limpo;
  }

  /// O cidadão sai da fila (remove o documento).
  /// Só remove se o status ainda for aguardando ou em_atendimento —
  /// evita remover acidentalmente um registro já finalizado/ausente.
  Future<void> sairDaFila(String pacienteId) async {
    assert(pacienteId.trim().isNotEmpty, 'pacienteId não pode ser vazio.');
    final ref = _pacientesRef.doc(pacienteId);
    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return; // Já removido — nada a fazer.
      final status = (snap.data()?['status'] as String?) ?? '';
      final statusAtivo = [
        StatusFila.aguardando.value,
        StatusFila.emAtendimento.value,
      ];
      if (!statusAtivo.contains(status)) return; // Não mexe em finalizados.
      tx.delete(ref);
    });
  }

  // ── Ações do posto ────────────────────────────────────────

  /// Atualiza o status de um paciente.
  Future<void> atualizarStatus(
      String pacienteId, StatusFila novoStatus) async {
    assert(pacienteId.trim().isNotEmpty, 'pacienteId não pode ser vazio.');
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
  /// - Toda a operação roda dentro de uma transação Firestore — dois atendentes
  ///   clicando "Chamar Próximo" simultaneamente não chamam o mesmo paciente.
  /// - Retorna o paciente recém-chamado, ou null se a fila estava vazia.
  /// - Lança [ConflitoChamadaException] se detectar concorrência.
  Future<PacienteNaFila?> chamarProximo() async {
    return _db.runTransaction<PacienteNaFila?>((tx) async {
      // 1. Próximo aguardando (mais antigo) — leitura fora da tx para query.
      final aguardandoQuery = await _pacientesRef
          .where('status', isEqualTo: StatusFila.aguardando.value)
          .orderBy('horaChegada')
          .limit(1)
          .get();

      if (aguardandoQuery.docs.isEmpty) return null;

      // 2. Paciente atualmente em atendimento (se houver).
      final emAtendimentoQuery = await _pacientesRef
          .where('status', isEqualTo: StatusFila.emAtendimento.value)
          .limit(1)
          .get();

      final proximoRef = aguardandoQuery.docs.first.reference;
      final atualRef = emAtendimentoQuery.docs.isEmpty
          ? null
          : emAtendimentoQuery.docs.first.reference;

      // 3. Releitura via tx.get() — garante consistência transacional.
      final proximoSnap = await tx.get(proximoRef);
      if (!proximoSnap.exists) {
        // Paciente removido entre a query e a transação — sem próximo seguro.
        return null;
      }

      // 4. Guarda de concorrência: outro atendente pode ter chamado este
      //    paciente entre o get() acima e este tx.get().
      final statusAtual =
          (proximoSnap.data()?['status'] as String?) ?? 'aguardando';
      if (statusAtual != StatusFila.aguardando.value) {
        throw const ConflitoChamadaException();
      }

      // 5. Finaliza atendimento anterior, se houver.
      if (atualRef != null) {
        tx.update(atualRef, {
          'status': StatusFila.atendido.value,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      // 6. Promove o próximo.
      tx.update(proximoRef, {
        'status': StatusFila.emAtendimento.value,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      // 7. Reconstrói o paciente já com o status novo.
      final data = Map<String, dynamic>.from(proximoSnap.data() ?? {});
      return PacienteNaFila(
        id: proximoSnap.id,
        nome: (data['nome'] as String?) ?? 'Sem nome',
        senha: (data['senha'] as String?) ?? '---',
        especialidade: (data['especialidade'] as String?) ?? 'Clínica Geral',
        status: StatusFila.emAtendimento,
        horaChegada:
            (data['horaChegada'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userId: data['userId'] as String?,
        sus: data['sus'] as String?,
        cpf: data['cpf'] as String?,
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