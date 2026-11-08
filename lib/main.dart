import 'package:flutter/material.dart';

void main() {
  runApp(const EventiBcApp());
}

/// Minimal app shell (phase F0); the screens come in F5.
class EventiBcApp extends StatelessWidget {
  const EventiBcApp({super.key});

  /// Name of the app (V-07).
  static const String titoloProvvisorio = 'Eventi in tasca';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: titoloProvvisorio,
      theme: ThemeData(fontFamily: 'TitilliumWeb'),
      home: Scaffold(appBar: AppBar(title: const Text(titoloProvvisorio))),
    );
  }
}
