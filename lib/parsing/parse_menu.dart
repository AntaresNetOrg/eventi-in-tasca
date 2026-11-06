import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/menu_eventi.dart';
import 'bc_page_format_exception.dart';
import 'parse_values.dart';

/// Decorations that the site puts before a menu label: `- `, `--- `, `----> `.
final _labelPrefix = RegExp(r'^-+>?\s*');

/// Group entries carry a `LevelN` class (`Level0LC`, `Level1`, `Level2`...).
final _levelClass = RegExp(r'^Level(\d)');

/// Reads regions and event types from the page `Events.aspx` (D-03).
///
/// Throws [BcPageFormatException] if a menu cannot be found or is empty.
MenuEventi parseMenu(String html) {
  final document = html_parser.parse(html);

  final regioni = [
    for (final option in _options(
      document,
      id: 'MainContent_ddlRegion',
      firstLabel: 'Tutte le regioni',
    ))
      Regione(rid: option.attributes['value']!, nome: _label(option)),
  ];
  final tipi = [
    for (final option in _options(
      document,
      id: 'MainContent_ddlCategory',
      firstLabel: 'Tutti gli eventi',
    ))
      _tipoEvento(option),
  ];

  return MenuEventi(regioni: regioni, tipi: tipi);
}

/// The options of a menu, without the "all" entry that has an empty value.
List<Element> _options(
  Document document, {
  required String id,
  required String firstLabel,
}) {
  final select =
      document.querySelector('select#$id') ??
      _selectByFirstLabel(document, firstLabel);
  if (select == null) {
    throw BcPageFormatException('Menu "$firstLabel" not found');
  }
  final options = select
      .querySelectorAll('option')
      .where((option) => (option.attributes['value'] ?? '').isNotEmpty)
      .toList();
  if (options.isEmpty) {
    throw BcPageFormatException('Menu "$firstLabel" is empty');
  }
  return options;
}

Element? _selectByFirstLabel(Document document, String firstLabel) {
  for (final select in document.querySelectorAll('select')) {
    final first = select.querySelector('option');
    if (first != null && cleanText(first) == firstLabel) return select;
  }
  return null;
}

TipoEvento _tipoEvento(Element option) {
  final level = _levelClass.firstMatch(option.attributes['class'] ?? '');
  return TipoEvento(
    cid: option.attributes['value']!,
    nome: _label(option),
    gruppo: level != null,
    livello: level == null ? null : int.parse(level[1]!),
  );
}

String _label(Element option) =>
    cleanText(option).replaceFirst(_labelPrefix, '');
