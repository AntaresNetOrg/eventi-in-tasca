/// The site could not be reached or answered with an error.
///
/// [message] is in Italian and can be shown to the user.
class BcNetworkException implements Exception {
  const BcNetworkException(this.message);

  final String message;

  @override
  String toString() => 'BcNetworkException: $message';
}

/// The event page no longer exists: the site redirects to the event list.
class EventoNonDisponibileException implements Exception {
  const EventoNonDisponibileException(this.id);

  final int id;

  @override
  String toString() => 'EventoNonDisponibileException: $id';
}

/// The user cancelled the extraction.
class EstrazioneAnnullataException implements Exception {
  const EstrazioneAnnullataException();

  @override
  String toString() => 'EstrazioneAnnullataException';
}
