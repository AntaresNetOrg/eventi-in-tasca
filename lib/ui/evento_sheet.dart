import 'package:flutter/material.dart';

import '../domain/evento.dart';
import '../domain/formati.dart';
import 'apri_link.dart';
import 'risultati_view.dart';

/// Opens the details of [evento] in a bottom sheet.
Future<void> mostraEvento(BuildContext context, Evento evento) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) =>
            EventoSheet(evento: evento, scrollController: controller),
      ),
    );

class EventoSheet extends StatelessWidget {
  const EventoSheet({super.key, required this.evento, this.scrollController});

  final Evento evento;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final e = evento;
    final url = e.url;
    final link = e.linkPresentazione;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(e.titolo, style: testo.titleLarge),
        if (e.sottotitolo != null)
          Text(e.sottotitolo!, style: testo.titleSmall),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ChipStato(stato: e.stato),
        ),
        if (e.anomalie.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dati da controllare su BuonaCaccia',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (final anomalia in e.anomalie) Text('• $anomalia'),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _Campo('Tipo', e.sigla.isEmpty ? '—' : e.sigla),
        _Campo('Regione', e.regione),
        _Campo('Date', formatPeriodo(e.partenza, e.rientro)),
        if (e.piuAppuntamenti) const _Campo('', 'Evento in più appuntamenti'),
        for (final a in e.appuntamenti)
          _Campo(
            'Appuntamento',
            '${formatPeriodo(a.dal, a.al)}'
                '${a.localita == null ? '' : ' · ${a.localita}'}',
          ),
        _Campo('Località', formatLocalita(e.localita)),
        _Campo('Quota', formatQuota(e.quotaCentesimi)),
        _Campo('Iscritti', formatIscritti(e.iscritti, e.iscrittiMax)),
        if (e.postiFuoriRegione != null)
          _Campo('Posti liberi fuori regione', '${e.postiFuoriRegione}'),
        if (e.postiMoz45 != null)
          _Campo('Posti liberi Moz.45/2023', '${e.postiMoz45}'),
        if (e.capiCampo.isNotEmpty)
          _Campo('Capi campo', e.capiCampo.join(', ')),
        if (e.aperturaIscrizioni != null || e.chiusuraIscrizioni != null)
          _Campo(
            'Iscrizioni',
            'dal ${formatData(e.aperturaIscrizioni)} '
                'al ${formatData(e.chiusuraIscrizioni)}',
          ),
        if (e.infoSegreteria != null)
          _Campo('Informazioni dalla segreteria', e.infoSegreteria!),
        if (e.contattoMetodologico != null)
          _Campo('Informazioni metodologiche', e.contattoMetodologico!),
        if (e.contattoAmministrativo != null)
          _Campo('Informazioni amministrative', e.contattoAmministrativo!),
        const SizedBox(height: 16),
        if (link != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Presentazione dell\'evento'),
            onPressed: () => apriLink(context, link),
          ),
        if (url != null)
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apri su BuonaCaccia'),
            onPressed: () => apriLink(context, url),
          ),
        const SizedBox(height: 8),
        Text(
          'Per iscriversi e per i dati aggiornati usare BuonaCaccia.',
          style: testo.bodySmall,
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.etichetta, this.valore);

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (etichetta.isNotEmpty)
          Text(etichetta, style: Theme.of(context).textTheme.labelMedium),
        SelectableText(valore),
      ],
    ),
  );
}
