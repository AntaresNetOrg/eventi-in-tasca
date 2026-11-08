import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/evento.dart';
import '../domain/formati.dart';
import '../domain/risultato.dart';
import 'nota_fonte.dart';

/// How events are laid out in the PDF (V-10).
enum LayoutPdf { tabella, schede }

/// Chosen by Andrea on the sample files (08/11/2026): a compact table for the
/// list, a card per event when the details make the rows long.
LayoutPdf layoutPer(Ricerca ricerca) =>
    ricerca.dettagli ? LayoutPdf.schede : LayoutPdf.tabella;

/// Titillium Web (OFL), loaded by the caller: from the app assets or, in tools
/// and tests, from `assets/fonts/`.
class FontPdf {
  const FontPdf({
    required this.regolare,
    required this.semiBold,
    required this.grassetto,
    required this.corsivo,
  });

  factory FontPdf.daByte({
    required ByteData regolare,
    required ByteData semiBold,
    required ByteData grassetto,
    required ByteData corsivo,
  }) => FontPdf(
    regolare: pw.Font.ttf(regolare),
    semiBold: pw.Font.ttf(semiBold),
    grassetto: pw.Font.ttf(grassetto),
    corsivo: pw.Font.ttf(corsivo),
  );

  final pw.Font regolare;
  final pw.Font semiBold;
  final pw.Font grassetto;
  final pw.Font corsivo;
}

/// Colours of the app icon (D-13).
const _verdeScuro = PdfColor.fromInt(0xFF1E4A30);
const _verde = PdfColor.fromInt(0xFF2F6B45);
const _giallo = PdfColor.fromInt(0xFFF2B33D);
const _arancio = PdfColor.fromInt(0xFFF08C2E);
const _rosso = PdfColor.fromInt(0xFFE8573C);
const _grigio = PdfColor.fromInt(0xFF5F6B66);
const _bordo = PdfColor.fromInt(0xFFCFD8D3);
const _sfondoRiga = PdfColor.fromInt(0xFFF3F6F4);

/// The PDF of [risultato]: A4 landscape (P-09), header on every page, the
/// note of D-00 in every footer and a legend of the states at the end.
Future<Uint8List> creaPdf(
  Risultato risultato, {
  required FontPdf font,
  LayoutPdf? layout,
}) {
  layout ??= layoutPer(risultato.ricerca);
  final ricerca = risultato.ricerca;
  final documento = pw.Document(
    title: 'Eventi ${ricerca.tipo}',
    author: 'Eventi in tasca',
    creator: 'Eventi in tasca',
  );
  final tema = pw.ThemeData.withFont(
    base: font.regolare,
    bold: font.grassetto,
    italic: font.corsivo,
  ).copyWith(defaultTextStyle: pw.TextStyle(font: font.regolare, fontSize: 9));
  final semiBold = pw.TextStyle(font: font.semiBold);

  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      theme: tema,
      // A long list must never be cut: one page holds at least a few events.
      maxPages: 1000,
      header: (context) => _intestazione(risultato, context),
      footer: (context) => _piede(risultato, context),
      build: (context) => [
        if (risultato.eventi.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 24),
            child: pw.Text('Nessun evento corrisponde alla ricerca.'),
          )
        else if (layout == LayoutPdf.tabella)
          _tabella(risultato, semiBold)
        else
          ..._schede(risultato, semiBold),
        pw.SizedBox(height: 16),
        _legenda(),
      ],
    ),
  );
  return documento.save();
}

pw.Widget _intestazione(Risultato risultato, pw.Context context) {
  final ricerca = risultato.ricerca;
  final quanti = risultato.eventi.length;
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _verde, width: 1.5)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                ricerca.tipo,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _verdeScuro,
                ),
              ),
              pw.Text(
                '${ricerca.regione ?? 'Tutte le regioni'} · '
                '${quanti == 1 ? '1 evento' : '$quanti eventi'}'
                '${ricerca.soloAperte ? ' con iscrizioni aperte o da aprire' : ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.Text(
          'Estratti da BuonaCaccia il '
          '${formatDataOra(risultato.estrattoIl).replaceFirst(' ', ' alle ')}',
          style: const pw.TextStyle(fontSize: 9, color: _grigio),
        ),
      ],
    ),
  );
}

pw.Widget _piede(Risultato risultato, pw.Context context) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 8),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(
          notaFonte(risultato.estrattoIl),
          style: const pw.TextStyle(fontSize: 7.5, color: _grigio),
        ),
      ),
      pw.SizedBox(width: 16),
      pw.Text(
        'Pagina ${context.pageNumber} di ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 7.5, color: _grigio),
      ),
    ],
  ),
);

// --- Table layout -----------------------------------------------------------

pw.Widget _tabella(Risultato risultato, pw.TextStyle semiBold) {
  final tutteLeRegioni = risultato.ricerca.regione == null;
  final intestazioni = [
    'Evento',
    if (tutteLeRegioni) 'Regione',
    'Date',
    'Località',
    'Quota',
    'Iscritti',
    'Stato',
  ];
  final larghezze = <int, pw.TableColumnWidth>{};
  var i = 0;
  larghezze[i++] = const pw.FlexColumnWidth(5);
  if (tutteLeRegioni) larghezze[i++] = const pw.FlexColumnWidth(1.4);
  larghezze[i++] = const pw.FlexColumnWidth(1.9);
  larghezze[i++] = const pw.FlexColumnWidth(1.8);
  larghezze[i++] = const pw.FlexColumnWidth(1.1);
  larghezze[i++] = const pw.FlexColumnWidth(1.4);
  larghezze[i++] = const pw.FlexColumnWidth(1.4);

  pw.Widget cella(pw.Widget child) =>
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: child);

  return pw.Table(
    columnWidths: larghezze,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _bordo, width: 0.5),
      bottom: pw.BorderSide(color: _bordo, width: 0.5),
    ),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _verdeScuro),
        children: [
          for (final t in intestazioni)
            cella(
              pw.Text(
                t,
                style: semiBold.copyWith(color: PdfColors.white, fontSize: 9),
              ),
            ),
        ],
      ),
      for (final (n, e) in risultato.eventi.indexed)
        pw.TableRow(
          decoration: n.isOdd
              ? const pw.BoxDecoration(color: _sfondoRiga)
              : null,
          children: [
            cella(_titoloConDettagli(e, semiBold)),
            if (tutteLeRegioni) cella(pw.Text(e.regione)),
            cella(pw.Text(_date(e))),
            cella(pw.Text(formatLocalita(e.localita))),
            cella(pw.Text(formatQuota(e.quotaCentesimi))),
            cella(pw.Text(_iscritti(e))),
            cella(_stato(e.stato, semiBold)),
          ],
        ),
    ],
  );
}

/// Title (a link to BuonaCaccia) and, with "Estrai dettagli", the details.
pw.Widget _titoloConDettagli(Evento e, pw.TextStyle semiBold) {
  final righe = _righeDettaglio(e);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _titolo(e, semiBold.copyWith(fontSize: 9.5)),
      if (e.sottotitolo != null)
        pw.Text(e.sottotitolo!, style: const pw.TextStyle(color: _grigio)),
      for (final (etichetta, valore) in righe)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _rigaEtichetta(etichetta, valore, semiBold, 8),
        ),
      if (e.linkPresentazione != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _link('Presentazione dell\'evento', e.linkPresentazione!, 8),
        ),
    ],
  );
}

// --- Card layout ------------------------------------------------------------

List<pw.Widget> _schede(Risultato risultato, pw.TextStyle semiBold) {
  final tutteLeRegioni = risultato.ricerca.regione == null;
  return [
    for (final e in risultato.eventi)
      // A card is never split between two pages.
      pw.Inseparable(child: _scheda(e, tutteLeRegioni, semiBold)),
  ];
}

pw.Widget _scheda(
  Evento e,
  bool tutteLeRegioni,
  pw.TextStyle semiBold,
) => pw.Container(
  margin: const pw.EdgeInsets.only(bottom: 8),
  padding: const pw.EdgeInsets.all(8),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: _bordo, width: 0.8),
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _titolo(e, semiBold.copyWith(fontSize: 11)),
                if (e.sottotitolo != null)
                  pw.Text(
                    e.sottotitolo!,
                    style: const pw.TextStyle(color: _grigio),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          _stato(e.stato, semiBold),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Wrap(
        spacing: 18,
        runSpacing: 2,
        children: [
          if (tutteLeRegioni) _rigaEtichetta('Regione', e.regione, semiBold, 9),
          _rigaEtichetta('Date', _date(e), semiBold, 9),
          _rigaEtichetta('Località', formatLocalita(e.localita), semiBold, 9),
          _rigaEtichetta('Quota', formatQuota(e.quotaCentesimi), semiBold, 9),
          _rigaEtichetta('Iscritti', _iscritti(e), semiBold, 9),
        ],
      ),
      for (final (etichetta, valore) in _righeDettaglio(e))
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _rigaEtichetta(etichetta, valore, semiBold, 9),
        ),
      if (e.linkPresentazione != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: _link('Presentazione dell\'evento', e.linkPresentazione!, 9),
        ),
    ],
  ),
);

// --- Shared pieces ----------------------------------------------------------

pw.Widget _titolo(Evento e, pw.TextStyle stile) {
  final testo = pw.Text(e.titolo, style: stile.copyWith(color: _verdeScuro));
  final url = e.url;
  return url == null
      ? testo
      : pw.UrlLink(destination: url.toString(), child: testo);
}

pw.Widget _link(String testo, Uri destinazione, double dimensione) =>
    pw.UrlLink(
      destination: destinazione.toString(),
      child: pw.Text(
        testo,
        style: pw.TextStyle(
          fontSize: dimensione,
          color: PdfColors.blue800,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    );

pw.Widget _rigaEtichetta(
  String etichetta,
  String valore,
  pw.TextStyle semiBold,
  double dimensione,
) => pw.RichText(
  text: pw.TextSpan(
    style: pw.TextStyle(fontSize: dimensione),
    children: [
      pw.TextSpan(
        text: '$etichetta: ',
        style: semiBold.copyWith(fontSize: dimensione, color: _grigio),
      ),
      pw.TextSpan(text: valore),
    ],
  ),
);

pw.Widget _stato(StatoIscrizioni? stato, pw.TextStyle semiBold) {
  final (sfondo, testo) = switch (stato) {
    StatoIscrizioni.aperte => (_verde, PdfColors.white),
    StatoIscrizioni.inEsaurimento => (_giallo, PdfColors.black),
    StatoIscrizioni.listaAttesa => (_arancio, PdfColors.black),
    StatoIscrizioni.chiuse => (_rosso, PdfColors.white),
    null => (PdfColors.grey300, PdfColors.black),
  };
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: pw.BoxDecoration(
      color: sfondo,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      etichettaStato(stato),
      style: semiBold.copyWith(color: testo, fontSize: 8),
    ),
  );
}

String _date(Evento e) => formatPeriodo(e.partenza, e.rientro);

String _iscritti(Evento e) {
  final quanti = e.iscritti?.toString() ?? '—';
  return e.iscrittiMax == null
      ? '$quanti (senza limite)'
      : '$quanti / ${e.iscrittiMax}';
}

/// Details of "Estrai dettagli" (D-11), as label and text.
List<(String, String)> _righeDettaglio(Evento e) => [
  if (e.piuAppuntamenti && e.appuntamenti.isEmpty)
    ('Appuntamenti', 'evento in più appuntamenti'),
  for (final a in e.appuntamenti)
    (
      'Appuntamento',
      '${formatPeriodo(a.dal, a.al)}'
          '${a.localita == null ? '' : ', ${a.localita}'}',
    ),
  if (e.capiCampo.isNotEmpty) ('Capi campo', e.capiCampo.join(', ')),
  if (e.aperturaIscrizioni != null || e.chiusuraIscrizioni != null)
    (
      'Iscrizioni',
      'dal ${formatData(e.aperturaIscrizioni)} '
          'al ${formatData(e.chiusuraIscrizioni)}',
    ),
  if (e.infoSegreteria != null)
    ('Dalla segreteria', e.infoSegreteria!.replaceAll('\n', ' · ')),
];

pw.Widget _legenda() {
  pw.Widget voce(StatoIscrizioni stato, String descrizione) => pw.Padding(
    padding: const pw.EdgeInsets.only(right: 14),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _stato(stato, const pw.TextStyle()),
        pw.SizedBox(width: 4),
        pw.Text(descrizione, style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );
  return pw.Wrap(
    runSpacing: 4,
    children: [
      voce(StatoIscrizioni.aperte, 'iscrizioni aperte'),
      voce(StatoIscrizioni.inEsaurimento, 'pochi posti o lieve sovrannumero'),
      voce(StatoIscrizioni.listaAttesa, 'forte sovrannumero'),
      voce(StatoIscrizioni.chiuse, 'non ci si può iscrivere ora'),
    ],
  );
}
