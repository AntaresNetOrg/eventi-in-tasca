import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/annullamento.dart';
import '../data/bc_exceptions.dart';
import '../domain/evento.dart';
import '../domain/ordinamento.dart';
import '../parsing/bc_page_format_exception.dart';
import 'filtri.dart';
import 'providers.dart';

/// Above this number of events, "Estrai dettagli" asks for confirmation first
/// (decided by Andrea on 08/11/2026).
const sogliaConfermaDettagli = 50;

/// What was searched, for the results header and the exported files.
class Ricerca {
  const Ricerca({
    required this.tipo,
    required this.regione,
    required this.soloAperte,
    required this.dettagli,
  });

  final String tipo;

  /// Null when searching all regions.
  final String? regione;
  final bool soloAperte;
  final bool dettagli;
}

class Risultato {
  const Risultato({
    required this.ricerca,
    required this.eventi,
    required this.estrattoIl,
  });

  final Ricerca ricerca;

  /// Sorted by departure date, then title (P-07).
  final List<Evento> eventi;
  final DateTime estrattoIl;

  int get eventiConAnomalie =>
      eventi.where((e) => e.anomalie.isNotEmpty).length;
}

sealed class StatoEstrazione {
  const StatoEstrazione();
}

/// Nothing running: the search screen is shown.
final class Inattivo extends StatoEstrazione {
  const Inattivo();
}

final class CercaEventi extends StatoEstrazione {
  const CercaEventi();
}

/// The list has many events: ask before opening every event page.
final class ConfermaDettagli extends StatoEstrazione {
  const ConfermaDettagli(this.eventi);

  final int eventi;
}

final class EstraiDettagli extends StatoEstrazione {
  const EstraiDettagli({required this.fatti, required this.totale});

  final int fatti;
  final int totale;
}

final class Completata extends StatoEstrazione {
  const Completata(this.risultato);

  final Risultato risultato;
}

final class Errore extends StatoEstrazione {
  const Errore(this.messaggio);

  /// In Italian, for the user.
  final String messaggio;
}

/// Runs one extraction at a time: list, optional confirmation, details.
class EstrazioneController extends Notifier<StatoEstrazione> {
  Annullamento? _annullamento;
  Ricerca? _ricerca;
  List<Evento> _eventi = const [];

  /// Increased by every new run or cancellation: results of an older run are
  /// ignored.
  int _corsa = 0;

  @override
  StatoEstrazione build() => const Inattivo();

  bool get inCorso => state is CercaEventi || state is EstraiDettagli;

  Future<void> avvia({
    required Filtri filtri,
    required String tipo,
    String? regione,
  }) async {
    final cid = filtri.cid;
    if (cid == null || inCorso) return;
    final corsa = ++_corsa;
    final annullamento = _annullamento = Annullamento();
    _ricerca = Ricerca(
      tipo: tipo,
      regione: filtri.rid == null ? null : regione,
      soloAperte: filtri.soloAperte,
      dettagli: filtri.dettagli,
    );
    state = const CercaEventi();

    try {
      final eventi = await ref
          .read(estrazioneProvider)
          .cercaEventi(
            cid: cid,
            rid: filtri.rid,
            soloAperte: filtri.soloAperte,
            annullamento: annullamento,
          );
      if (!_attuale(corsa)) return;
      _eventi = eventi;
      if (!filtri.dettagli || eventi.isEmpty) {
        _completa(eventi);
      } else if (eventi.length > sogliaConfermaDettagli) {
        state = ConfermaDettagli(eventi.length);
      } else {
        await _estraiDettagli(corsa);
      }
    } catch (e) {
      if (_attuale(corsa)) _fallisci(e);
    }
  }

  /// After [ConfermaDettagli]: open every event page.
  Future<void> confermaDettagli() async {
    if (state is! ConfermaDettagli) return;
    final corsa = _corsa;
    try {
      await _estraiDettagli(corsa);
    } catch (e) {
      if (_attuale(corsa)) _fallisci(e);
    }
  }

  /// After [ConfermaDettagli]: keep the list without details.
  void soloElenco() {
    if (state is ConfermaDettagli) _completa(_eventi, dettagli: false);
  }

  /// Stops the running extraction and goes back to the search.
  void annulla() {
    _corsa++;
    _annullamento?.annulla();
    _annullamento = null;
    state = const Inattivo();
  }

  /// From the results or an error, back to the search screen.
  void nuovaRicerca() => annulla();

  Future<void> _estraiDettagli(int corsa) async {
    state = EstraiDettagli(fatti: 0, totale: _eventi.length);
    final completi = await ref
        .read(estrazioneProvider)
        .estraiDettagli(
          _eventi,
          annullamento: _annullamento,
          avanzamento: (fatti, totale) {
            if (_attuale(corsa)) {
              state = EstraiDettagli(fatti: fatti, totale: totale);
            }
          },
        );
    if (_attuale(corsa)) _completa(completi);
  }

  bool _attuale(int corsa) => ref.mounted && corsa == _corsa;

  void _completa(List<Evento> eventi, {bool? dettagli}) {
    final ricerca = _ricerca!;
    _annullamento = null;
    state = Completata(
      Risultato(
        ricerca: Ricerca(
          tipo: ricerca.tipo,
          regione: ricerca.regione,
          soloAperte: ricerca.soloAperte,
          dettagli: dettagli ?? ricerca.dettagli,
        ),
        eventi: ordinaEventi(eventi),
        estrattoIl: DateTime.now(),
      ),
    );
  }

  void _fallisci(Object errore) {
    _annullamento = null;
    state = switch (errore) {
      EstrazioneAnnullataException() => const Inattivo(),
      BcNetworkException(:final message) => Errore(message),
      BcPageFormatException() => const Errore(
        'La pagina di BuonaCaccia non è stata riconosciuta: il sito potrebbe '
        'essere cambiato. Riprova più tardi.',
      ),
      _ => const Errore('Si è verificato un errore imprevisto. Riprova.'),
    };
  }
}

final estrazioneControllerProvider =
    NotifierProvider<EstrazioneController, StatoEstrazione>(
      EstrazioneController.new,
    );
