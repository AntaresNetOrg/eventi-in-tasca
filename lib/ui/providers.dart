import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bc_client.dart';
import '../data/estrazione.dart';

/// The only HTTP client of the app, so all requests share the limits of D-04.
final bcClientProvider = Provider<BcClient>((ref) {
  final client = BcClient();
  ref.onDispose(client.close);
  return client;
});

final estrazioneProvider = Provider<Estrazione>(
  (ref) => Estrazione(ref.watch(bcClientProvider)),
);

const menuAsset = 'assets/menu/menu.json';

/// Search menus: from the site at startup, or the bundled fallback (D-03).
final menuProvider = FutureProvider<MenuCaricato>(
  (ref) => ref
      .watch(estrazioneProvider)
      .caricaMenu(riserva: () => rootBundle.loadString(menuAsset)),
);
