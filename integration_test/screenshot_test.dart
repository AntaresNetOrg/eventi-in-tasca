// Store screenshots (F7, docs/Pubblicazione.md §4). Not a unit test: it runs the
// real app on a device or simulator and makes one GET to Events.aspx (D-00b).
//
//   SCREENSHOT_DIR=docs/store/screenshot/iphone \
//     flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart -d <device>
import 'dart:io';

import 'package:eventi_bc/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Android needs the Flutter surface converted to an image, once only.
  var convertita = false;
  Future<void> scatta(WidgetTester tester, String nome) async {
    if (Platform.isAndroid && !convertita) {
      await binding.convertFlutterSurfaceToImage();
      convertita = true;
      await tester.pump();
    }
    await binding.takeScreenshot(nome);
  }

  /// Pumps until [finder] appears: the search waits on the network, which
  /// pumpAndSettle cannot see while the progress indicator keeps animating.
  Future<void> attendi(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'store screenshots',
    timeout: const Timeout(Duration(minutes: 2)),
    (tester) async {
      app.main();
      await attendi(tester, find.text('Ho capito'));
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tipo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piccole Orme').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excel'));
      await tester.pumpAndSettle();
      await scatta(tester, '1_ricerca');

      await tester.tap(find.text('Estrai'));
      await attendi(tester, find.text('Condividi'));
      await scatta(tester, '2_risultati');

      await tester.tap(find.textContaining('Piccole Orme - ').first);
      await tester.pumpAndSettle();
      await scatta(tester, '3_evento');

      // Last, so no back navigation is needed: the event sheet covers the app bar
      // on phones, hence the tap on the barrier first.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Informazioni'));
      await tester.pumpAndSettle();
      await scatta(tester, '4_informazioni');
    },
  );
}
