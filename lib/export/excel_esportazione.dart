import 'package:excel/excel.dart';

import '../domain/evento.dart';
import '../domain/formati.dart';
import '../domain/risultato.dart';
import 'nota_fonte.dart';

/// Name of the only sheet.
const foglioEventi = 'Eventi';

final _formatoData = NumFormat.custom(formatCode: 'dd/mm/yyyy');
final _formatoEuro = NumFormat.custom(formatCode: '#,##0.00 "€"');

/// One column of the sheet: header, width, value of an event.
class _Colonna {
  const _Colonna(this.titolo, this.larghezza, this.valore, {this.formato});

  final String titolo;
  final double larghezza;
  final CellValue? Function(Evento) valore;
  final NumFormat? formato;
}

CellValue? _testo(String? valore) =>
    valore == null || valore.isEmpty ? null : TextCellValue(valore);

CellValue? _intero(int? valore) => valore == null ? null : IntCellValue(valore);

CellValue? _data(DateTime? d) =>
    d == null ? null : DateCellValue(year: d.year, month: d.month, day: d.day);

/// The fee as a number in euro. Amounts are integer cents everywhere (rule 8);
/// the excel package writes numbers only from a double, so the conversion
/// happens here, on the way out.
CellValue? _euro(int? centesimi) =>
    centesimi == null ? null : DoubleCellValue(centesimi / 100);

List<_Colonna> _colonne(Ricerca ricerca) => [
  _Colonna('Titolo', 45, (e) => _testo(e.titolo)),
  if (ricerca.dettagli)
    _Colonna('Sottotitolo', 30, (e) => _testo(e.sottotitolo)),
  _Colonna('Tipo', 10, (e) => _testo(e.sigla)),
  _Colonna('Regione', 18, (e) => _testo(e.regione)),
  _Colonna('Partenza', 12, (e) => _data(e.partenza), formato: _formatoData),
  _Colonna('Rientro', 12, (e) => _data(e.rientro), formato: _formatoData),
  _Colonna('Località', 24, (e) => _testo(formatLocalita(e.localita))),
  _Colonna('Quota', 10, (e) => _euro(e.quotaCentesimi), formato: _formatoEuro),
  _Colonna('Iscritti', 9, (e) => _intero(e.iscritti)),
  _Colonna(
    'Posti',
    11,
    (e) => e.iscrittiMax == null
        ? TextCellValue('senza limite')
        : IntCellValue(e.iscrittiMax!),
  ),
  _Colonna('Stato', 14, (e) => _testo(etichettaStato(e.stato))),
  _Colonna(
    'Più appuntamenti',
    10,
    (e) => TextCellValue(e.piuAppuntamenti ? 'sì' : 'no'),
  ),
  _Colonna(
    'Posti liberi fuori regione',
    12,
    (e) => _intero(e.postiFuoriRegione),
  ),
  _Colonna('Posti liberi Moz.45/2023', 12, (e) => _intero(e.postiMoz45)),
  if (ricerca.dettagli) ...[
    _Colonna('Capi campo', 30, (e) => _testo(e.capiCampo.join(', '))),
    _Colonna(
      'Apertura iscrizioni',
      12,
      (e) => _data(e.aperturaIscrizioni),
      formato: _formatoData,
    ),
    _Colonna(
      'Chiusura iscrizioni',
      12,
      (e) => _data(e.chiusuraIscrizioni),
      formato: _formatoData,
    ),
    _Colonna(
      'Appuntamenti',
      30,
      (e) => _testo(
        e.appuntamenti
            .map(
              (a) =>
                  '${formatPeriodo(a.dal, a.al)}'
                  '${a.localita == null ? '' : ', ${a.localita}'}',
            )
            .join('; '),
      ),
    ),
    _Colonna(
      'Presentazione',
      30,
      (e) => _testo(e.linkPresentazione?.toString()),
    ),
    _Colonna(
      'Informazioni dalla segreteria',
      50,
      (e) => _testo(e.infoSegreteria),
    ),
    _Colonna(
      'Contatto metodologico',
      26,
      (e) => _testo(e.contattoMetodologico),
    ),
    _Colonna(
      'Contatto amministrativo',
      26,
      (e) => _testo(e.contattoAmministrativo),
    ),
  ],
  _Colonna('Pagina su BuonaCaccia', 45, (e) => _testo(e.url?.toString())),
  _Colonna('Dati da controllare', 40, (e) => _testo(e.anomalie.join('; '))),
];

/// The xlsx of [risultato] (§5): one sheet, a header row, one row per event
/// and, at the end, the note of D-00.
List<int> creaExcel(Risultato risultato) {
  final excel = Excel.createExcel();
  final predefinito = excel.getDefaultSheet()!;
  excel.rename(predefinito, foglioEventi);
  final foglio = excel[foglioEventi];
  final colonne = _colonne(risultato.ricerca);

  final intestazione = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#1E4A30'),
  );
  for (final (c, colonna) in colonne.indexed) {
    foglio.setColumnWidth(c, colonna.larghezza);
    foglio.updateCell(
      CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      TextCellValue(colonna.titolo),
      cellStyle: intestazione,
    );
  }

  for (final (r, evento) in risultato.eventi.indexed) {
    for (final (c, colonna) in colonne.indexed) {
      final valore = colonna.valore(evento);
      if (valore == null) continue;
      final formato = colonna.formato;
      foglio.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        valore,
        cellStyle: formato == null ? null : CellStyle(numberFormat: formato),
      );
    }
  }

  final ricerca = risultato.ricerca;
  final rigaNota = risultato.eventi.length + 2;
  foglio.updateCell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rigaNota),
    TextCellValue(
      '${ricerca.tipo} · ${ricerca.regione ?? 'Tutte le regioni'}'
      '${ricerca.soloAperte ? ' · solo iscrizioni aperte o da aprire' : ''}',
    ),
    cellStyle: CellStyle(bold: true),
  );
  foglio.updateCell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rigaNota + 1),
    TextCellValue(notaFonte(risultato.estrattoIl)),
  );

  final bytes = excel.encode();
  if (bytes == null) throw StateError('Excel encoding failed');
  return bytes;
}
