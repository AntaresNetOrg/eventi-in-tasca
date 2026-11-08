import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'export/file_temporanei.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Files shared in a previous session are removed at every start (D-00b).
  unawaited(
    FileTemporanei(getTemporaryDirectory).svuota().catchError((Object _) {}),
  );
  runApp(
    ProviderScope(
      // No automatic retries: every request to BuonaCaccia starts from a user
      // action (D-04).
      retry: (_, _) => null,
      child: const EventiInTascaApp(),
    ),
  );
}
