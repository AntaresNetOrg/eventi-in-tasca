import 'dart:io';

import 'package:eventi_bc/domain/con_dettaglio.dart';
import 'package:eventi_bc/domain/dettaglio_evento.dart';
import 'package:eventi_bc/parsing/bc_page_format_exception.dart';
import 'package:eventi_bc/parsing/parse_event_detail.dart';
import 'package:eventi_bc/parsing/parse_event_list.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.html').readAsStringSync();

const _detailIds = [
  26719,
  26870,
  26533,
  26575,
  26698,
  26886,
  26678,
  26770,
  26748,
];

DettaglioEvento _detail(int id) => parseEventDetail(_fixture('event_$id'));

void main() {
  group('event pages', () {
    test('every fixture is read without anomalies', () {
      for (final id in _detailIds) {
        expect(_detail(id).anomalie, isEmpty, reason: 'event $id');
      }
    });

    test('basic page', () {
      final d = _detail(26719);

      expect(d.titolo, 'Piccole Orme - Dicembre 1 - Quadriennale');
      expect(d.regione, 'Lazio');
      expect(d.partenza, DateTime(2026, 12, 5));
      expect(d.rientro, DateTime(2026, 12, 8));
      expect(d.quotaCentesimi, 2100);
      expect(d.localita, 'Orvinio (RI)');
      expect(d.iscritti, 29);
      expect(d.iscrittiMax, 28);
      expect(d.letti, CampoCondiviso.values.toSet());
      expect(d.sottotitolo, isNull);
      expect(d.capiCampo, ['CAPO UNO', 'CAPO DUE']);
      expect(d.aperturaIscrizioni, isNotNull);
      expect(d.chiusuraIscrizioni, isNotNull);
      expect(d.linkPresentazione, isNull);
      expect(d.infoSegreteria, isNull);
      expect(d.appuntamenti, isEmpty);
      expect(d.contattoMetodologico, 'piccoleorme@lazio.agesci.it');
      expect(d.contattoAmministrativo, 'eventi@lazio.agesci.it');
    });

    test('subtitle, missing contact and line break in a mailto link', () {
      final d = _detail(26870);

      expect(d.titolo, 'Piccole Orme - Lancia i dadi! - Dicembre');
      expect(d.sottotitolo, 'Che il gioco abbia inizio...Jumanji!');
      expect(d.aperturaIscrizioni, DateTime(2026, 11, 5));
      expect(d.chiusuraIscrizioni, DateTime(2026, 11, 23));
      expect(d.contattoMetodologico, isNull);
      expect(d.contattoAmministrativo, 'eventi@toscana.agesci.it');
    });

    test('presentation link and secretariat with empty lines', () {
      final d = _detail(26533);

      expect(d.titolo, 'CFA - Novembre B');
      expect(d.regione, 'Nazionale');
      expect(d.quotaCentesimi, 5150);
      expect(d.iscritti, 39);
      expect(d.iscrittiMax, 29);
      expect(d.aperturaIscrizioni, DateTime(2026, 7, 29));
      expect(d.chiusuraIscrizioni, DateTime(2026, 11, 6));
      expect(
        d.linkPresentazione,
        Uri.parse('https://foca.agesci.it/evento/cfa-novembre-b-roma-rm/'),
      );
      expect(d.infoSegreteria, 'Campo fisso');
    });

    test('sessions instead of a location', () {
      final d = _detail(26575);

      expect(d.localita, isNull);
      expect(d.letti, isNot(contains(CampoCondiviso.localita)));
      expect(d.appuntamenti, hasLength(3));
      expect(d.appuntamenti.first.dal, DateTime(2026, 12, 5));
      expect(d.appuntamenti.first.al, DateTime(2026, 12, 7));
      expect(d.appuntamenti.first.localita, 'Savona (SV)');
      expect(d.appuntamenti.last.dal, DateTime(2027, 2, 20));
      expect(d.appuntamenti.last.al, DateTime(2027, 2, 21));
    });

    test('a link in the secretariat keeps its address once', () {
      expect(
        _detail(26575).infoSegreteria,
        'Info: https://sites.google.com/agesciliguria.it/cfmlcmoduli/home\n'
        'Il campo inizierà il 5 dicembre. è necessario partecipare A TUTTI '
        'GLI INCONTRI in presenza e alle attività laboratoriali previste a '
        'distanza.\n'
        'Ti consigliamo di visitare il sito che trovi nel box qui sopra, '
        'contiene un sacco di info utili!',
      );
    });

    test('bold text and non-breaking spaces in the secretariat', () {
      expect(
        _detail(26698).infoSegreteria,
        'ORE 19 presso la Chiesa di San Paolo Apostoli via Sardegna 16 '
        'La Spezia',
      );
    });

    test('line breaks in the secretariat', () {
      expect(
        _detail(26886).infoSegreteria,
        'Quando: venerdì 13, ore 17:00 – domenica 15 novembre, ore 17:00\n'
        'Ritrovo: Base Scout di Piazzole, via Brione snc, Gussago (BS)\n'
        'Per tutti i capi\n'
        'Informazioni pratiche\n'
        'Presenza continuativa richiesta\n'
        'Da portare: sacco a pelo o lenzuola e coperta',
      );
    });

    test('no fee and no limit', () {
      final d = _detail(26770);

      expect(d.quotaCentesimi, isNull);
      expect(d.iscrittiMax, isNull);
      expect(
        d.letti,
        containsAll([CampoCondiviso.quota, CampoCondiviso.iscrittiMax]),
      );
    });

    test('location to be defined and three capi campo', () {
      final d = _detail(26748);

      expect(d.localita, isNull);
      expect(d.letti, contains(CampoCondiviso.localita));
      expect(d.capiCampo, ['CAPO UNO', 'CAPO DUE', 'CAPO TRE']);
    });

    test('a page that is not an event page is an error', () {
      expect(
        () => parseEventDetail(_fixture('events_lazio_po')),
        throwsA(isA<BcPageFormatException>()),
      );
    });
  });

  group('text labels as fallback', () {
    test('give the same values when the ids change', () {
      for (final id in _detailIds) {
        final html = _fixture('event_$id');
        final original = parseEventDetail(html);
        final renamed = parseEventDetail(
          html.replaceAll('MainContent_EventFormView_', 'x_'),
        );
        final reason = 'event $id';

        expect(renamed.anomalie, isEmpty, reason: reason);
        expect(renamed.titolo, original.titolo, reason: reason);
        expect(renamed.regione, original.regione, reason: reason);
        expect(renamed.partenza, original.partenza, reason: reason);
        expect(renamed.rientro, original.rientro, reason: reason);
        expect(renamed.quotaCentesimi, original.quotaCentesimi, reason: reason);
        expect(renamed.localita, original.localita, reason: reason);
        expect(renamed.iscritti, original.iscritti, reason: reason);
        expect(renamed.iscrittiMax, original.iscrittiMax, reason: reason);
        expect(renamed.letti, original.letti, reason: reason);
        expect(renamed.sottotitolo, original.sottotitolo, reason: reason);
        expect(renamed.capiCampo, original.capiCampo, reason: reason);
        expect(
          renamed.aperturaIscrizioni,
          original.aperturaIscrizioni,
          reason: reason,
        );
        expect(
          renamed.chiusuraIscrizioni,
          original.chiusuraIscrizioni,
          reason: reason,
        );
        expect(
          renamed.linkPresentazione,
          original.linkPresentazione,
          reason: reason,
        );
        expect(renamed.infoSegreteria, original.infoSegreteria, reason: reason);
        expect(
          renamed.contattoMetodologico,
          original.contattoMetodologico,
          reason: reason,
        );
        expect(
          renamed.contattoAmministrativo,
          original.contattoAmministrativo,
          reason: reason,
        );
        expect(
          renamed.appuntamenti.length,
          original.appuntamenti.length,
          reason: reason,
        );
      }
    });
  });

  group('values out of format', () {
    final html = _fixture('event_26719');

    test('subscription date', () {
      final d = parseEventDetail(
        html.replaceFirstMapped(
          RegExp(r'(lbSubsFrom"[^>]*>)[^<]*'),
          (m) => '${m[1]}presto',
        ),
      );

      expect(d.aperturaIscrizioni, isNull);
      expect(d.anomalie.single, contains('apertura'));
    });

    test('fee', () {
      final d = parseEventDetail(html.replaceFirst('21,00 €', 'gratis'));

      expect(d.letti, isNot(contains(CampoCondiviso.quota)));
      expect(d.anomalie.single, contains('gratis'));
    });

    test('presentation link that is not a web address', () {
      final d = parseEventDetail(
        _fixture('event_26533').replaceFirst(
          'href="https://foca.agesci.it/evento/cfa-novembre-b-roma-rm/"',
          'href="javascript:void(0)"',
        ),
      );

      expect(d.linkPresentazione, isNull);
      expect(d.anomalie.single, contains('javascript'));
    });

    test('contact that is not an email address', () {
      final d = parseEventDetail(
        html.replaceFirst(
          'href="mailto:eventi@lazio.agesci.it"',
          'href="https://lazio.agesci.it"',
        ),
      );

      expect(d.contattoAmministrativo, isNull);
      expect(d.anomalie.single, contains('Contatto amministrativo'));
    });

    test('session dates', () {
      final d = parseEventDetail(
        _fixture('event_26575')
            .replaceFirst('23/01/2027 - 24/01/2027', 'gennaio'),
      );

      expect(d.appuntamenti, hasLength(3));
      expect(d.appuntamenti[1].dal, isNull);
      expect(d.appuntamenti[1].localita, 'Savona (SV)');
      expect(d.anomalie.single, contains('gennaio'));
    });
  });

  group('merge with the list', () {
    final elenco = {
      for (final e in parseEventList(_fixture('events_all_1'))) e.id: e,
    };

    test('list and event pages agree on every fixture', () {
      for (final id in _detailIds) {
        final evento = conDettaglio(elenco[id]!, _detail(id));

        expect(evento.anomalie, isEmpty, reason: 'event $id');
      }
    });

    test('adds the detail fields and keeps the list fields', () {
      final evento = conDettaglio(elenco[26870]!, _detail(26870));

      expect(evento.id, 26870);
      expect(evento.sigla, 'PO');
      expect(evento.sottotitolo, 'Che il gioco abbia inizio...Jumanji!');
      expect(evento.capiCampo, ['CAPO UNO', 'CAPO DUE']);
      expect(evento.contattoAmministrativo, 'eventi@toscana.agesci.it');
    });

    test('a different value keeps the list one and is reported', () {
      final dettaglio = parseEventDetail(
        _fixture('event_26719').replaceFirst('21,00 €', '25,00 €'),
      );

      final evento = conDettaglio(elenco[26719]!, dettaglio);

      expect(evento.quotaCentesimi, 2100);
      expect(
        evento.anomalie.single,
        'Quota diversa tra elenco e pagina dell\'evento: '
        '21,00 € nell\'elenco, 25,00 € nella pagina',
      );
    });

    test('no limit and no fee are shown in words', () {
      final dettaglio = parseEventDetail(
        _fixture('event_26770')
            .replaceFirst('>illimitati<', '>30<')
            .replaceFirst("nessuna quota d'iscrizione", '10,00 €'),
      );

      final anomalie = conDettaglio(elenco[26770]!, dettaglio).anomalie;

      expect(anomalie, hasLength(2));
      expect(anomalie, contains(contains('senza limite nell\'elenco')));
      expect(anomalie, contains(contains('nessuna quota nell\'elenco')));
    });

    test('a value not read from the page is not compared', () {
      final dettaglio = parseEventDetail(
        _fixture('event_26719').replaceFirst('21,00 €', 'gratis'),
      );

      final anomalie = conDettaglio(elenco[26719]!, dettaglio).anomalie;

      expect(anomalie.single, contains('gratis'));
    });
  });
}
