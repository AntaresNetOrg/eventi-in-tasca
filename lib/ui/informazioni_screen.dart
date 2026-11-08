import 'package:flutter/material.dart';

import '../data/bc_client.dart';
import 'apri_link.dart';
import 'testi.dart';

/// "Informazioni" (D-00): always reachable from the app bar.
class InformazioniScreen extends StatelessWidget {
  const InformazioniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    Widget titolo(String t) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(t, style: testo.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Informazioni')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(Testi.nomeApp, style: testo.headlineSmall),
            Text('Versione $appVersion', style: testo.bodySmall),
            titolo('App non ufficiale'),
            const Text(Testi.nonUfficiale),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apri BuonaCaccia'),
                onPressed: () =>
                    apriLink(context, Uri.parse(Testi.sitoBuonaCaccia)),
              ),
            ),
            titolo('Come funziona'),
            const Text(
              'L\'app legge solo le pagine pubbliche di BuonaCaccia con '
              'l\'elenco degli eventi e i singoli eventi, poche alla volta per '
              'non sovraccaricare il sito. Non accede ad aree riservate e non '
              'chiede credenziali.',
            ),
            titolo('Privacy'),
            const Text(
              'L\'app non raccoglie dati personali e non salva nulla sul '
              'dispositivo: il file da condividere è temporaneo. Nessuna '
              'analitica, nessun tracciamento, nessuna pubblicità.',
            ),
            titolo('Codice sorgente'),
            const Text('Software libero con licenza MIT © 2026 Andrea Bruno.'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => apriLink(context, Uri.parse(repositoryUrl)),
                child: const Text(repositoryUrl),
              ),
            ),
            const Text('Font Titillium Web, SIL Open Font License 1.1.'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: Testi.nomeApp,
                  applicationVersion: appVersion,
                ),
                child: const Text('Licenze dei componenti'),
              ),
            ),
            titolo('AGESCI e BuonaCaccia'),
            const Text(
              'AGESCI e BuonaCaccia sono dell\'Associazione Guide e Scouts '
              'Cattolici Italiani; questa app non è un prodotto ufficiale '
              'dell\'associazione.',
            ),
          ],
        ),
      ),
    );
  }
}
