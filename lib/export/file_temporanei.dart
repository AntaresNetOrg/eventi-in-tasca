import 'dart:io';

/// The only files the app writes (D-00b): the PDF and Excel to share, in a
/// folder of their own inside the temporary directory.
///
/// The folder is emptied at every start and before every new export, so at
/// most the files of the last share remain. They are not deleted as soon as
/// the share sheet closes: on Android the receiving app may read the file
/// after that (inference, not verified).
class FileTemporanei {
  FileTemporanei(this._radice);

  /// The temporary directory of the app (`getTemporaryDirectory`).
  final Future<Directory> Function() _radice;

  static const nomeCartella = 'condivisione';

  Future<Directory> cartella() async =>
      Directory('${(await _radice()).path}/$nomeCartella');

  Future<void> svuota() async {
    final dir = await cartella();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<File> scrivi(String nome, List<int> bytes) async {
    final dir = await cartella();
    await dir.create(recursive: true);
    return File('${dir.path}/$nome').writeAsBytes(bytes, flush: true);
  }
}
