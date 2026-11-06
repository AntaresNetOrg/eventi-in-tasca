import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/evento.dart';
import 'bc_page_format_exception.dart';
import 'parse_values.dart';

const _baseUrl = 'https://buonacaccia.agesci.it';
const _idPrefix = 'MainContent_EventsGridView_';

const _emptyListMessage = 'nessun evento corrisponde ai criteri di ricerca';

const _columnTipo = 'Tipo';
const _columnTitolo = 'Titolo';
const _columnRegione = 'Regione';
const _columnPartenza = 'Partenza';
const _columnRientro = 'Rientro';
const _columnQuota = 'Quota';
const _columnLocalita = 'Località';
const _columnIscritti = 'Iscritti';
const _columnStato = 'Stato';

const _requiredColumns = [
  _columnTipo,
  _columnTitolo,
  _columnRegione,
  _columnPartenza,
  _columnRientro,
  _columnQuota,
  _columnLocalita,
  _columnIscritti,
  _columnStato,
];

const _noFee = '-';
const _noLocation = '(da definire)';
const _noLimit = '(*)';

/// The list abbreviates these regions; the others have their full name.
const _regionAbbreviations = {
  'EmiRo': 'Emilia Romagna',
  'FVG': 'Friuli Venezia Giulia',
  'TAA': 'Trentino Alto Adige',
};

/// Labels of the site's region menu.
const _regionNames = {
  'Nazionale',
  'Abruzzo',
  'Basilicata',
  'Calabria',
  'Campania',
  'Emilia Romagna',
  'Friuli Venezia Giulia',
  'Lazio',
  'Liguria',
  'Lombardia',
  'Marche',
  'Molise',
  'Piemonte',
  'Puglia',
  'Sardegna',
  'Sicilia',
  'Toscana',
  'Trentino Alto Adige',
  'Umbria',
  "Valle d'Aosta",
  'Veneto',
};

const _stateByIcon = {
  'green': StatoIscrizioni.aperte,
  'yellow': StatoIscrizioni.inEsaurimento,
  'dual': StatoIscrizioni.listaAttesa,
  'red': StatoIscrizioni.chiuse,
};

const _branchByIcon = {
  'lc': Branca.lc,
  'eg': Branca.eg,
  'rs': Branca.rs,
  'fc': Branca.fc,
  'aa': Branca.aa,
};

final _eventLink = RegExp(r'Event\.aspx\?e=(\d+)');
final _branchIcon = RegExp(r'branch_([a-z]+)\.png');
final _stateIcon = RegExp(r'light_([a-z]+)\.png');
final _integer = RegExp(r'^\d+$');

// D-10: informative icons are recognized by their `title`, not their file name.
final _multipleSessions = RegExp(r'^Evento in più appuntamenti$');
final _seatsOutOfRegion = RegExp(r'^Posti liberi per fuori regione: (-?\d+)$');
final _seatsMoz45 = RegExp(r'^Posti liberi Moz\.45/2023: (-?\d+)$');

/// Reads the events from the page `Events.aspx`, in the site's order.
///
/// Returns an empty list when the site reports that no event matches.
/// Throws [BcPageFormatException] if the page structure is not recognized.
List<Evento> parseEventList(String html) {
  final document = html_parser.parse(html);
  final table =
      document.querySelector('table#MainContent_EventsGridView') ??
      _tableByHeaders(document);
  if (table == null) {
    throw const BcPageFormatException('Event grid not found');
  }

  final rows = _directRows(table);
  if (_isEmptyListMessage(rows)) return const [];
  if (rows.isEmpty) {
    throw const BcPageFormatException('Event grid has no rows');
  }

  final columns = _columnIndexes(rows.first);
  return [for (final row in rows.skip(1)) _parseRow(row, columns)];
}

Element? _tableByHeaders(Document document) {
  for (final table in document.querySelectorAll('table')) {
    final headers = table.querySelectorAll('th').map(cleanText).toSet();
    if (headers.containsAll(_requiredColumns)) return table;
  }
  return null;
}

/// Rows of [table] only: the "Tipo" column contains a nested table.
List<Element> _directRows(Element table) => [
  for (final section in table.children)
    for (final row in section.children)
      if (row.localName == 'tr') row,
];

bool _isEmptyListMessage(List<Element> rows) {
  if (rows.length != 1) return false;
  final cells = rows.single.children;
  return cells.length == 1 &&
      cleanText(cells.single).contains(_emptyListMessage);
}

Map<String, int> _columnIndexes(Element headerRow) {
  final indexes = <String, int>{};
  final cells = headerRow.children;
  for (var i = 0; i < cells.length; i++) {
    indexes[cleanText(cells[i])] = i;
  }
  final missing = _requiredColumns.where((name) => !indexes.containsKey(name));
  if (missing.isNotEmpty) {
    throw BcPageFormatException(
      'Event grid columns not found: ${missing.join(', ')}',
    );
  }
  return indexes;
}

Evento _parseRow(Element row, Map<String, int> columns) {
  final anomalie = <String>[];
  final cells = row.children;

  Element? cell(String column) {
    final index = columns[column]!;
    return index < cells.length ? cells[index] : null;
  }

  String cellText(String column) {
    final element = cell(column);
    return element == null ? '' : cleanText(element);
  }

  /// The element with the row's ASP.NET id, or the text of its column.
  String valueOf(String idSuffix, String column) =>
      _byId(row, idSuffix) ?? cellText(column);

  DateTime? date(String column, String label) {
    final text = cellText(column);
    final value = parseDate(text);
    if (value == null) anomalie.add('$label non riconosciuta: "$text"');
    return value;
  }

  final link = cell(_columnTitolo)?.querySelector('a');
  final id = _parseId(link, anomalie);
  final titolo = link == null ? cellText(_columnTitolo) : cleanText(link);
  if (titolo.isEmpty) anomalie.add('Titolo mancante');

  final icons = _parseIcons(row, anomalie);
  final iscrittiText = cellText(_columnIscritti).split('/');

  return Evento(
    id: id,
    url: id == null ? null : Uri.parse('$_baseUrl/Event.aspx?e=$id'),
    // The id `Type_N` is used twice per row (acronym and region), so here the
    // column comes first.
    sigla: _parseSigla(cell(_columnTipo)),
    branca: _parseBranch(cell(_columnTipo), anomalie),
    titolo: titolo,
    regione: _parseRegion(cell(_columnRegione), anomalie),
    partenza: date(_columnPartenza, 'Data di partenza'),
    rientro: date(_columnRientro, 'Data di rientro'),
    quotaCentesimi: _parseFee(valueOf('Fee', _columnQuota), anomalie),
    localita: _parseLocation(valueOf('Location', _columnLocalita), anomalie),
    iscritti: _parseTaken(
      _byId(row, 'Taken') ?? iscrittiText.first.trim(),
      anomalie,
    ),
    iscrittiMax: _parseMax(
      _byId(row, 'SeatsMax') ??
          (iscrittiText.length > 1 ? iscrittiText[1].trim() : ''),
      anomalie,
    ),
    stato: _parseState(cell(_columnStato), anomalie),
    piuAppuntamenti: icons.piuAppuntamenti,
    postiFuoriRegione: icons.postiFuoriRegione,
    postiMoz45: icons.postiMoz45,
    anomalie: List.unmodifiable(anomalie),
  );
}

String? _byId(Element row, String idSuffix) {
  final element = row.querySelector('[id^="$_idPrefix${idSuffix}_"]');
  return element == null ? null : cleanText(element);
}

int? _parseId(Element? link, List<String> anomalie) {
  final href = link?.attributes['href'] ?? '';
  final match = _eventLink.firstMatch(href);
  if (match == null) {
    anomalie.add('Collegamento alla pagina dell\'evento non riconosciuto');
    return null;
  }
  return int.parse(match[1]!);
}

String _parseSigla(Element? cell) {
  if (cell == null) return '';
  final span = cell.querySelector('span');
  return span == null ? cleanText(cell) : cleanText(span);
}

Branca? _parseBranch(Element? cell, List<String> anomalie) {
  final src = cell?.querySelector('img')?.attributes['src'] ?? '';
  final code = _branchIcon.firstMatch(src)?[1];
  final branca = _branchByIcon[code];
  if (branca == null) anomalie.add('Branca non riconosciuta: "$src"');
  return branca;
}

String _parseRegion(Element? cell, List<String> anomalie) {
  final text = cell == null ? '' : cleanText(cell);
  final name = _regionAbbreviations[text] ?? text;
  if (!_regionNames.contains(name)) {
    anomalie.add('Regione non riconosciuta: "$text"');
  }
  return name;
}

int? _parseFee(String text, List<String> anomalie) {
  if (text == _noFee) return null;
  final cents = parseFeeCents(text);
  if (cents == null) anomalie.add('Quota non riconosciuta: "$text"');
  return cents;
}

String? _parseLocation(String text, List<String> anomalie) {
  if (text == _noLocation) return null;
  if (text.isEmpty) {
    anomalie.add('Località mancante');
    return null;
  }
  return text;
}

int? _parseTaken(String text, List<String> anomalie) {
  if (_integer.hasMatch(text)) return int.parse(text);
  anomalie.add('Numero di iscritti non riconosciuto: "$text"');
  return null;
}

int? _parseMax(String text, List<String> anomalie) {
  if (text == _noLimit) return null;
  if (_integer.hasMatch(text)) return int.parse(text);
  anomalie.add('Numero massimo di iscritti non riconosciuto: "$text"');
  return null;
}

StatoIscrizioni? _parseState(Element? cell, List<String> anomalie) {
  final src = cell?.querySelector('img')?.attributes['src'] ?? '';
  final code = _stateIcon.firstMatch(src)?[1];
  final stato = _stateByIcon[code];
  if (stato == null) anomalie.add('Stato non riconosciuto: "$src"');
  return stato;
}

({bool piuAppuntamenti, int? postiFuoriRegione, int? postiMoz45}) _parseIcons(
  Element row,
  List<String> anomalie,
) {
  var piuAppuntamenti = false;
  int? postiFuoriRegione;
  int? postiMoz45;

  for (final image in row.querySelectorAll('img')) {
    final title = image.attributes['title'];
    if (title == null) continue;
    final outOfRegion = _seatsOutOfRegion.firstMatch(title);
    final moz45 = _seatsMoz45.firstMatch(title);
    if (_multipleSessions.hasMatch(title)) {
      piuAppuntamenti = true;
    } else if (outOfRegion != null) {
      postiFuoriRegione = int.parse(outOfRegion[1]!);
    } else if (moz45 != null) {
      postiMoz45 = int.parse(moz45[1]!);
    } else {
      anomalie.add('Indicazione non riconosciuta: "$title"');
    }
  }

  return (
    piuAppuntamenti: piuAppuntamenti,
    postiFuoriRegione: postiFuoriRegione,
    postiMoz45: postiMoz45,
  );
}
