import 'dart:async';

import 'bc_exceptions.dart';

/// Cancellation signal shared by the requests of one extraction.
///
/// Queued requests are dropped and the running ones are aborted.
class Annullamento {
  final _segnale = Completer<void>();

  bool get richiesto => _segnale.isCompleted;

  /// Completes when [annulla] is called.
  Future<void> get segnale => _segnale.future;

  void annulla() {
    if (!_segnale.isCompleted) _segnale.complete();
  }

  /// Throws [EstrazioneAnnullataException] if cancellation was requested.
  void verifica() {
    if (richiesto) throw const EstrazioneAnnullataException();
  }
}
