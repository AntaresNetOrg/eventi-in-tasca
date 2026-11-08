import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evento.dart';
import '../domain/formati.dart';
import 'app.dart';
import 'condivisione.dart';
import 'estrazione_controller.dart';
import 'evento_sheet.dart';

/// The right side of the app: progress, results or error (§4.2, §4.3).
class RisultatiPanel extends ConsumerWidget {
  const RisultatiPanel({super.key, required this.stato});

  final StatoEstrazione stato;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(estrazioneControllerProvider.notifier);
    return switch (stato) {
      Inattivo() => const _Centro(
        child: Text(
          'Scegli il tipo di evento e premi “Estrai”.',
          textAlign: TextAlign.center,
        ),
      ),
      CercaEventi() => _Avanzamento(
        testo: 'Ricerca degli eventi su BuonaCaccia…',
        onAnnulla: controller.annulla,
      ),
      ConfermaDettagli(:final eventi) => _Centro(
        child: Text('Trovati $eventi eventi.', textAlign: TextAlign.center),
      ),
      EstraiDettagli(:final fatti, :final totale) => _Avanzamento(
        testo: 'Dettagli degli eventi: $fatti di $totale',
        valore: totale == 0 ? null : fatti / totale,
        onAnnulla: controller.annulla,
      ),
      Errore(:final messaggio) => _Centro(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(messaggio, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.nuovaRicerca,
              child: const Text('Torna alla ricerca'),
            ),
          ],
        ),
      ),
      Completata(:final risultato) => _Risultati(risultato: risultato),
    };
  }
}

class _Centro extends StatelessWidget {
  const _Centro({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  );
}

class _Avanzamento extends StatelessWidget {
  const _Avanzamento({
    required this.testo,
    required this.onAnnulla,
    this.valore,
  });

  final String testo;
  final VoidCallback onAnnulla;

  /// Null for an indeterminate bar.
  final double? valore;

  @override
  Widget build(BuildContext context) => _Centro(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(testo, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SizedBox(width: 280, child: LinearProgressIndicator(value: valore)),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: onAnnulla, child: const Text('Annulla')),
      ],
    ),
  );
}

class _Risultati extends StatelessWidget {
  const _Risultati({required this.risultato});

  final Risultato risultato;

  @override
  Widget build(BuildContext context) {
    final ricerca = risultato.ricerca;
    final eventi = risultato.eventi;
    final conAnomalie = risultato.eventiConAnomalie;
    final tutteLeRegioni = ricerca.regione == null;

    return Scaffold(
      floatingActionButton: eventi.isEmpty
          ? null
          : PulsanteCondividi(risultato: risultato),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: eventi.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Intestazione(
              risultato: risultato,
              conAnomalie: conAnomalie,
            );
          }
          final evento = eventi[index - 1];
          return _VoceEvento(evento: evento, mostraRegione: tutteLeRegioni);
        },
      ),
    );
  }
}

class _Intestazione extends StatelessWidget {
  const _Intestazione({required this.risultato, required this.conAnomalie});

  final Risultato risultato;
  final int conAnomalie;

  @override
  Widget build(BuildContext context) {
    final ricerca = risultato.ricerca;
    final testo = Theme.of(context).textTheme;
    final quanti = risultato.eventi.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ricerca.tipo, style: testo.titleLarge),
          Text(
            '${ricerca.regione ?? 'Tutte le regioni'} · '
            '${quanti == 1 ? '1 evento' : '$quanti eventi'}'
            '${ricerca.soloAperte ? ' con iscrizioni aperte o da aprire' : ''}',
            style: testo.bodyMedium,
          ),
          Text(
            'Dati estratti da BuonaCaccia il '
            '${formatDataOra(risultato.estrattoIl).replaceFirst(' ', ' alle ')}',
            style: testo.bodySmall,
          ),
          if (quanti == 0)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('Nessun evento corrisponde alla ricerca.'),
            ),
          if (conAnomalie > 0)
            Card(
              margin: const EdgeInsets.only(top: 12),
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text(
                  conAnomalie == 1
                      ? '1 evento con dati da controllare'
                      : '$conAnomalie eventi con dati da controllare',
                ),
                subtitle: const Text(
                  'Sono segnati con ⚠: toccali per leggere i dettagli.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VoceEvento extends StatelessWidget {
  const _VoceEvento({required this.evento, required this.mostraRegione});

  final Evento evento;
  final bool mostraRegione;

  @override
  Widget build(BuildContext context) {
    final righe = [
      formatPeriodo(evento.partenza, evento.rientro),
      formatLocalita(evento.localita),
      if (mostraRegione) evento.regione,
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: evento.anomalie.isEmpty
            ? null
            : Icon(
                Icons.warning_amber,
                color: Theme.of(context).colorScheme.error,
                semanticLabel: 'Dati da controllare',
              ),
        title: Text(evento.titolo),
        subtitle: Text(righe.join(' · ')),
        trailing: ChipStato(stato: evento.stato),
        onTap: () => mostraEvento(context, evento),
      ),
    );
  }
}

/// Coloured label of the enrollment state (D-09).
class ChipStato extends StatelessWidget {
  const ChipStato({super.key, required this.stato});

  final StatoIscrizioni? stato;

  @override
  Widget build(BuildContext context) {
    final (sfondo, testo) = switch (stato) {
      StatoIscrizioni.aperte => (Colori.verde, Colors.white),
      StatoIscrizioni.inEsaurimento => (Colori.giallo, Colors.black),
      StatoIscrizioni.listaAttesa => (const Color(0xFFF08C2E), Colors.black),
      StatoIscrizioni.chiuse => (Colori.rosso, Colors.white),
      null => (Colors.grey.shade300, Colors.black),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        etichettaStato(stato),
        style: TextStyle(color: testo, fontSize: 12),
      ),
    );
  }
}
