// Generates the offline fallback menu assets/menu/menu.json (D-03) from a page
// captured by tool/capture_fixtures.sh.
//
// Usage: dart run tool/generate_menu.dart
import 'dart:convert';
import 'dart:io';

import 'package:eventi_bc/parsing/parse_menu.dart';

const _source = 'tool/fixtures_raw/events_all_1.html';
const _target = 'assets/menu/menu.json';

void main() {
  final sourceFile = File(_source);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing $_source. Run tool/capture_fixtures.sh first.');
    exitCode = 1;
    return;
  }

  final menu = parseMenu(sourceFile.readAsStringSync());
  final captured = sourceFile.lastModifiedSync().toIso8601String().substring(
    0,
    10,
  );
  final json = {'catturatoIl': captured, ...menu.toJson()};

  File(
    _target,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln(
    '$_target: ${menu.regioni.length} regioni, ${menu.tipi.length} tipi',
  );
}
