import 'dart:io';

import '../domain/risultato.dart';
import 'excel_esportazione.dart';
import 'file_temporanei.dart';
import 'nomi_file.dart';
import 'pdf_esportazione.dart';

const mimePdf = 'application/pdf';
const mimeXlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Writes the files of a result in the formats chosen before the search.
class Esportazione {
  Esportazione({required this.fileTemporanei, required this.font});

  final FileTemporanei fileTemporanei;

  /// Loaded only when a PDF is needed.
  final Future<FontPdf> Function() font;

  /// The files to share, after removing those of the previous export.
  Future<List<File>> crea(Risultato risultato) async {
    await fileTemporanei.svuota();
    final nome = nomeFile(risultato);
    final ricerca = risultato.ricerca;
    return [
      if (ricerca.pdf)
        await fileTemporanei.scrivi(
          '$nome.pdf',
          await creaPdf(risultato, font: await font()),
        ),
      if (ricerca.excel)
        await fileTemporanei.scrivi('$nome.xlsx', creaExcel(risultato)),
    ];
  }
}
