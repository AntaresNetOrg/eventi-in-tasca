import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/formati.dart';
import 'estrazione_controller.dart';
import 'informazioni_screen.dart';
import 'risultati_view.dart';
import 'ricerca_view.dart';
import 'testi.dart';

/// Width from which search and results are shown side by side (tablet).
const larghezzaAffiancata = 840.0;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Shown at every start: nothing is stored, so it cannot be remembered
    // (P-13).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mostraAvviso();
    });
  }

  Future<void> _mostraAvviso() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('App non ufficiale'),
      content: const Text(Testi.nonUfficiale),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ho capito'),
        ),
      ],
    ),
  );

  Future<void> _chiediConferma(int eventi) async {
    final controller = ref.read(estrazioneControllerProvider.notifier);
    final scelta = await showDialog<_SceltaDettagli>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Estrarre i dettagli di $eventi eventi?'),
        content: Text(
          'L\'app aprirà la pagina di ogni evento su BuonaCaccia, poche '
          'alla volta per non sovraccaricare il sito: servirà '
          '${stimaDurata(eventi)}. Potrai annullare in qualsiasi momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_SceltaDettagli.annulla),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_SceltaDettagli.soloElenco),
            child: const Text('Solo elenco'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_SceltaDettagli.estrai),
            child: const Text('Estrai dettagli'),
          ),
        ],
      ),
    );
    switch (scelta) {
      case _SceltaDettagli.estrai:
        await controller.confermaDettagli();
      case _SceltaDettagli.soloElenco:
        controller.soloElenco();
      case _SceltaDettagli.annulla || null:
        controller.annulla();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(estrazioneControllerProvider, (_, stato) {
      if (stato is ConfermaDettagli) _chiediConferma(stato.eventi);
    });
    final stato = ref.watch(estrazioneControllerProvider);
    final controller = ref.read(estrazioneControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final affiancata = constraints.maxWidth >= larghezzaAffiancata;
        final mostraRicerca = affiancata || stato is Inattivo;

        return PopScope(
          // On the phone, "back" from the results returns to the search.
          canPop: mostraRicerca,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.nuovaRicerca();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text(Testi.nomeApp),
              leading: mostraRicerca
                  ? null
                  : IconButton(
                      tooltip: 'Nuova ricerca',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: controller.nuovaRicerca,
                    ),
              actions: [
                IconButton(
                  tooltip: 'Informazioni',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InformazioniScreen(),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: affiancata
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(width: 400, child: RicercaView()),
                        const VerticalDivider(width: 1),
                        Expanded(child: RisultatiPanel(stato: stato)),
                      ],
                    )
                  : stato is Inattivo
                  ? const RicercaView()
                  : RisultatiPanel(stato: stato),
            ),
          ),
        );
      },
    );
  }
}

enum _SceltaDettagli { estrai, soloElenco, annulla }
