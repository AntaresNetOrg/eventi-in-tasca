import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/app.dart';

void main() {
  runApp(
    ProviderScope(
      // No automatic retries: every request to BuonaCaccia starts from a user
      // action (D-04).
      retry: (_, _) => null,
      child: const EventiInTascaApp(),
    ),
  );
}
