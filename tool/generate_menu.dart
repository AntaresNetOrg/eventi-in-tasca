// Generates the offline fallback menu assets/menu/menu.json (D-03) from a page
// captured by tool/capture_fixtures.sh.
//
// Usage: dart run tool/generate_menu.dart
import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;

const _source = 'tool/fixtures_raw/events_all_1.html';
const _target = 'assets/menu/menu.json';

/// Decorations that the site puts before a menu label: `- `, `--- `, `----> `.
final _labelPrefix = RegExp(r'^-+>?\s*');

/// Group entries carry a `LevelN` class (`Level0LC`, `Level1`, `Level2`...).
final _levelClass = RegExp(r'^Level(\d)');

void main() {
  final sourceFile = File(_source);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing $_source. Run tool/capture_fixtures.sh first.');
    exitCode = 1;
    return;
  }

  final document = html_parser.parse(sourceFile.readAsStringSync());

  List<Map<String, Object?>> options(
    String selectId,
    Map<String, Object?> Function(String value, String label, String cssClass)
    build,
  ) {
    final select = document.querySelector('select#$selectId');
    if (select == null) {
      throw StateError('select#$selectId not found in $_source');
    }
    return [
      for (final option in select.querySelectorAll('option'))
        if ((option.attributes['value'] ?? '').isNotEmpty)
          build(
            option.attributes['value']!,
            option.text.trim().replaceFirst(_labelPrefix, ''),
            option.attributes['class'] ?? '',
          ),
    ];
  }

  final captured = sourceFile.lastModifiedSync().toIso8601String().substring(
    0,
    10,
  );
  final menu = {
    'catturatoIl': captured,
    'regioni': options(
      'MainContent_ddlRegion',
      (value, label, _) => {'rid': value, 'nome': label},
    ),
    'tipi': options('MainContent_ddlCategory', (value, label, cssClass) {
      final level = _levelClass.firstMatch(cssClass)?.group(1);
      return {
        'cid': value,
        'nome': label,
        'gruppo': level != null,
        if (level != null) 'livello': int.parse(level),
      };
    }),
  };

  File(
    _target,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(menu)}\n');
  stdout.writeln(
    '$_target: ${(menu['regioni']! as List).length} regioni, '
    '${(menu['tipi']! as List).length} tipi',
  );
}
