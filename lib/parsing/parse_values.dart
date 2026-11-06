import 'package:html/dom.dart';

final _datePattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
final _feePattern = RegExp(r'^(\d+),(\d{2}) €$');

/// The text of [element], with non-breaking spaces normalized and trimmed.
String cleanText(Element element) => element.text.replaceAll(' ', ' ').trim();

/// Parses `gg/mm/aaaa`; null if the format is wrong or the date does not exist.
DateTime? parseDate(String text) {
  final match = _datePattern.firstMatch(text);
  if (match == null) return null;
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final year = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  // DateTime rolls invalid dates over: 31/02 would become 03/03.
  return date.day == day && date.month == month ? date : null;
}

/// Parses `N,NN €` into euro cents; null if the format is wrong.
int? parseFeeCents(String text) {
  final match = _feePattern.firstMatch(text);
  if (match == null) return null;
  return int.parse(match[1]!) * 100 + int.parse(match[2]!);
}
