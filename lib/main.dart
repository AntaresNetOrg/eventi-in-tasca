import 'package:flutter/material.dart';

void main() {
  runApp(const EventiBcApp());
}

/// Minimal app shell (phase F0). The title is provisional until the final
/// name is chosen (V-07).
class EventiBcApp extends StatelessWidget {
  const EventiBcApp({super.key});

  static const String titoloProvvisorio = 'eventi_bc';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: titoloProvvisorio,
      theme: ThemeData(fontFamily: 'TitilliumWeb'),
      home: Scaffold(appBar: AppBar(title: const Text(titoloProvvisorio))),
    );
  }
}
