import 'evento.dart';

/// Events by departure date, then by title (P-07); events without a valid
/// date go last. The input list is not modified.
List<Evento> ordinaEventi(Iterable<Evento> eventi) {
  final ordinati = eventi.toList();
  ordinati.sort((a, b) {
    final pa = a.partenza;
    final pb = b.partenza;
    if (pa != pb) {
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pa.compareTo(pb);
    }
    return a.titolo.toLowerCase().compareTo(b.titolo.toLowerCase());
  });
  return List.unmodifiable(ordinati);
}
