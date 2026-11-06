// Produces test/fixtures/ from the raw pages in tool/fixtures_raw/ (D-05).
//
// Usage: dart run tool/anonymize_fixtures.dart
//
// Works on the raw text instead of a parsed DOM, so that everything not
// explicitly replaced stays byte-identical (structure, ids, classes, icons,
// `title` attributes, line endings).
//
// Free text can also hold names that this script cannot recognize, such as
// speakers mentioned in "Informazioni dalla segreteria". Pages with such text
// are left out of [fixtureNames], and every fixture must still be checked by
// hand before committing it (see test/fixtures/README.md).
import 'dart:io';

/// Raw pages to publish as fixtures; test/fixtures/README.md explains each one.
const fixtureNames = [
  'events_all_1',
  'events_lazio_po',
  'event_26719',
  'event_26870',
  'event_26533',
  'event_26575',
  'event_26698',
  'event_26886',
  'event_26678',
  'event_26770',
  'event_26748',
];

const replacementEmail = 'anonimo@example.org';

const _fictitiousOwners = [
  'CAPO UNO',
  'CAPO DUE',
  'CAPO TRE',
  'CAPO QUATTRO',
  'CAPO CINQUE',
  'CAPO SEI',
  'CAPO SETTE',
  'CAPO OTTO',
];

const _ownerSeparator = ' - ';

final _ownersPattern = RegExp(
  r'(id="MainContent_EventFormView_lbOwners"[^>]*>)([^<]*)(<)',
);
final _hiddenValuePattern = RegExp(
  r'(<input\b(?=[^>]*\btype="hidden")[^>]*\bvalue=")[^"]*(")',
);
final _emailPattern = RegExp(
  r'[A-Za-z0-9._+-]+@([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)',
);
final _institutionalDomain = RegExp(
  r'^(?:[a-z0-9-]+\.)?agesci\.it$',
  caseSensitive: false,
);

/// Returns [html] without capi campo names, non-institutional email addresses
/// and hidden field values.
String anonymize(String html) {
  var result = html.replaceAllMapped(
    _hiddenValuePattern,
    (m) => '${m[1]}${m[2]}',
  );

  final realToFictitious = <String, String>{};
  result = result.replaceAllMapped(_ownersPattern, (m) {
    final names = m[2]!
        .split(_ownerSeparator)
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final fictitious = [
      for (var i = 0; i < names.length; i++) _fictitiousOwner(i),
    ];
    for (var i = 0; i < names.length; i++) {
      realToFictitious[names[i]] = fictitious[i];
    }
    return '${m[1]}${fictitious.join(_ownerSeparator)}${m[3]}';
  });

  // The same names may be repeated elsewhere in the page.
  realToFictitious.forEach((real, fictitious) {
    result = result.replaceAll(
      RegExp(
        '(?<!\\p{L})${RegExp.escape(real)}(?!\\p{L})',
        caseSensitive: false,
        unicode: true,
      ),
      fictitious,
    );
  });

  return result.replaceAllMapped(
    _emailPattern,
    (m) => _institutionalDomain.hasMatch(m[1]!) ? m[0]! : replacementEmail,
  );
}

String _fictitiousOwner(int index) => index < _fictitiousOwners.length
    ? _fictitiousOwners[index]
    : 'CAPO ${index + 1}';

void main() {
  const rawDir = 'tool/fixtures_raw';
  const outDir = 'test/fixtures';

  final missing = [
    for (final name in fixtureNames)
      if (!File('$rawDir/$name.html').existsSync()) name,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln(
      'Missing raw pages: ${missing.join(', ')}. '
      'Run tool/capture_fixtures.sh first.',
    );
    exitCode = 1;
    return;
  }

  for (final name in fixtureNames) {
    final raw = File('$rawDir/$name.html').readAsStringSync();
    File('$outDir/$name.html').writeAsStringSync(anonymize(raw));
    stdout.writeln('$rawDir/$name.html -> $outDir/$name.html');
  }
  stdout.writeln('Check every fixture by hand before committing it.');
}
