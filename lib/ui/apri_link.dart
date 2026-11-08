import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside the app (browser or mail app), with a message if no
/// app can open it. `canLaunchUrl` is not used: it would need `<queries>` on
/// Android and `LSApplicationQueriesSchemes` on iOS.
Future<void> apriLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final aperto = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!aperto) {
    messenger.showSnackBar(
      SnackBar(content: Text('Impossibile aprire ${uri.toString()}')),
    );
  }
}
