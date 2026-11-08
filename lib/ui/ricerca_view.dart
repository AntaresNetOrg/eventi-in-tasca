import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/menu_eventi.dart';
import 'estrazione_controller.dart';
import 'filtri.dart';
import 'providers.dart';

/// Search screen (§4.1): type, region, options, formats, "Estrai".
class RicercaView extends ConsumerWidget {
  const RicercaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuProvider);
    return menu.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Lettura dei tipi di evento da BuonaCaccia…'),
          ],
        ),
      ),
      // The fallback menu is bundled, so this happens only if it is broken.
      error: (_, _) => _Messaggio(
        testo: 'Impossibile leggere l\'elenco dei tipi di evento.',
        azione: 'Riprova',
        onAzione: () => ref.invalidate(menuProvider),
      ),
      data: (caricato) =>
          _Modulo(menu: caricato.menu, daRiserva: caricato.daRiserva),
    );
  }
}

class _Modulo extends ConsumerWidget {
  const _Modulo({required this.menu, required this.daRiserva});

  final MenuEventi menu;
  final bool daRiserva;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtri = ref.watch(filtriProvider);
    final stato = ref.watch(estrazioneControllerProvider);
    final occupato = stato is CercaEventi || stato is EstraiDettagli;
    final tipi = _conRientro(menu.tipi);

    String? nomeTipo(String? cid) {
      for (final t in menu.tipi) {
        if (t.cid == cid) return t.nome;
      }
      return null;
    }

    String? nomeRegione(String? rid) {
      for (final r in menu.regioni) {
        if (r.rid == rid) return r.nome;
      }
      return null;
    }

    final estrai = Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        icon: const Icon(Icons.search),
        label: const Text('Estrai'),
        onPressed: occupato || filtri.cid == null
            ? null
            : () => ref
                  .read(estrazioneControllerProvider.notifier)
                  .avvia(
                    filtri: filtri,
                    tipo: nomeTipo(filtri.cid) ?? filtri.cid!,
                    regione: nomeRegione(filtri.rid),
                  ),
      ),
    );

    // "Estrai" stays visible below the scrolling options.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _opzioni(context, ref, filtri, occupato, tipi)),
        const Divider(height: 1),
        estrai,
      ],
    );
  }

  Widget _opzioni(
    BuildContext context,
    WidgetRef ref,
    Filtri filtri,
    bool occupato,
    List<(TipoEvento, int)> tipi,
  ) {
    final notifier = ref.read(filtriProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (daRiserva)
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.cloud_off),
              title: const Text(
                'BuonaCaccia non è raggiungibile: uso l\'elenco dei tipi '
                'incluso nell\'app, che potrebbe non essere aggiornato.',
              ),
              trailing: TextButton(
                onPressed: () => ref.invalidate(menuProvider),
                child: const Text('Riprova'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('tipo'),
          initialValue: filtri.cid,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tipo di evento',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Scegli il tipo di evento'),
          items: [
            for (final (tipo, rientro) in tipi)
              DropdownMenuItem(
                value: tipo.cid,
                child: Padding(
                  padding: EdgeInsets.only(left: 16.0 * rientro),
                  child: Text(
                    tipo.nome,
                    overflow: TextOverflow.ellipsis,
                    style: tipo.gruppo
                        ? const TextStyle(fontWeight: FontWeight.w600)
                        : null,
                  ),
                ),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final (tipo, _) in tipi)
              Text(tipo.nome, overflow: TextOverflow.ellipsis),
          ],
          onChanged: occupato
              ? null
              : (cid) {
                  if (cid != null) notifier.tipo(cid);
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          key: const Key('regione'),
          initialValue: filtri.rid,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Regione',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tutte le regioni'),
            ),
            for (final regione in menu.regioni)
              DropdownMenuItem<String?>(
                value: regione.rid,
                child: Text(regione.nome),
              ),
          ],
          onChanged: occupato ? null : notifier.regione,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Solo iscrizioni aperte o da aprire'),
          value: filtri.soloAperte,
          onChanged: occupato ? null : notifier.soloAperte,
        ),
        SwitchListTile(
          title: const Text('Estrai dettagli'),
          subtitle: const Text(
            'Capi campo, periodo di iscrizione, informazioni dalla segreteria: '
            'apre la pagina di ogni evento, quindi richiede più tempo.',
          ),
          value: filtri.dettagli,
          onChanged: occupato ? null : notifier.dettagli,
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Formati da condividere',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        CheckboxListTile(
          title: const Text('PDF'),
          value: filtri.pdf,
          onChanged: occupato ? null : (v) => notifier.pdf(v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Excel'),
          value: filtri.excel,
          onChanged: occupato ? null : (v) => notifier.excel(v ?? false),
        ),
      ],
    );
  }
}

/// Menu entries with their indentation: groups by their `LevelN`, leaves one
/// step below the group before them.
List<(TipoEvento, int)> _conRientro(List<TipoEvento> tipi) {
  var livelloGruppo = -1;
  return [
    for (final tipo in tipi)
      if (tipo.gruppo)
        (tipo, livelloGruppo = tipo.livello ?? 0)
      else
        (tipo, livelloGruppo + 1),
  ];
}

class _Messaggio extends StatelessWidget {
  const _Messaggio({
    required this.testo,
    required this.azione,
    required this.onAzione,
  });

  final String testo;
  final String azione;
  final VoidCallback onAzione;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(testo, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAzione, child: Text(azione)),
        ],
      ),
    ),
  );
}
