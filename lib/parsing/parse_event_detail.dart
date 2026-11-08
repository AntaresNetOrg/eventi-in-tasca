import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/dettaglio_evento.dart';
import '../domain/evento.dart';
import 'bc_page_format_exception.dart';
import 'parse_values.dart';

const _idPrefix = 'MainContent_EventFormView_';

const _noFee = "nessuna quota d'iscrizione";
const _noLocation = '(da definire)';
const _noLimit = 'illimitati';
const _noLink = '(link di presentazione non disponibile)';
const _noContact = '(non disponibile)';
const _ownerSeparator = ' - ';

// Text labels of the page, used when an id is missing (D-05).
const _labelOwners = 'I Capi Campo';
const _labelRegion = 'della regione';
const _labelFrom = 'avrà luogo dal';
const _labelTo = 'al';
const _labelLocation = 'in località';
const _labelFee = "La quota d'iscrizione è di";
const _labelDescription = 'Informazioni dalla segreteria';
const _labelSeats = 'Posti disponibili:';
const _labelSubsFrom = 'Apriranno il';
const _labelSubsTo = 'Chiuderanno il';
const _labelTaken = 'Al momento ci sono';
const _labelPoC = 'Per informazioni metodologiche:';
const _labelAdmin = 'Per informazioni amministrative:';
const _columnDates = 'Date';
const _columnLocation = 'Località';

/// `[Regione] Titolo`: the event page puts the region before the title.
final _titleWithRegion = RegExp(r'^\[[^\]]*\]\s*(.*)$');
final _dateRange = RegExp(r'^(\S+)\s+-\s+(\S+)$');
final _integer = RegExp(r'^\d+$');
final _spaces = RegExp(r'[ \t ]+');

/// Reads the page `Event.aspx` of one event (D-11).
///
/// Throws [BcPageFormatException] if the page has no event title: for example
/// a page of another kind, or a site that has changed.
DettaglioEvento parseEventDetail(String html) {
  final document = html_parser.parse(html);
  final anomalie = <String>[];
  final letti = <CampoCondiviso>{};

  final titleElement =
      _byId(document, 'lbTitle') ?? document.querySelector('h2 > span');
  final rawTitle = titleElement == null ? '' : cleanText(titleElement);
  if (rawTitle.isEmpty) {
    throw const BcPageFormatException('Event title not found');
  }
  letti.add(CampoCondiviso.titolo);
  final titolo = _titleWithRegion.firstMatch(rawTitle)?[1] ?? rawTitle;

  /// Text of the element with [id] or, failing that, after [label].
  String? text(String id, String label, {bool exact = false}) {
    final element =
        _byId(document, id) ?? _afterLabel(document, label, exact: exact);
    return element == null ? null : cleanText(element);
  }

  /// A shared field: [read] returns false when the text is out of format.
  void shared(
    CampoCondiviso campo,
    String? value,
    String label,
    bool Function(String value) read,
  ) {
    if (value == null) {
      anomalie.add('$label non trovata nella pagina dell\'evento');
    } else if (read(value)) {
      letti.add(campo);
    } else {
      anomalie.add(
        '$label non riconosciuta nella pagina dell\'evento: '
        '"$value"',
      );
    }
  }

  final regione = text('lbRegion', _labelRegion);
  if (regione != null && regione.isNotEmpty) {
    letti.add(CampoCondiviso.regione);
  } else {
    anomalie.add('Regione non trovata nella pagina dell\'evento');
  }

  DateTime? partenza;
  shared(
    CampoCondiviso.partenza,
    text('lbEventFrom', _labelFrom),
    'Data di partenza',
    (v) => (partenza = parseDate(v)) != null,
  );
  DateTime? rientro;
  shared(
    CampoCondiviso.rientro,
    text('lbEventTo', _labelTo, exact: true),
    'Data di rientro',
    (v) => (rientro = parseDate(v)) != null,
  );

  int? quotaCentesimi;
  shared(CampoCondiviso.quota, text('lbFee', _labelFee), 'Quota', (v) {
    if (v == _noFee) return true;
    return (quotaCentesimi = parseFeeCents(v)) != null;
  });

  final appuntamenti = _parseAppointments(document, anomalie);
  String? localita;
  final locationText = text('lbLocation', _labelLocation);
  if (locationText != null && locationText.isNotEmpty) {
    letti.add(CampoCondiviso.localita);
    localita = locationText == _noLocation ? null : locationText;
  } else if (appuntamenti.isEmpty) {
    // Events in several sessions have a location per session instead.
    anomalie.add('Località non trovata nella pagina dell\'evento');
  }

  int? iscritti;
  shared(
    CampoCondiviso.iscritti,
    text('lbTaken', _labelTaken),
    'Numero di iscritti',
    (v) {
      if (!_integer.hasMatch(v)) return false;
      iscritti = int.parse(v);
      return true;
    },
  );
  int? iscrittiMax;
  shared(
    CampoCondiviso.iscrittiMax,
    text('lbSeats', _labelSeats),
    'Numero massimo di iscritti',
    (v) {
      if (v == _noLimit) return true;
      if (!_integer.hasMatch(v)) return false;
      iscrittiMax = int.parse(v);
      return true;
    },
  );

  DateTime? subsDate(String id, String label, String name) {
    final value = text(id, label);
    final date = value == null ? null : parseDate(value);
    if (date == null) {
      anomalie.add(
        value == null
            ? '$name non trovata'
            : '$name non riconosciuta: "$value"',
      );
    }
    return date;
  }

  final sottotitoloElement =
      _byId(document, 'lblSottotitolo') ??
      document.querySelector('h3.well > span');
  final sottotitolo = sottotitoloElement == null
      ? ''
      : cleanText(sottotitoloElement);

  return DettaglioEvento(
    titolo: titolo,
    regione: regione,
    partenza: partenza,
    rientro: rientro,
    quotaCentesimi: quotaCentesimi,
    localita: localita,
    iscritti: iscritti,
    iscrittiMax: iscrittiMax,
    letti: Set.unmodifiable(letti),
    sottotitolo: sottotitolo.isEmpty ? null : sottotitolo,
    capiCampo: _parseOwners(document, anomalie),
    aperturaIscrizioni: subsDate(
      'lbSubsFrom',
      _labelSubsFrom,
      'Data di apertura iscrizioni',
    ),
    chiusuraIscrizioni: subsDate(
      'lbSubsTo',
      _labelSubsTo,
      'Data di chiusura iscrizioni',
    ),
    linkPresentazione: _parseLink(document, anomalie),
    appuntamenti: appuntamenti,
    infoSegreteria: _parseDescription(html),
    contattoMetodologico: _parseContact(
      document,
      'hlPoC',
      _labelPoC,
      'Contatto metodologico',
      anomalie,
    ),
    contattoAmministrativo: _parseContact(
      document,
      'hlAdmin',
      _labelAdmin,
      'Contatto amministrativo',
      anomalie,
    ),
    anomalie: List.unmodifiable(anomalie),
  );
}

Element? _byId(Document document, String id) =>
    document.getElementById('$_idPrefix$id');

/// The first `span` or `a` that follows a text node ending with [label].
Element? _afterLabel(Document document, String label, {bool exact = false}) {
  final pattern = RegExp('${exact ? r'(^|\s)' : ''}${RegExp.escape(label)}\$');
  for (final parent in document.querySelectorAll('*')) {
    final nodes = parent.nodes;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is! Text) continue;
      final value = node.text.replaceAll(' ', ' ').trim();
      if (!pattern.hasMatch(value)) continue;
      for (final next in nodes.skip(i + 1)) {
        if (next is Element &&
            (next.localName == 'span' || next.localName == 'a')) {
          return next;
        }
      }
    }
  }
  return null;
}

/// The heading [title] (`h3`), followed by a paragraph containing a span.
Element? _afterHeading(Document document, String title) {
  for (final heading in document.querySelectorAll('h3')) {
    if (cleanText(heading) != title) continue;
    final paragraph = heading.nextElementSibling;
    return paragraph?.querySelector('span');
  }
  return null;
}

List<String> _parseOwners(Document document, List<String> anomalie) {
  final element =
      _byId(document, 'lbOwners') ?? _afterHeading(document, _labelOwners);
  if (element == null) {
    anomalie.add('Capi campo non trovati');
    return const [];
  }
  return List.unmodifiable(
    cleanText(element)
        .split(_ownerSeparator)
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty),
  );
}

Uri? _parseLink(Document document, List<String> anomalie) {
  final element =
      _byId(document, 'hlURL') ??
      document
          .querySelector('img[src\$="link.png"]')
          ?.parent
          ?.querySelector('a');
  if (element == null) {
    anomalie.add('Link di presentazione non trovato');
    return null;
  }
  final href = element.attributes['href'];
  if (href == null) {
    final value = cleanText(element);
    if (value != _noLink) {
      anomalie.add('Link di presentazione non riconosciuto: "$value"');
    }
    return null;
  }
  final uri = Uri.tryParse(href.trim());
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    anomalie.add('Link di presentazione non riconosciuto: "$href"');
    return null;
  }
  return uri;
}

String? _parseContact(
  Document document,
  String id,
  String label,
  String name,
  List<String> anomalie,
) {
  final element = _byId(document, id) ?? _afterLabel(document, label);
  if (element == null) {
    anomalie.add('$name non trovato');
    return null;
  }
  final href = element.attributes['href'];
  if (href == null) {
    final value = cleanText(element);
    if (value != _noContact) {
      anomalie.add('$name non riconosciuto: "$value"');
    }
    return null;
  }
  if (!href.toLowerCase().startsWith('mailto:')) {
    anomalie.add('$name non riconosciuto: "$href"');
    return null;
  }
  // Some addresses end with an encoded line break (`%0d%0a`).
  final address = Uri.decodeComponent(href.substring('mailto:'.length)).trim();
  if (address.isEmpty) {
    anomalie.add('$name non riconosciuto: "$href"');
    return null;
  }
  return address;
}

List<Appuntamento> _parseAppointments(
  Document document,
  List<String> anomalie,
) {
  final table =
      _byId(document, 'gvAppointments') ??
      _tableWithHeaders(document, _columnDates, _columnLocation);
  if (table == null) return const [];

  final rows = _directRows(table);
  if (rows.isEmpty) return const [];
  final headers = rows.first.children.map(cleanText).toList();
  final datesIndex = headers.indexOf(_columnDates);
  final locationIndex = headers.indexOf(_columnLocation);
  if (datesIndex < 0 || locationIndex < 0) {
    anomalie.add('Tabella degli appuntamenti non riconosciuta');
    return const [];
  }

  final appuntamenti = <Appuntamento>[];
  for (final row in rows.skip(1)) {
    final cells = row.children;
    String cell(int index) =>
        index < cells.length ? cleanText(cells[index]) : '';

    final dates = cell(datesIndex);
    final range = _dateRange.firstMatch(dates);
    final dal = range == null ? null : parseDate(range[1]!);
    final al = range == null ? null : parseDate(range[2]!);
    if (dal == null || al == null) {
      anomalie.add('Date di un appuntamento non riconosciute: "$dates"');
    }
    final localita = cell(locationIndex);
    appuntamenti.add(
      Appuntamento(
        dal: dal,
        al: al,
        localita: localita.isEmpty ? null : localita,
      ),
    );
  }
  return List.unmodifiable(appuntamenti);
}

/// The table whose own first row is the header [first], [second]. Nested
/// tables are not looked into: the whole page is a table containing this one.
Element? _tableWithHeaders(Document document, String first, String second) {
  for (final table in document.querySelectorAll('table')) {
    final rows = _directRows(table);
    if (rows.isEmpty) continue;
    final headers = rows.first.children
        .where((cell) => cell.localName == 'th')
        .map(cleanText)
        .toList();
    if (headers.length == 2 && headers[0] == first && headers[1] == second) {
      return table;
    }
  }
  return null;
}

List<Element> _directRows(Element table) => [
  for (final section in table.children)
    for (final row in section.children)
      if (row.localName == 'tr') row,
];

// "Informazioni dalla segreteria" holds paragraphs inside a `span` inside a
// `p`. That is invalid HTML: an HTML5 parser closes the outer paragraph and
// moves the content out of the span. So the fragment is cut from the source
// text, balancing nested spans, and parsed on its own.

final _descriptionStart = RegExp(
  '<span\\b[^>]*\\bid="${_idPrefix}lbDescription"[^>]*>',
);
final _descriptionHeading = RegExp(
  '<h3>\\s*${RegExp.escape(_labelDescription)}\\s*</h3>\\s*<p>\\s*<span\\b[^>]*>',
);
final _spanTag = RegExp(r'<(/?)span\b[^>]*>', caseSensitive: false);

String? _parseDescription(String html) {
  final start =
      _descriptionStart.firstMatch(html) ??
      _descriptionHeading.firstMatch(html);
  if (start == null) return null;

  var depth = 1;
  for (final tag in _spanTag.allMatches(html, start.end)) {
    depth += tag[1]!.isEmpty ? 1 : -1;
    if (depth == 0) {
      final fragment = html_parser.parseFragment(
        html.substring(start.end, tag.start),
      );
      return _toPlainText(fragment);
    }
  }
  return null;
}

const _blockElements = {'p', 'div', 'li', 'ul', 'ol', 'h1', 'h2', 'h3', 'h4'};

/// Plain text with one line per paragraph or line break, without empty lines.
/// Links keep their address when it differs from their text (V-05).
String? _toPlainText(Node root) {
  final buffer = StringBuffer();

  void visit(Node node) {
    if (node is Text) {
      buffer.write(node.text);
    } else if (node is Element) {
      final name = node.localName;
      if (name == 'br') {
        buffer.write('\n');
        return;
      }
      final block = _blockElements.contains(name);
      if (block) buffer.write('\n');
      node.nodes.forEach(visit);
      if (name == 'a') {
        final href = node.attributes['href']?.trim();
        if (href != null && href.isNotEmpty && href != cleanText(node)) {
          buffer.write(' ($href)');
        }
      }
      if (block) buffer.write('\n');
    } else {
      node.nodes.forEach(visit);
    }
  }

  visit(root);
  final lines = buffer
      .toString()
      .split('\n')
      .map((line) => line.replaceAll(_spaces, ' ').trim())
      .where((line) => line.isNotEmpty);
  final text = lines.join('\n');
  return text.isEmpty ? null : text;
}
