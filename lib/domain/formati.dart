import 'evento.dart';

/// Italian texts for the values of an event, shared by screens and exports.

String _two(int value) => value.toString().padLeft(2, '0');

/// `gg/mm/aaaa`, or a dash when the date is missing or out of format.
String formatData(DateTime? data) =>
    data == null ? '—' : '${_two(data.day)}/${_two(data.month)}/${data.year}';

/// `gg/mm/aaaa hh:mm`.
String formatDataOra(DateTime data) =>
    '${formatData(data)} ${_two(data.hour)}:${_two(data.minute)}';

/// `05/12/2026 – 08/12/2026`, or a single date when they coincide.
String formatPeriodo(DateTime? dal, DateTime? al) {
  if (dal != null && dal == al) return formatData(dal);
  return '${formatData(dal)} – ${formatData(al)}';
}

/// `21,00 €`; null means that the site shows no fee.
String formatQuota(int? centesimi) {
  if (centesimi == null) return 'nessuna quota';
  return '${centesimi ~/ 100},${_two(centesimi % 100)} €';
}

String formatLocalita(String? localita) => localita ?? 'da definire';

/// `29 su 28 posti`, `12 (senza limite)`.
String formatIscritti(int? iscritti, int? massimo) {
  final quanti = iscritti?.toString() ?? '—';
  if (massimo == null) return '$quanti (senza limite)';
  return '$quanti su $massimo posti';
}

/// Labels of D-09.
String etichettaStato(StatoIscrizioni? stato) => switch (stato) {
  StatoIscrizioni.aperte => 'Aperte',
  StatoIscrizioni.inEsaurimento => 'In esaurimento',
  StatoIscrizioni.listaAttesa => "Lista d'attesa",
  StatoIscrizioni.chiuse => 'Chiuse',
  null => 'Stato non disponibile',
};

/// Rough duration of "Estrai dettagli" for [pagine] event pages.
///
/// About 0.3-0.5 s per page with the limits of D-04 (an estimate still to be
/// measured on the real site).
String stimaDurata(int pagine) {
  final minimo = (pagine * 0.3 / 60).ceil();
  final massimo = (pagine * 0.5 / 60).ceil();
  if (massimo <= 1) return 'meno di un minuto';
  if (minimo == massimo) return 'circa $massimo minuti';
  return 'circa $minimo-$massimo minuti';
}
