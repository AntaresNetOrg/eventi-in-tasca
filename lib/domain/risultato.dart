import 'evento.dart';

/// What was searched, for the results header and the exported files.
class Ricerca {
  const Ricerca({
    required this.tipo,
    required this.regione,
    required this.soloAperte,
    required this.dettagli,
    this.pdf = true,
    this.excel = false,
  });

  final String tipo;

  /// Null when searching all regions.
  final String? regione;
  final bool soloAperte;
  final bool dettagli;

  /// Formats to share, chosen before the search.
  final bool pdf;
  final bool excel;

  Ricerca copyWith({bool? dettagli}) => Ricerca(
    tipo: tipo,
    regione: regione,
    soloAperte: soloAperte,
    dettagli: dettagli ?? this.dettagli,
    pdf: pdf,
    excel: excel,
  );
}

class Risultato {
  const Risultato({
    required this.ricerca,
    required this.eventi,
    required this.estrattoIl,
  });

  final Ricerca ricerca;

  /// Sorted by departure date, then title (P-07).
  final List<Evento> eventi;
  final DateTime estrattoIl;

  int get eventiConAnomalie =>
      eventi.where((e) => e.anomalie.isNotEmpty).length;
}
