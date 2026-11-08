import 'dart:convert';

import '../domain/con_dettaglio.dart';
import '../domain/evento.dart';
import '../domain/menu_eventi.dart';
import '../parsing/bc_page_format_exception.dart';
import '../parsing/parse_event_detail.dart';
import '../parsing/parse_event_list.dart';
import '../parsing/parse_menu.dart';
import 'annullamento.dart';
import 'bc_client.dart';
import 'bc_exceptions.dart';

/// Search menus and where they come from.
typedef MenuCaricato = ({MenuEventi menu, bool daRiserva});

/// Reads menus, event lists and event pages from the site.
class Estrazione {
  Estrazione(this.client);

  final BcClient client;

  /// The menus of the site or, if the site cannot be read, the bundled
  /// fallback [riserva] (D-03), which may be out of date.
  Future<MenuCaricato> caricaMenu({
    required Future<String> Function() riserva,
  }) async {
    try {
      return (menu: parseMenu(await client.paginaElenco()), daRiserva: false);
    } on BcNetworkException {
      // Fall back below.
    } on BcPageFormatException {
      // Fall back below.
    }
    final json = jsonDecode(await riserva()) as Map<String, dynamic>;
    return (menu: MenuEventi.fromJson(json), daRiserva: true);
  }

  /// The events of a type and, optionally, of a region, in the site's order.
  ///
  /// Throws [BcNetworkException] or [BcPageFormatException] if the list cannot
  /// be read.
  Future<List<Evento>> cercaEventi({
    required String cid,
    String? rid,
    bool soloAperte = true,
    Annullamento? annullamento,
  }) async {
    final html = await client.paginaElenco(
      rid: rid,
      cid: cid,
      soloAperte: soloAperte,
      annullamento: annullamento,
    );
    return parseEventList(html);
  }

  /// [eventi] completed with their event pages ("Estrai dettagli").
  ///
  /// An event whose page cannot be read stays in the list with an anomaly
  /// (D-04). [avanzamento] receives the pages done so far and the total.
  /// Throws [EstrazioneAnnullataException] if [annullamento] is triggered.
  Future<List<Evento>> estraiDettagli(
    List<Evento> eventi, {
    void Function(int fatti, int totale)? avanzamento,
    Annullamento? annullamento,
  }) async {
    var fatti = 0;
    avanzamento?.call(0, eventi.length);

    Future<Evento> completa(Evento evento) async {
      try {
        return await _conPagina(evento, annullamento);
      } finally {
        if (!(annullamento?.richiesto ?? false)) {
          avanzamento?.call(++fatti, eventi.length);
        }
      }
    }

    final risultati = await Future.wait(eventi.map(completa), eagerError: true);
    annullamento?.verifica();
    return risultati;
  }

  Future<Evento> _conPagina(Evento evento, Annullamento? annullamento) async {
    final id = evento.id;
    if (id == null) {
      return evento.conAnomalie([
        'Dettagli non disponibili: manca il collegamento alla pagina '
            'dell\'evento',
      ]);
    }
    try {
      final html = await client.paginaEvento(id, annullamento: annullamento);
      return conDettaglio(evento, parseEventDetail(html));
    } on EventoNonDisponibileException {
      return evento.conAnomalie([
        'Dettagli non disponibili: la pagina dell\'evento non esiste più su '
            'BuonaCaccia',
      ]);
    } on BcNetworkException catch (e) {
      return evento.conAnomalie(['Dettagli non scaricati: ${e.message}']);
    } on BcPageFormatException {
      return evento.conAnomalie([
        'Dettagli non disponibili: pagina dell\'evento non riconosciuta',
      ]);
    }
  }
}
