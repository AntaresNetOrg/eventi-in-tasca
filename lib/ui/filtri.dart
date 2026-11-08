import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choices of the search screen (D-08, §4).
class Filtri {
  const Filtri({
    this.cid,
    this.rid,
    this.soloAperte = true,
    this.dettagli = false,
    this.pdf = true,
    this.excel = false,
  });

  /// Event type; required to search.
  final String? cid;

  /// Region; null means all regions.
  final String? rid;
  final bool soloAperte;
  final bool dettagli;
  final bool pdf;
  final bool excel;

  Filtri copyWith({
    String? cid,
    String? Function()? rid,
    bool? soloAperte,
    bool? dettagli,
    bool? pdf,
    bool? excel,
  }) => Filtri(
    cid: cid ?? this.cid,
    rid: rid == null ? this.rid : rid(),
    soloAperte: soloAperte ?? this.soloAperte,
    dettagli: dettagli ?? this.dettagli,
    pdf: pdf ?? this.pdf,
    excel: excel ?? this.excel,
  );
}

class FiltriNotifier extends Notifier<Filtri> {
  @override
  Filtri build() => const Filtri();

  void tipo(String cid) => state = state.copyWith(cid: cid);

  void regione(String? rid) => state = state.copyWith(rid: () => rid);

  void soloAperte(bool value) => state = state.copyWith(soloAperte: value);

  void dettagli(bool value) => state = state.copyWith(dettagli: value);

  /// At least one format stays selected.
  void pdf(bool value) {
    if (!value && !state.excel) return;
    state = state.copyWith(pdf: value);
  }

  void excel(bool value) {
    if (!value && !state.pdf) return;
    state = state.copyWith(excel: value);
  }
}

final filtriProvider = NotifierProvider<FiltriNotifier, Filtri>(
  FiltriNotifier.new,
);
