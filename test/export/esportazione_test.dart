import 'dart:io';
import 'dart:typed_data';

import 'package:eventi_bc/domain/con_dettaglio.dart';
import 'package:eventi_bc/domain/ordinamento.dart';
import 'package:eventi_bc/domain/risultato.dart';
import 'package:eventi_bc/export/esportazione.dart';
import 'package:eventi_bc/export/excel_esportazione.dart';
import 'package:eventi_bc/export/file_temporanei.dart';
import 'package:eventi_bc/export/nomi_file.dart';
import 'package:eventi_bc/export/nota_fonte.dart';
import 'package:eventi_bc/export/pdf_esportazione.dart';
import 'package:eventi_bc/parsing/parse_event_detail.dart';
import 'package:eventi_bc/parsing/parse_event_list.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.html').readAsStringSync();

ByteData _font(String name) => ByteData.sublistView(
  File('assets/fonts/TitilliumWeb-$name.ttf').readAsBytesSync(),
);

FontPdf _fontPdf() => FontPdf.daByte(
  regolare: _font('Regular'),
  semiBold: _font('SemiBold'),
  grassetto: _font('Bold'),
  corsivo: _font('Italic'),
);

final _quando = DateTime(2026, 11, 6, 9, 5);

Risultato _lazio({bool pdf = true, bool excel = false}) => Risultato(
  ricerca: Ricerca(
    tipo: 'Piccole Orme',
    regione: 'Lazio',
    soloAperte: true,
    dettagli: false,
    pdf: pdf,
    excel: excel,
  ),
  eventi: ordinaEventi(parseEventList(_fixture('events_lazio_po'))),
  estrattoIl: _quando,
);

Risultato _conDettagli() {
  final elenco = {
    for (final e in parseEventList(_fixture('events_all_1'))) e.id: e,
  };
  return Risultato(
    ricerca: const Ricerca(
      tipo: 'Prova',
      regione: null,
      soloAperte: false,
      dettagli: true,
    ),
    eventi: ordinaEventi([
      for (final id in [26719, 26575, 26770])
        conDettaglio(elenco[id]!, parseEventDetail(_fixture('event_$id'))),
    ]),
    estrattoIl: _quando,
  );
}

void main() {
  group('file names', () {
    test('slug without accents and separators', () {
      expect(slug('Specialità E/G'), 'specialita-e-g');
      expect(slug("Valle d'Aosta"), 'valle-d-aosta');
      expect(slug('--- CFM ---'), 'cfm');
    });

    test('type, region and date', () {
      expect(nomeFile(_lazio()), 'eventi_piccole-orme_lazio_20261106');
      expect(
        nomeFile(_conDettagli()),
        'eventi_prova_tutte-le-regioni_20261106',
      );
    });
  });

  test('the source note of D-00', () {
    final nota = notaFonte(_quando);

    expect(nota, contains('Fonte: BuonaCaccia (buonacaccia.agesci.it)'));
    expect(nota, contains('il 06/11/2026 alle 09:05'));
    expect(nota, contains('Per iscriversi e per i dati aggiornati'));
    expect(nota, contains('app non ufficiale'));
  });

  group('PDF', () {
    test('table without details, cards with details', () {
      expect(layoutPer(_lazio().ricerca), LayoutPdf.tabella);
      expect(layoutPer(_conDettagli().ricerca), LayoutPdf.schede);
    });

    for (final layout in LayoutPdf.values) {
      test('${layout.name}: a valid PDF, also with details', () async {
        for (final risultato in [_lazio(), _conDettagli()]) {
          final bytes = await creaPdf(
            risultato,
            font: _fontPdf(),
            layout: layout,
          );
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        }
      });
    }

    test('298 events do not exceed the page limit', () async {
      final tutti = Risultato(
        ricerca: const Ricerca(
          tipo: 'Tutti',
          regione: null,
          soloAperte: false,
          dettagli: false,
        ),
        eventi: parseEventList(_fixture('events_all_1')),
        estrattoIl: _quando,
      );

      for (final layout in LayoutPdf.values) {
        await expectLater(
          creaPdf(tutti, font: _fontPdf(), layout: layout),
          completes,
        );
      }
    });

    test('an empty result is still a document', () async {
      final vuoto = Risultato(
        ricerca: _lazio().ricerca,
        eventi: const [],
        estrattoIl: _quando,
      );

      final bytes = await creaPdf(vuoto, font: _fontPdf());

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('Excel', () {
    Sheet foglio(Risultato risultato) {
      final excel = Excel.decodeBytes(creaExcel(risultato));
      expect(excel.tables.keys, [foglioEventi]);
      return excel.tables[foglioEventi]!;
    }

    List<String> intestazioni(Sheet s) => [
      for (final c in s.rows.first) (c!.value as TextCellValue).value.text!,
    ];

    CellValue? valore(Sheet s, int riga, String colonna) =>
        s.rows[riga][intestazioni(s).indexOf(colonna)]?.value;

    test('one row per event, with typed values', () {
      final s = foglio(_lazio());

      expect(intestazioni(s), isNot(contains('Capi campo')));
      expect(
        (valore(s, 1, 'Titolo')! as TextCellValue).value.text,
        'Piccole Orme - Dicembre 1 - Quadriennale',
      );
      final partenza = valore(s, 1, 'Partenza')! as DateCellValue;
      expect((partenza.year, partenza.month, partenza.day), (2026, 12, 5));
      // A number in euro; when read back, whole amounts come as integers.
      final quota = switch (valore(s, 1, 'Quota')) {
        DoubleCellValue(:final value) => value,
        IntCellValue(:final value) => value.toDouble(),
        final altro => fail('Quota is not a number: $altro'),
      };
      expect(quota, 21.0);
      expect((valore(s, 1, 'Iscritti')! as IntCellValue).value, 29);
      expect((valore(s, 1, 'Posti')! as IntCellValue).value, 28);
      expect(
        (valore(s, 1, 'Pagina su BuonaCaccia')! as TextCellValue).value.text,
        'https://buonacaccia.agesci.it/Event.aspx?e=26719',
      );
    });

    test('the details add their columns', () {
      final s = foglio(_conDettagli());
      final titoli = intestazioni(s);

      expect(
        titoli,
        containsAll(['Capi campo', 'Appuntamenti', 'Sottotitolo']),
      );
      final senzaLimite = [for (var r = 1; r <= 3; r++) valore(s, r, 'Posti')]
          .whereType<TextCellValue>();
      expect(senzaLimite.single.value.text, 'senza limite');
    });

    test('the D-00 note follows the events', () {
      final s = foglio(_lazio());
      final testi = [
        for (final riga in s.rows.skip(10))
          for (final c in riga)
            if (c?.value case TextCellValue(:final value)) value.text,
      ];

      expect(testi, contains(notaFonte(_quando)));
    });
  });

  group('temporary files', () {
    late Directory radice;

    setUp(() => radice = Directory.systemTemp.createTempSync('eventi_bc'));
    tearDown(() => radice.deleteSync(recursive: true));

    test('only the chosen formats, and the old files are removed', () async {
      final temporanei = FileTemporanei(() async => radice);
      final esportazione = Esportazione(
        fileTemporanei: temporanei,
        font: () async => _fontPdf(),
      );

      final primi = await esportazione.crea(_lazio(excel: true));
      expect(primi.map((f) => f.uri.pathSegments.last), [
        'eventi_piccole-orme_lazio_20261106.pdf',
        'eventi_piccole-orme_lazio_20261106.xlsx',
      ]);

      final secondi = await esportazione.crea(_conDettagli());
      expect(secondi, hasLength(1));
      final rimasti = (await temporanei.cartella()).listSync();
      expect(rimasti.map((f) => f.uri.pathSegments.last), [
        'eventi_prova_tutte-le-regioni_20261106.pdf',
      ]);
    });

    test('emptying works also when nothing was written', () async {
      final temporanei = FileTemporanei(() async => radice);

      await temporanei.svuota();
      await temporanei.scrivi('x.pdf', [1]);
      await temporanei.svuota();

      expect(await (await temporanei.cartella()).exists(), isFalse);
    });
  });
}
