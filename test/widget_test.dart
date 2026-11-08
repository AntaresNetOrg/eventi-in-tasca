import 'dart:convert';
import 'dart:io';

import 'package:eventi_bc/data/bc_client.dart';
import 'package:eventi_bc/data/estrazione.dart';
import 'package:eventi_bc/data/request_scheduler.dart';
import 'package:eventi_bc/export/file_temporanei.dart';
import 'package:eventi_bc/ui/app.dart';
import 'package:eventi_bc/ui/condivisione.dart';
import 'package:eventi_bc/ui/providers.dart';
import 'package:eventi_bc/ui/testi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _page(String name) => http.Response.bytes(
  utf8.encode(File('test/fixtures/$name.html').readAsStringSync()),
  200,
);

/// A fake BuonaCaccia built on the fixtures: the Lazio list for searches with
/// a region, the full list otherwise, and only the page of event 26719 (the
/// other events redirect to the list, as missing events do).
Future<http.Response> _sito(http.Request request) async {
  final query = request.url.queryParameters;
  if (request.url.path == '/Events.aspx') {
    if (query.isEmpty || query.containsKey('RID')) {
      return _page('events_lazio_po');
    }
    return _page('events_all_1');
  }
  if (query['e'] == '26719') return _page('event_26719');
  return http.Response('', 302, headers: {'location': '/Events.aspx'});
}

Future<http.Response> _offline(http.Request request) async =>
    throw http.ClientException('offline', request.url);

Future<void> _avvia(
  WidgetTester tester, {
  MockClientHandler sito = _sito,
  Size size = const Size(400, 800),
  List<Override> altri = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final estrazione = Estrazione(
    BcClient(
      client: MockClient(sito),
      scheduler: RequestScheduler(pausa: Duration.zero),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        estrazioneProvider.overrideWith((ref) => estrazione),
        ...altri,
      ],
      child: const EventiInTascaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chiudiAvviso(WidgetTester tester) async {
  await tester.tap(find.text('Ho capito'));
  await tester.pumpAndSettle();
}

Future<void> _scegli(WidgetTester tester, String campo, String voce) async {
  await tester.tap(find.byKey(Key(campo)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(voce).last);
  await tester.pumpAndSettle();
}

Future<void> _estrai(WidgetTester tester) async {
  await tester.tap(find.text('Estrai'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the "unofficial app" notice is shown at start', (tester) async {
    await _avvia(tester);

    expect(find.text('App non ufficiale'), findsOneWidget);
    expect(find.text(Testi.nonUfficiale), findsOneWidget);

    await _chiudiAvviso(tester);
    expect(find.text('Tipo di evento'), findsOneWidget);
  });

  testWidgets('"Estrai" needs an event type', (tester) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);

    final estrai = find.widgetWithText(FilledButton, 'Estrai');
    expect(tester.widget<FilledButton>(estrai).onPressed, isNull);

    await _scegli(tester, 'tipo', 'Piccole Orme');
    expect(tester.widget<FilledButton>(estrai).onPressed, isNotNull);
  });

  testWidgets('at least one format stays selected', (tester) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);

    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    final pdf = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'PDF'),
    );
    expect(pdf.value, isTrue);
  });

  testWidgets('searches and shows the events sorted by date', (tester) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);
    await _scegli(tester, 'tipo', 'Piccole Orme');
    await _scegli(tester, 'regione', 'Lazio');

    await _estrai(tester);

    expect(find.text('Piccole Orme'), findsOneWidget);
    expect(find.textContaining('Lazio · 9 eventi'), findsOneWidget);
    // 05/12 comes before 27/12 and 03/01/2027.
    final primo = tester.getTopLeft(
      find.text('Piccole Orme - Dicembre 1 - Quadriennale'),
    );
    final dopo = tester.getTopLeft(
      find.text('Piccole Orme - Dicembre 3 - Quadriennale'),
    );
    expect(primo.dy, lessThan(dopo.dy));
    expect(find.text('In esaurimento'), findsOneWidget);
  });

  testWidgets('"back" from the results returns to the search', (tester) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);
    await _scegli(tester, 'tipo', 'Piccole Orme');
    await _estrai(tester);

    await tester.tap(find.byTooltip('Nuova ricerca'));
    await tester.pumpAndSettle();

    expect(find.text('Tipo di evento'), findsOneWidget);
  });

  testWidgets('details: anomalies are flagged and readable', (tester) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);
    await _scegli(tester, 'tipo', 'Piccole Orme');
    await _scegli(tester, 'regione', 'Lazio');
    await tester.tap(find.text('Estrai dettagli'));
    await tester.pumpAndSettle();

    await _estrai(tester);

    // Only 26719 has a page in the fake site; the other 8 report it.
    expect(find.text('8 eventi con dati da controllare'), findsOneWidget);

    await tester.tap(find.text('Piccole Orme - Dicembre 1 - Quadriennale'));
    await tester.pumpAndSettle();
    final scheda = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('CAPO UNO, CAPO DUE'),
      100,
      scrollable: scheda.first,
    );
    expect(find.text('Capi campo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Apri su BuonaCaccia'),
      100,
      scrollable: scheda.first,
    );
    expect(find.text('Apri su BuonaCaccia'), findsOneWidget);
  });

  testWidgets('more than 50 events: confirm before the details', (
    tester,
  ) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);
    await _scegli(tester, 'tipo', 'Piccole Orme');
    await tester.tap(find.text('Estrai dettagli'));
    await tester.pumpAndSettle();

    await _estrai(tester);

    expect(find.text('Estrarre i dettagli di 298 eventi?'), findsOneWidget);
    await tester.tap(find.text('Solo elenco'));
    await tester.pumpAndSettle();

    expect(find.textContaining('298 eventi'), findsOneWidget);
    expect(find.textContaining('con dati da controllare'), findsNothing);
  });

  testWidgets('the confirmation can be cancelled', (tester) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);
    await _scegli(tester, 'tipo', 'Piccole Orme');
    await tester.tap(find.text('Estrai dettagli'));
    await tester.pumpAndSettle();
    await _estrai(tester);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(find.text('Tipo di evento'), findsOneWidget);
  });

  testWidgets('offline: bundled menu and a clear error', (tester) async {
    await _avvia(tester, sito: _offline);
    await _chiudiAvviso(tester);

    expect(
      find.textContaining('BuonaCaccia non è raggiungibile'),
      findsOneWidget,
    );

    await _scegli(tester, 'tipo', 'Piccole Orme');
    await _estrai(tester);

    expect(
      find.textContaining('Impossibile raggiungere BuonaCaccia'),
      findsOneWidget,
    );
    await tester.tap(find.text('Torna alla ricerca'));
    await tester.pumpAndSettle();
    expect(find.text('Tipo di evento'), findsOneWidget);
  });

  testWidgets('tablet: search and results side by side', (tester) async {
    await _avvia(tester, size: const Size(1400, 900));
    await _chiudiAvviso(tester);

    expect(find.text('Tipo di evento'), findsOneWidget);
    expect(find.textContaining('premi “Estrai”'), findsOneWidget);

    await _scegli(tester, 'tipo', 'Piccole Orme');
    await _estrai(tester);

    // Without a region the fake site returns the full list.
    expect(find.text('Tipo di evento'), findsOneWidget);
    expect(find.textContaining('298 eventi'), findsOneWidget);
  });

  testWidgets('"Condividi" shares the files of the chosen formats', (
    tester,
  ) async {
    final condivisi = <String>[];
    final radice = Directory.systemTemp.createTempSync('eventi_bc');
    addTearDown(() => radice.deleteSync(recursive: true));

    await _avvia(
      tester,
      altri: [
        fileTemporaneiProvider.overrideWith(
          (ref) => FileTemporanei(() async => radice),
        ),
        condividiProvider.overrideWith(
          (ref) => (files, {required oggetto, required testo, origine}) async {
            condivisi.addAll(files.map((f) => f.uri.pathSegments.last));
          },
        ),
      ],
    );
    await _chiudiAvviso(tester);
    await _scegli(tester, 'tipo', 'Piccole Orme');
    await _scegli(tester, 'regione', 'Lazio');
    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    await _estrai(tester);

    // Writing files and fonts needs real asynchronous I/O.
    await tester.runAsync(() async {
      await tester.tap(find.text('Condividi'));
      for (var i = 0; i < 100 && condivisi.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    expect(condivisi, hasLength(2));
    expect(condivisi.first, startsWith('eventi_piccole-orme_lazio_'));
    expect(condivisi.first, endsWith('.pdf'));
    expect(condivisi.last, endsWith('.xlsx'));
    expect(find.text('Condividi'), findsOneWidget);
  });

  testWidgets('"Informazioni" states that the app is unofficial', (
    tester,
  ) async {
    await _avvia(tester);
    await _chiudiAvviso(tester);

    await tester.tap(find.byTooltip('Informazioni'));
    await tester.pumpAndSettle();

    expect(find.text(Testi.nonUfficiale), findsOneWidget);
    await tester.scrollUntilVisible(find.text(repositoryUrl), 100);
    expect(find.text(repositoryUrl), findsOneWidget);
  });
}
