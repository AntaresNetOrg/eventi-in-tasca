import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/anonymize_fixtures.dart';

void main() {
  group('anonymize', () {
    test('replaces the capi campo, also where they are repeated', () {
      const html =
          '<span id="MainContent_EventFormView_lbOwners" style="x">'
          'MARIO ROSSI - ANNA VERDI</span><p>Referente: Mario Rossi</p>';

      expect(
        anonymize(html),
        '<span id="MainContent_EventFormView_lbOwners" style="x">'
        'CAPO UNO - CAPO DUE</span><p>Referente: CAPO UNO</p>',
      );
    });

    test('keeps institutional email addresses only', () {
      const html =
          'eventi@agesci.it eventi@lazio.agesci.it '
          'mario@gmail.com info@agesciliguria.it';

      expect(
        anonymize(html),
        'eventi@agesci.it eventi@lazio.agesci.it '
        '$replacementEmail $replacementEmail',
      );
    });

    test('keeps the trailing %0d%0a of a mailto link', () {
      expect(
        anonymize('href="mailto:mario@gmail.com%0d%0a"'),
        'href="mailto:$replacementEmail%0d%0a"',
      );
    });

    test('empties the hidden field values', () {
      expect(
        anonymize(
          '<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" '
          'value="abc+/=" />',
        ),
        '<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="" />',
      );
    });

    test('leaves everything else untouched', () {
      const html = '<a title="Titolo\rSottotitolo" href="Event.aspx?e=1">x</a>';

      expect(anonymize(html), html);
    });
  });

  group('committed fixtures', () {
    final fixtures =
        Directory('test/fixtures')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.html'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('match the published list', () {
      expect(fixtures.map((file) => file.uri.pathSegments.last).toSet(), {
        for (final name in fixtureNames) '$name.html',
      });
    });

    for (final file in fixtures) {
      final name = file.uri.pathSegments.last;
      final html = file.readAsStringSync();

      test('$name is stable under anonymization', () {
        // Owners are already fictitious, so a second pass changes nothing.
        expect(anonymize(html), html);
      });

      test('$name has fictitious capi campo only', () {
        final owners = RegExp(r'lbOwners"[^>]*>([^<]*)<')
            .allMatches(html)
            .map((m) => m[1]!);
        for (final value in owners) {
          expect(value, matches(RegExp(r'^CAPO \w+( - CAPO \w+)*$')));
        }
      });

      test('$name has no phone numbers or IBANs', () {
        expect(
          html,
          isNot(contains(RegExp(r'\b3\d{2}[ .-]?\d{3}[ .-]?\d{3,4}\b'))),
        );
        expect(html, isNot(contains(RegExp(r'\bIT\d{2}[A-Z]\d{10}'))));
      });
    }
  });

  test('the fallback menu comes from the site structure', () {
    final menu = jsonDecode(
      File('assets/menu/menu.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final regioni = (menu['regioni'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final tipi = (menu['tipi'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(regioni, contains(equals({'rid': 'H', 'nome': 'Lazio'})));
    expect(regioni, contains(equals({'rid': 'A', 'nome': 'Nazionale'})));
    expect(
      tipi,
      contains(
        equals({'cid': '1010101', 'nome': 'Piccole Orme', 'gruppo': false}),
      ),
    );
    expect(
      tipi,
      contains(
        equals({'cid': '1000000', 'nome': 'L/C', 'gruppo': true, 'livello': 0}),
      ),
    );
  });
}
