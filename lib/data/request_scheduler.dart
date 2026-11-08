import 'dart:async';
import 'dart:collection';

import 'annullamento.dart';
import 'bc_exceptions.dart';

/// Limits the requests to the site (D-04, P-01).
///
/// At most [maxParallel] requests run at the same time, and each slot waits
/// [pausa] after a request before starting the next one. The values are not
/// configurable from the user interface: the parameters exist for the tests.
class RequestScheduler {
  RequestScheduler({
    this.maxParallel = 2,
    this.pausa = const Duration(milliseconds: 300),
  }) : assert(maxParallel > 0);

  final int maxParallel;
  final Duration pausa;

  final _coda = Queue<_Job<Object?>>();
  int _attivi = 0;

  /// Runs [richiesta] when a slot is free.
  ///
  /// If [annullamento] is triggered while waiting, the request never starts
  /// and the future fails with [EstrazioneAnnullataException].
  Future<T> esegui<T>(
    Future<T> Function() richiesta, {
    Annullamento? annullamento,
  }) {
    annullamento?.verifica();
    final job = _Job<T>(richiesta);
    _coda.add(job);
    if (annullamento != null) {
      unawaited(
        annullamento.segnale.then((_) {
          if (_coda.remove(job)) job.annulla();
        }),
      );
    }
    _avvia();
    return job.completer.future;
  }

  void _avvia() {
    while (_attivi < maxParallel && _coda.isNotEmpty) {
      final job = _coda.removeFirst();
      _attivi++;
      unawaited(_esegui(job));
    }
  }

  Future<void> _esegui(_Job<Object?> job) async {
    try {
      await job.esegui();
    } finally {
      await Future<void>.delayed(pausa);
      _attivi--;
      _avvia();
    }
  }
}

class _Job<T> {
  _Job(this.richiesta);

  final Future<T> Function() richiesta;
  final completer = Completer<T>();

  Future<void> esegui() async {
    try {
      completer.complete(await richiesta());
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  }

  void annulla() =>
      completer.completeError(const EstrazioneAnnullataException());
}
