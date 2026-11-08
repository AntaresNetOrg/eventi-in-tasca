import 'dettaglio_evento.dart';
import 'evento.dart';

/// [evento] from the list, completed with its event page.
///
/// The list values are kept; when the page shows a different value, an anomaly
/// reports both, because the event may have changed between the two readings
/// (D-11).
Evento conDettaglio(Evento evento, DettaglioEvento dettaglio) {
  final differenze = <String>[];

  void compare<T>(CampoCondiviso campo, T elenco, T pagina, String label) {
    if (!dettaglio.letti.contains(campo) || elenco == pagina) return;
    differenze.add(
      '$label diversa tra elenco e pagina dell\'evento: '
      '${_show(elenco)} nell\'elenco, ${_show(pagina)} nella pagina',
    );
  }

  compare(CampoCondiviso.titolo, evento.titolo, dettaglio.titolo, 'Titolo');
  compare(CampoCondiviso.regione, evento.regione, dettaglio.regione, 'Regione');
  compare(
    CampoCondiviso.partenza,
    evento.partenza,
    dettaglio.partenza,
    'Data di partenza',
  );
  compare(
    CampoCondiviso.rientro,
    evento.rientro,
    dettaglio.rientro,
    'Data di rientro',
  );
  compare(
    CampoCondiviso.quota,
    _Quota(evento.quotaCentesimi),
    _Quota(dettaglio.quotaCentesimi),
    'Quota',
  );
  compare(
    CampoCondiviso.localita,
    _Localita(evento.localita),
    _Localita(dettaglio.localita),
    'Località',
  );
  compare(
    CampoCondiviso.iscritti,
    evento.iscritti,
    dettaglio.iscritti,
    'Numero di iscritti',
  );
  compare(
    CampoCondiviso.iscrittiMax,
    _Massimo(evento.iscrittiMax),
    _Massimo(dettaglio.iscrittiMax),
    'Numero massimo di iscritti',
  );

  return Evento(
    id: evento.id,
    url: evento.url,
    sigla: evento.sigla,
    branca: evento.branca,
    titolo: evento.titolo,
    regione: evento.regione,
    partenza: evento.partenza,
    rientro: evento.rientro,
    quotaCentesimi: evento.quotaCentesimi,
    localita: evento.localita,
    iscritti: evento.iscritti,
    iscrittiMax: evento.iscrittiMax,
    stato: evento.stato,
    piuAppuntamenti: evento.piuAppuntamenti,
    postiFuoriRegione: evento.postiFuoriRegione,
    postiMoz45: evento.postiMoz45,
    sottotitolo: dettaglio.sottotitolo,
    capiCampo: dettaglio.capiCampo,
    aperturaIscrizioni: dettaglio.aperturaIscrizioni,
    chiusuraIscrizioni: dettaglio.chiusuraIscrizioni,
    linkPresentazione: dettaglio.linkPresentazione,
    appuntamenti: dettaglio.appuntamenti,
    infoSegreteria: dettaglio.infoSegreteria,
    contattoMetodologico: dettaglio.contattoMetodologico,
    contattoAmministrativo: dettaglio.contattoAmministrativo,
    anomalie: List.unmodifiable([
      ...evento.anomalie,
      ...dettaglio.anomalie,
      ...differenze,
    ]),
  );
}

String _show(Object? value) => switch (value) {
  null => 'non indicato',
  DateTime(:final day, :final month, :final year) =>
    '${_two(day)}/${_two(month)}/$year',
  String() => '"$value"',
  _ => '$value',
};

String _two(int value) => value.toString().padLeft(2, '0');

/// Wrappers that compare like the wrapped value and print it for the user.
final class _Quota {
  const _Quota(this.centesimi);

  final int? centesimi;

  @override
  bool operator ==(Object other) =>
      other is _Quota && other.centesimi == centesimi;

  @override
  int get hashCode => centesimi.hashCode;

  @override
  String toString() {
    final cents = centesimi;
    if (cents == null) return 'nessuna quota';
    return '${cents ~/ 100},${_two(cents % 100)} €';
  }
}

final class _Localita {
  const _Localita(this.nome);

  final String? nome;

  @override
  bool operator ==(Object other) => other is _Localita && other.nome == nome;

  @override
  int get hashCode => nome.hashCode;

  @override
  String toString() => nome == null ? 'da definire' : '"$nome"';
}

final class _Massimo {
  const _Massimo(this.posti);

  final int? posti;

  @override
  bool operator ==(Object other) => other is _Massimo && other.posti == posti;

  @override
  int get hashCode => posti.hashCode;

  @override
  String toString() => posti == null ? 'senza limite' : '$posti';
}
