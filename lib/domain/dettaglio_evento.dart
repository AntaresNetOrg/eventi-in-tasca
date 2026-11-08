import 'evento.dart';

/// Fields shown both in the event list and in the event page.
enum CampoCondiviso {
  titolo,
  regione,
  partenza,
  rientro,
  quota,
  localita,
  iscritti,
  iscrittiMax,
}

/// What the event page adds to the list ("Estrai dettagli", D-11).
///
/// The fields shared with the list are kept only to compare them: the list
/// values win (D-11). [letti] tells which of them were read without errors,
/// because null is a valid value for some of them (no fee, no limit...).
class DettaglioEvento {
  const DettaglioEvento({
    this.titolo,
    this.regione,
    this.partenza,
    this.rientro,
    this.quotaCentesimi,
    this.localita,
    this.iscritti,
    this.iscrittiMax,
    this.letti = const {},
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

  // Shared with the list.
  final String? titolo;
  final String? regione;
  final DateTime? partenza;
  final DateTime? rientro;
  final int? quotaCentesimi;
  final String? localita;
  final int? iscritti;
  final int? iscrittiMax;
  final Set<CampoCondiviso> letti;

  // Only in the event page.
  final String? sottotitolo;
  final List<String> capiCampo;
  final DateTime? aperturaIscrizioni;
  final DateTime? chiusuraIscrizioni;
  final Uri? linkPresentazione;
  final List<Appuntamento> appuntamenti;
  final String? infoSegreteria;
  final String? contattoMetodologico;
  final String? contattoAmministrativo;

  final List<String> anomalie;
}
