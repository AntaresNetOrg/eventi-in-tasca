// Writes sample PDFs (in both layouts, V-10) and Excel files from the
// fixtures. Same code as the app; only the data comes from test/fixtures.
//
// Usage: dart run tool/prove_pdf.dart [output folder]
import 'dart:io';
import 'dart:typed_data';

import 'package:eventi_bc/domain/con_dettaglio.dart';
import 'package:eventi_bc/domain/ordinamento.dart';
import 'package:eventi_bc/domain/risultato.dart';
import 'package:eventi_bc/export/excel_esportazione.dart';
import 'package:eventi_bc/export/pdf_esportazione.dart';
import 'package:eventi_bc/parsing/parse_event_detail.dart';
import 'package:eventi_bc/parsing/parse_event_list.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.html').readAsStringSync();

ByteData _font(String name) => ByteData.sublistView(
  File('assets/fonts/TitilliumWeb-$name.ttf').readAsBytesSync(),
);

const _dettagli = [
  26719, 26870, 26533, 26575, 26698, 26886, 26678, 26770, 26748, //
];

Future<void> main(List<String> args) async {
  final out = Directory(args.isEmpty ? 'build/prove_pdf' : args.first)
    ..createSync(recursive: true);
  final font = FontPdf.daByte(
    regolare: _font('Regular'),
    semiBold: _font('SemiBold'),
    grassetto: _font('Bold'),
    corsivo: _font('Italic'),
  );
  final estrattoIl = DateTime(2026, 11, 6, 9, 30);

  final tutti = parseEventList(_fixture('events_all_1'));
  final perId = {for (final e in tutti) e.id: e};

  final prove = {
    'lazio-piccole-orme': Risultato(
      ricerca: const Ricerca(
        tipo: 'Piccole Orme',
        regione: 'Lazio',
        soloAperte: true,
        dettagli: false,
      ),
      eventi: ordinaEventi(parseEventList(_fixture('events_lazio_po'))),
      estrattoIl: estrattoIl,
    ),
    'con-dettagli': Risultato(
      ricerca: const Ricerca(
        tipo: 'Prova con dettagli (tipi diversi)',
        regione: null,
        soloAperte: false,
        dettagli: true,
      ),
      eventi: ordinaEventi([
        for (final id in _dettagli)
          conDettaglio(perId[id]!, parseEventDetail(_fixture('event_$id'))),
      ]),
      estrattoIl: estrattoIl,
    ),
    'elenco-completo': Risultato(
      ricerca: const Ricerca(
        tipo: 'Tutti i tipi (elenco completo)',
        regione: null,
        soloAperte: false,
        dettagli: false,
      ),
      eventi: ordinaEventi(tutti),
      estrattoIl: estrattoIl,
    ),
  };

  for (final MapEntry(key: nome, value: risultato) in prove.entries) {
    for (final layout in LayoutPdf.values) {
      final file = File('${out.path}/$nome-${layout.name}.pdf');
      file.writeAsBytesSync(
        await creaPdf(risultato, font: font, layout: layout),
      );
      stdout.writeln(file.path);
    }
    final excel = File('${out.path}/$nome.xlsx')
      ..writeAsBytesSync(creaExcel(risultato));
    stdout.writeln(excel.path);
  }
}
