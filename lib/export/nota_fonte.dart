import '../domain/formati.dart';

/// The note required in every exported file (D-00).
String notaFonte(DateTime estrattoIl) {
  final quando = formatDataOra(estrattoIl).split(' ');
  return 'Fonte: BuonaCaccia (buonacaccia.agesci.it) — dati estratti il '
      '${quando[0]} alle ${quando[1]}. Per iscriversi e per i dati aggiornati '
      'usare BuonaCaccia. Elenco prodotto con Eventi in tasca, app non '
      'ufficiale.';
}
