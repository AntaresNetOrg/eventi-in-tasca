import 'dart:convert';
import 'dart:io';

import 'package:eventi_bc/domain/menu_eventi.dart';
import 'package:eventi_bc/parsing/bc_page_format_exception.dart';
import 'package:eventi_bc/parsing/parse_menu.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.html').readAsStringSync();

void main() {
  final html = _fixture('events_lazio_po');

  test('reads all regions, without the "all" entry', () {
    final regioni = parseMenu(html).regioni;

    expect(regioni, hasLength(21));
    expect(regioni.first.rid, 'A');
    expect(regioni.first.nome, 'Nazionale');
    expect(regioni.map((r) => r.nome), contains("Valle d'Aosta"));
    expect(regioni.map((r) => r.nome), isNot(contains('Tutte le regioni')));
  });

  test('reads all event types, cleaning the labels', () {
    final tipi = parseMenu(html).tipi;

    expect(tipi, hasLength(85));
    expect(tipi.map((t) => t.nome), isNot(contains('Tutti gli eventi')));
    expect(tipi.where((t) => t.nome.startsWith('-')), isEmpty);
  });

  test('tells group entries from leaf entries', () {
    final tipi = {for (final t in parseMenu(html).tipi) t.cid: t};

    expect(tipi['1010101']!.nome, 'Piccole Orme');
    expect(tipi['1010101']!.gruppo, isFalse);
    expect(tipi['1010101']!.livello, isNull);

    expect(tipi['1000000']!.nome, 'L/C');
    expect(tipi['1000000']!.gruppo, isTrue);
    expect(tipi['1000000']!.livello, 0);

    expect(tipi['4010000']!.nome, 'Moduli Formativi');
    expect(tipi['4010000']!.livello, 1);

    expect(tipi['4000200']!.nome, 'CFM');
    expect(tipi['4000200']!.livello, 2);
  });

  test('decodes HTML entities', () {
    final tipi = {for (final t in parseMenu(html).tipi) t.cid: t};

    expect(tipi['2010101']!.nome, 'Specialità');
  });

  test('falls back on the first label when the ids change', () {
    final renamed = html
        .replaceAll('MainContent_ddlRegion', 'other_a')
        .replaceAll('MainContent_ddlCategory', 'other_b');

    final menu = parseMenu(renamed);

    expect(menu.regioni, hasLength(21));
    expect(menu.tipi, hasLength(85));
  });

  test('ignores the region selector of the navigation bar', () {
    // That selector has no "Nazionale" entry.
    expect(parseMenu(html).regioni.map((r) => r.rid), contains('A'));
  });

  test('fails on a page without menus', () {
    expect(
      () => parseMenu('<html><body></body></html>'),
      throwsA(isA<BcPageFormatException>()),
    );
  });

  test('the bundled fallback is what the parser reads from the page', () {
    final bundled = jsonDecode(
      File('assets/menu/menu.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final parsed = jsonDecode(jsonEncode(parseMenu(html).toJson()));

    expect(bundled['regioni'], parsed['regioni']);
    expect(bundled['tipi'], parsed['tipi']);
  });

  test('the bundled fallback can be loaded', () {
    final bundled = jsonDecode(
      File('assets/menu/menu.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final menu = MenuEventi.fromJson(bundled);

    expect(menu.regioni, hasLength(21));
    expect(menu.tipi, hasLength(85));
  });
}
