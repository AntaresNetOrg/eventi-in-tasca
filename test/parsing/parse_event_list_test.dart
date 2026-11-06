import 'dart:io';

import 'package:eventi_bc/domain/evento.dart';
import 'package:eventi_bc/parsing/bc_page_format_exception.dart';
import 'package:eventi_bc/parsing/parse_event_list.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.html').readAsStringSync();

void main() {
  group('filtered list', () {
    final html = _fixture('events_lazio_po');
    final eventi = parseEventList(html);

    test('reads every row, without the header', () {
      expect(eventi, hasLength(9));
    });

    test('reads all the fields of a row', () {
      final evento = eventi.first;

      expect(evento.id, 26719);
      expect(
        evento.url,
        Uri.parse('https://buonacaccia.agesci.it/Event.aspx?e=26719'),
      );
      expect(evento.sigla, 'PO');
      expect(evento.branca, Branca.lc);
      expect(evento.titolo, 'Piccole Orme - Dicembre 1 - Quadriennale');
      expect(evento.regione, 'Lazio');
      expect(evento.partenza, DateTime(2026, 12, 5));
      expect(evento.rientro, DateTime(2026, 12, 8));
      expect(evento.quotaCentesimi, 2100);
      expect(evento.localita, 'Orvinio (RI)');
      expect(evento.iscritti, 29);
      expect(evento.iscrittiMax, 28);
      expect(evento.stato, StatoIscrizioni.inEsaurimento);
      expect(evento.piuAppuntamenti, isFalse);
      expect(evento.postiFuoriRegione, isNull);
      expect(evento.postiMoz45, isNull);
      expect(evento.anomalie, isEmpty);
    });

    test('leaves the detail fields empty', () {
      final evento = eventi.first;

      expect(evento.sottotitolo, isNull);
      expect(evento.capiCampo, isEmpty);
      expect(evento.appuntamenti, isEmpty);
    });
  });

  group('full list', () {
    final eventi = parseEventList(_fixture('events_all_1'));
    final byId = {for (final e in eventi) e.id: e};

    int count(bool Function(Evento) test) => eventi.where(test).length;

    test('reads every row without anomalies', () {
      expect(eventi, hasLength(298));
      expect(eventi.expand((e) => e.anomalie), isEmpty);
    });

    test('maps every traffic light', () {
      expect(count((e) => e.stato == StatoIscrizioni.aperte), 110);
      expect(count((e) => e.stato == StatoIscrizioni.inEsaurimento), 20);
      expect(count((e) => e.stato == StatoIscrizioni.listaAttesa), 34);
      expect(count((e) => e.stato == StatoIscrizioni.chiuse), 134);
    });

    test('maps every branch', () {
      expect(count((e) => e.branca == Branca.lc), 15);
      expect(count((e) => e.branca == Branca.eg), 20);
      expect(count((e) => e.branca == Branca.rs), 27);
      expect(count((e) => e.branca == Branca.fc), 190);
      expect(count((e) => e.branca == Branca.aa), 46);
    });

    test('an event without fee has a null fee and no anomaly', () {
      expect(count((e) => e.quotaCentesimi == null), 115);
    });

    test('an event without limit has a null maximum and no anomaly', () {
      expect(count((e) => e.iscrittiMax == null), 59);
    });

    test('a location to be defined is null', () {
      expect(byId[26872]!.localita, isNull);
      expect(byId[26575]!.localita, 'Savona (SV)');
    });

    test('expands the abbreviated regions', () {
      expect(count((e) => e.regione == 'Emilia Romagna'), 15);
      expect(count((e) => e.regione == 'Friuli Venezia Giulia'), 2);
      expect(count((e) => e.regione == 'Trentino Alto Adige'), 2);
      expect(eventi.map((e) => e.regione), isNot(contains('EmiRo')));
    });

    test('tells acronym and region apart, despite the shared id', () {
      expect(byId[26575]!.sigla, 'CFM L/C');
      expect(byId[26575]!.regione, 'Liguria');
    });

    test('accepts an empty acronym', () {
      expect(byId[26479]!.sigla, isEmpty);
      expect(byId[26479]!.branca, Branca.aa);
    });

    test('the title does not include the subtitle', () {
      expect(byId[26870]!.titolo, 'Piccole Orme - Lancia i dadi! - Dicembre');
    });

    test('reads the informative icons', () {
      expect(byId[26575]!.piuAppuntamenti, isTrue);
      expect(byId[26719]!.piuAppuntamenti, isFalse);
      expect(eventi.map((e) => e.postiFuoriRegione), contains(-2));
      expect(count((e) => e.postiFuoriRegione != null), greaterThan(0));
      expect(count((e) => e.postiMoz45 != null), greaterThan(0));
    });
  });

  group('search without results', () {
    test('is an empty list, not an error', () {
      expect(parseEventList(_fixture('events_empty')), isEmpty);
    });
  });

  group('values out of format keep the event', () {
    final html = _fixture('events_lazio_po');

    Evento firstOf(String modified) => parseEventList(modified).first;

    test('fee', () {
      final evento = firstOf(html.replaceFirst('21,00 €', 'gratis'));

      expect(evento.quotaCentesimi, isNull);
      expect(evento.anomalie.single, contains('gratis'));
    });

    test('impossible date', () {
      final evento = firstOf(html.replaceFirst('05/12/2026', '31/02/2026'));

      expect(evento.partenza, isNull);
      expect(evento.anomalie.single, contains('31/02/2026'));
    });

    test('date in another format', () {
      final evento = firstOf(html.replaceFirst('08/12/2026', '2026-12-08'));

      expect(evento.rientro, isNull);
      expect(evento.anomalie.single, contains('2026-12-08'));
    });

    test('unknown region keeps the raw text', () {
      final evento = firstOf(html.replaceFirst('>Lazio</span>', '>LzX</span>'));

      expect(evento.regione, 'LzX');
      expect(evento.anomalie.single, contains('LzX'));
    });

    test('unknown traffic light', () {
      final evento = firstOf(html.replaceFirst('light_yellow', 'light_blue'));

      expect(evento.stato, isNull);
      expect(evento.anomalie.single, contains('light_blue'));
    });

    test('unknown branch', () {
      final evento = firstOf(html.replaceFirst('branch_lc', 'branch_xx'));

      expect(evento.branca, isNull);
      expect(evento.anomalie.single, contains('branch_xx'));
    });

    test('number of participants', () {
      final evento = firstOf(
        html.replaceFirst('Taken_0">29<', 'Taken_0">n.d.<'),
      );

      expect(evento.iscritti, isNull);
      expect(evento.anomalie.single, contains('n.d.'));
    });

    test('maximum number of participants', () {
      final evento = firstOf(
        html.replaceFirst('SeatsMax_0">28<', 'SeatsMax_0">molti<'),
      );

      expect(evento.iscrittiMax, isNull);
      expect(evento.anomalie.single, contains('molti'));
    });

    test('link to the event', () {
      final evento = firstOf(
        html.replaceFirst('Event.aspx?e=26719', 'Altro.aspx'),
      );

      expect(evento.id, isNull);
      expect(evento.url, isNull);
      expect(evento.titolo, 'Piccole Orme - Dicembre 1 - Quadriennale');
      expect(evento.anomalie, hasLength(1));
    });

    test('unknown informative icon', () {
      final evento = firstOf(
        html.replaceFirst(
          '<td class="text-nowrap"> </td>',
          '<td class="text-nowrap"><img title="Novità: 3" src="x.png" /></td>',
        ),
      );

      expect(evento.anomalie.single, contains('Novità: 3'));
    });

    test('the other rows are not affected', () {
      final eventi = parseEventList(html.replaceFirst('21,00 €', 'gratis'));

      expect(eventi, hasLength(9));
      expect(eventi[1].anomalie, isEmpty);
      expect(eventi[1].quotaCentesimi, 2100);
    });
  });

  group('page structure', () {
    test('falls back on column names when the ids change', () {
      final original = parseEventList(_fixture('events_all_1'));
      final renamed = parseEventList(
        _fixture('events_all_1').replaceAll('MainContent_EventsGridView', 'x'),
      );

      expect(renamed, hasLength(original.length));
      expect(renamed.expand((e) => e.anomalie), isEmpty);
      for (var i = 0; i < original.length; i++) {
        expect(renamed[i].id, original[i].id);
        expect(renamed[i].sigla, original[i].sigla);
        expect(renamed[i].quotaCentesimi, original[i].quotaCentesimi);
        expect(renamed[i].localita, original[i].localita);
        expect(renamed[i].iscritti, original[i].iscritti);
        expect(renamed[i].iscrittiMax, original[i].iscrittiMax);
      }
    });

    test('fails on a page without the grid', () {
      expect(
        () => parseEventList('<html><body><p>Manutenzione</p></body></html>'),
        throwsA(isA<BcPageFormatException>()),
      );
    });

    test('fails when a column is missing', () {
      final html = _fixture('events_lazio_po').replaceFirst(
        '<th scope="col">Quota</th>',
        '<th scope="col">Costo</th>',
      );

      expect(() => parseEventList(html), throwsA(isA<BcPageFormatException>()));
    });
  });
}
