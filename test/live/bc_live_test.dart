// Tests against the real site (D-05, P-02). Skipped by default (see
// dart_test.yaml); run with:
//   flutter test --run-skipped --tags live
//
// They make 4 GET requests, through the same client and limits as the app.
@Tags(['live'])
library;

import 'package:eventi_bc/data/bc_client.dart';
import 'package:eventi_bc/data/estrazione.dart';
import 'package:eventi_bc/domain/evento.dart';
import 'package:eventi_bc/parsing/parse_event_detail.dart';
import 'package:eventi_bc/parsing/parse_event_list.dart';
import 'package:eventi_bc/parsing/parse_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final client = BcClient();
  tearDownAll(client.close);

  late List<Evento> eventi;

  test('the menus are read from the site', () async {
    final menu = parseMenu(await client.paginaElenco());

    expect(menu.regioni.map((r) => r.nome), contains('Nazionale'));
    expect(menu.regioni.length, greaterThanOrEqualTo(20));
    expect(menu.tipi.where((t) => t.gruppo), isNotEmpty);
    expect(menu.tipi.where((t) => !t.gruppo).length, greaterThan(50));
  });

  test('every event of the full list is read without anomalies', () async {
    final html = await client.paginaElenco(soloAperte: false);
    eventi = parseEventList(html);

    expect(eventi, isNotEmpty);
    // V-04: no paging was seen so far.
    expect(html, isNot(contains(r'Page$')));
    final anomalie = [
      for (final e in eventi)
        for (final a in e.anomalie) 'evento ${e.id}: $a',
    ];
    expect(anomalie, isEmpty, reason: anomalie.join('\n'));
  });

  test('two event pages are read without anomalies', () async {
    final campione = eventi.where((e) => e.id != null).take(2).toList();
    expect(campione, isNotEmpty);

    for (final evento in campione) {
      final dettaglio = parseEventDetail(await client.paginaEvento(evento.id!));
      expect(
        dettaglio.anomalie,
        isEmpty,
        reason: 'evento ${evento.id}: ${dettaglio.anomalie.join('; ')}',
      );
    }
  });

  test('the search without results is still recognized', () async {
    // Molise had no events on 06/11/2026; if it has some, the list is valid
    // anyway, so this only checks that the page is understood.
    // Same address as the fixture events_empty: Events.aspx?RID=N&All=1.
    final eventi = await Estrazione(client)
        .cercaEventi(cid: '', rid: 'N', soloAperte: false);

    expect(eventi, isA<List<Evento>>());
  });
}
