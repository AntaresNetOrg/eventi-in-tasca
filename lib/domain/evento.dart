/// Enrollment state shown by the site's traffic light (D-09).
enum StatoIscrizioni { aperte, inEsaurimento, listaAttesa, chiuse }

/// Branch from the `branch_xx.png` icon. [aa] covers meetings and assemblies.
enum Branca { lc, eg, rs, fc, aa }

/// One date range of an event held in several sessions (V-14).
class Appuntamento {
  const Appuntamento({this.dal, this.al, this.localita});

  final DateTime? dal;
  final DateTime? al;
  final String? localita;
}

/// An event from BuonaCaccia (Progettazione §3).
///
/// A value that does not match the expected format is null, and [anomalie]
/// holds a message with the raw text: events are never discarded (D-05). This
/// is why fields that the site always provides are nullable too.
class Evento {
  const Evento({
    this.id,
    this.url,
    required this.sigla,
    this.branca,
    required this.titolo,
    required this.regione,
    this.partenza,
    this.rientro,
    this.quotaCentesimi,
    this.localita,
    this.iscritti,
    this.iscrittiMax,
    this.stato,
    this.piuAppuntamenti = false,
    this.postiFuoriRegione,
    this.postiMoz45,
    this.sottotitolo,
    this.capiCampo = const [],
    this.aperturaIscrizioni,
    this.chiusuraIscrizioni,
    this.linkPresentazione,
    this.appuntamenti = const [],
    this.infoSegreteria,
    this.contattoMetodologico,
    this.contattoAmministrativo,
    this.anomalie = const [],
  });

  // From the event list.
  final int? id;
  final Uri? url;
  final String sigla;
  final Branca? branca;
  final String titolo;
  final String regione;
  final DateTime? partenza;
  final DateTime? rientro;

  /// Fee in euro cents; null when the event has no fee (`-`).
  final int? quotaCentesimi;

  /// Null when the site says `(da definire)`.
  final String? localita;
  final int? iscritti;

  /// Null when there is no limit (`(*)`).
  final int? iscrittiMax;
  final StatoIscrizioni? stato;
  final bool piuAppuntamenti;
  final int? postiFuoriRegione;
  final int? postiMoz45;

  // From the event page ("Estrai dettagli").
  final String? sottotitolo;
  final List<String> capiCampo;
  final DateTime? aperturaIscrizioni;
  final DateTime? chiusuraIscrizioni;
  final Uri? linkPresentazione;
  final List<Appuntamento> appuntamenti;
  final String? infoSegreteria;
  final String? contattoMetodologico;
  final String? contattoAmministrativo;

  /// User-visible messages, in Italian, about values out of format.
  final List<String> anomalie;
}
