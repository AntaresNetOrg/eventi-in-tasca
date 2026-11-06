/// The page does not have the expected structure, so nothing can be read from
/// it: most likely the site has changed. Single values out of format are not
/// errors: they become anomalies of their event (D-05).
class BcPageFormatException implements Exception {
  const BcPageFormatException(this.message);

  final String message;

  @override
  String toString() => 'BcPageFormatException: $message';
}
