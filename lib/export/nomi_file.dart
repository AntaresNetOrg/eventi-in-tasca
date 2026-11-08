import '../domain/risultato.dart';

const _accentate = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
};

final _separatori = RegExp(r'[^a-z0-9]+');

/// Lowercase ASCII with dashes: `Specialità E/G` → `specialita-e-g`.
String slug(String testo) {
  final buffer = StringBuffer();
  for (final c in testo.toLowerCase().split('')) {
    buffer.write(_accentate[c] ?? c);
  }
  return buffer
      .toString()
      .replaceAll(_separatori, '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _due(int n) => n.toString().padLeft(2, '0');

/// `eventi_<tipo>_<regione>_<aaaammgg>` (§5), without extension.
String nomeFile(Risultato risultato) {
  final r = risultato.ricerca;
  final d = risultato.estrattoIl;
  final regione = slug(r.regione ?? 'tutte le regioni');
  return 'eventi_${slug(r.tipo)}_${regione}_'
      '${d.year}${_due(d.month)}${_due(d.day)}';
}
