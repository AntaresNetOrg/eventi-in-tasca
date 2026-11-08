import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'testi.dart';

/// Colours of the app icon (D-13).
abstract final class Colori {
  static const verdeScuro = Color(0xFF1E4A30);
  static const verde = Color(0xFF2F6B45);
  static const giallo = Color(0xFFF2B33D);
  static const rosso = Color(0xFFE8573C);
}

class EventiInTascaApp extends StatelessWidget {
  const EventiInTascaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colori.verde,
      primary: Colori.verde,
      secondary: Colori.giallo,
    );
    return MaterialApp(
      title: Testi.nomeApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        fontFamily: 'TitilliumWeb',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colori.verdeScuro,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
