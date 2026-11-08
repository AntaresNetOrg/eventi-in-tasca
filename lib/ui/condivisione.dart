import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/risultato.dart';
import '../export/esportazione.dart';
import '../export/file_temporanei.dart';
import '../export/pdf_esportazione.dart';

final fileTemporaneiProvider = Provider<FileTemporanei>(
  (ref) => FileTemporanei(getTemporaryDirectory),
);

Future<FontPdf> _fontDagliAsset() async => FontPdf.daByte(
  regolare: await rootBundle.load('assets/fonts/TitilliumWeb-Regular.ttf'),
  semiBold: await rootBundle.load('assets/fonts/TitilliumWeb-SemiBold.ttf'),
  grassetto: await rootBundle.load('assets/fonts/TitilliumWeb-Bold.ttf'),
  corsivo: await rootBundle.load('assets/fonts/TitilliumWeb-Italic.ttf'),
);

final esportazioneProvider = Provider<Esportazione>(
  (ref) => Esportazione(
    fileTemporanei: ref.watch(fileTemporaneiProvider),
    font: _fontDagliAsset,
  ),
);

/// Opens the share sheet of the system; replaced in the tests.
typedef Condividi = Future<void> Function(
  List<File> files, {
  required String oggetto,
  required String testo,
  Rect? origine,
});

Future<void> _condividiConSistema(
  List<File> files, {
  required String oggetto,
  required String testo,
  Rect? origine,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        for (final f in files)
          XFile(f.path, mimeType: f.path.endsWith('.pdf') ? mimePdf : mimeXlsx),
      ],
      subject: oggetto,
      text: testo,
      // Required on iPad, where the sheet is a popover.
      sharePositionOrigin: origine,
    ),
  );
}

final condividiProvider = Provider<Condividi>((ref) => _condividiConSistema);

/// The "Condividi" button of the results: writes the files and shares them.
class PulsanteCondividi extends ConsumerStatefulWidget {
  const PulsanteCondividi({super.key, required this.risultato});

  final Risultato risultato;

  @override
  ConsumerState<PulsanteCondividi> createState() => _PulsanteCondividiState();
}

class _PulsanteCondividiState extends ConsumerState<PulsanteCondividi> {
  bool _inCorso = false;

  Future<void> _condividi() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origine = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final ricerca = widget.risultato.ricerca;
    setState(() => _inCorso = true);
    try {
      final files = await ref.read(esportazioneProvider).crea(widget.risultato);
      await ref.read(condividiProvider)(
        files,
        oggetto:
            'Eventi BuonaCaccia: ${ricerca.tipo} – '
            '${ricerca.regione ?? 'tutte le regioni'}',
        testo:
            'Elenco degli eventi estratto da BuonaCaccia con Eventi in tasca, '
            'app non ufficiale. Per iscriversi e per i dati aggiornati usare '
            'buonacaccia.agesci.it.',
        origine: origine,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossibile preparare i file da condividere.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    icon: _inCorso
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.share),
    label: Text(_inCorso ? 'Preparazione…' : 'Condividi'),
    onPressed: _inCorso ? null : _condividi,
  );
}
