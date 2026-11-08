import 'dart:convert';
import 'dart:io';

import 'package:eventi_bc/data/annullamento.dart';
import 'package:eventi_bc/data/bc_client.dart';
import 'package:eventi_bc/data/bc_exceptions.dart';
import 'package:eventi_bc/data/estrazione.dart';
import 'package:eventi_bc/data/request_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.html').readAsStringSync();

http.Response _page(String name) =>
    http.Response.bytes(utf8.encode(_fixture(name)), 200);

/// A site with the Lazio list and only the page of event 26719: the other
/// events of the list redirect to the list, as missing events do.
Future<http.Response> _site(http.Request request) async {
  if (request.url.path == '/Events.aspx') return _page('events_lazio_po');
  if (request.url.queryParameters['e'] == '26719') return _page('event_26719');
  return http.Response('', 302, headers: {'location': '/Events.aspx'});
}

Estrazione _estrazione(MockClientHandler handler) => Estrazione(
  BcClient(
    client: MockClient(handler),
    scheduler: RequestScheduler(pausa: Duration.zero),
  ),
);

void main() {
  group('menus', () {
    test('come from the site when it can be read', () async {
      final caricato = await _estrazione(_site)
          .caricaMenu(riserva: () async => fail('fallback not expected'));

      expect(caricato.daRiserva, isFalse);
      expect(caricato.menu.regioni, hasLength(21));
    });

    test('come from the bundled fallback when the site is offline', () async {
      final caricato =
          await _estrazione(
            (request) async =>
                throw http.ClientException('offline', request.url),
          ).caricaMenu(
            riserva: () async =>
                File('assets/menu/menu.json').readAsStringSync(),
          );

      expect(caricato.daRiserva, isTrue);
      expect(caricato.menu.tipi, hasLength(85));
    });

    test('come from the fallback when the page is not recognized', () async {
      final caricato =
          await _estrazione((_) async => http.Response('<html></html>', 200))
              .caricaMenu(
                riserva: () async =>
                    File('assets/menu/menu.json').readAsStringSync(),
              );

      expect(caricato.daRiserva, isTrue);
    });
  });

  test('searches the events of the list', () async {
    final eventi = await _estrazione(_site)
        .cercaEventi(cid: '1010101', rid: 'H');

    expect(eventi, hasLength(9));
    expect(eventi.first.id, 26719);
  });

  group('details', () {
    test('complete the events and keep the order', () async {
      final estrazione = _estrazione(_site);
      final eventi = await estrazione.cercaEventi(cid: '1010101');
      final avanzamento = <(int, int)>[];

      final completi = await estrazione.estraiDettagli(
        eventi,
        avanzamento: (fatti, totale) => avanzamento.add((fatti, totale)),
      );

      expect(completi.map((e) => e.id), eventi.map((e) => e.id));
      expect(completi.first.capiCampo, ['CAPO UNO', 'CAPO DUE']);
      expect(completi.first.anomalie, isEmpty);
      expect(avanzamento.first, (0, 9));
      expect(avanzamento.last, (9, 9));
      expect(avanzamento, hasLength(10));
    });

    test('an event whose page is missing stays with an anomaly', () async {
      final estrazione = _estrazione(_site);
      final eventi = await estrazione.cercaEventi(cid: '1010101');

      final completi = await estrazione.estraiDettagli(eventi);

      expect(completi, hasLength(9));
      expect(completi[1].capiCampo, isEmpty);
      expect(completi[1].anomalie.single, contains('non esiste più'));
    });

    test('a network error on one page does not stop the others', () async {
      final estrazione = _estrazione((request) async {
        if (request.url.queryParameters['e'] == '26721') {
          return http.Response('', 503);
        }
        return _site(request);
      });
      final eventi = await estrazione.cercaEventi(cid: '1010101');

      final completi = await estrazione.estraiDettagli(eventi);

      expect(completi.first.capiCampo, isNotEmpty);
      expect(completi[1].anomalie.single, contains('503'));
    });

    test('an unrecognized page is an anomaly of its event', () async {
      final estrazione = _estrazione((request) async {
        if (request.url.path == '/Event.aspx') {
          return http.Response('<html><body>Manutenzione</body></html>', 200);
        }
        return _site(request);
      });
      final eventi = await estrazione.cercaEventi(cid: '1010101');

      final completi = await estrazione.estraiDettagli(eventi.take(1).toList());

      expect(completi.single.anomalie.single, contains('non riconosciuta'));
    });

    test('cancellation stops the extraction', () async {
      final annullamento = Annullamento();
      var avviate = 0;
      var interrotte = 0;
      // The streaming mock receives the original request, with its abort
      // trigger: event pages wait until they are aborted.
      final estrazione = Estrazione(
        BcClient(
          client: MockClient.streaming((request, _) async {
            avviate++;
            await (request as http.Abortable).abortTrigger;
            interrotte++;
            throw http.RequestAbortedException(request.url);
          }),
          scheduler: RequestScheduler(pausa: Duration.zero),
        ),
      );
      final eventi = await _estrazione(_site).cercaEventi(cid: '1010101');

      final risultato = estrazione.estraiDettagli(
        eventi,
        annullamento: annullamento,
      );
      await pumpEventQueue();
      annullamento.annulla();

      await expectLater(
        risultato,
        throwsA(isA<EstrazioneAnnullataException>()),
      );
      await pumpEventQueue();
      // Two pages were running and were aborted; the other seven never left.
      expect(avviate, 2);
      expect(interrotte, 2);
    });
  });
}
