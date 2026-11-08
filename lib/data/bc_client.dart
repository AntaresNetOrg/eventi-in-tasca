import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'annullamento.dart';
import 'bc_exceptions.dart';
import 'request_scheduler.dart';

/// The only host the app talks to (D-14).
const bcHost = 'buonacaccia.agesci.it';

/// Version sent in the User-Agent; a test keeps it equal to pubspec.yaml.
const appVersion = '1.0.0';

/// Identifies the app without any email address (D-04).
// TODO(V-07): add the repository URL once the repository is decided.
const userAgent = 'eventi_bc/$appVersion (app non ufficiale per BuonaCaccia)';

const _eventsPath = '/Events.aspx';
const _eventPath = '/Event.aspx';

/// Reads the public pages of BuonaCaccia: only GET on `Events.aspx` and
/// `Event.aspx`, without cookies or credentials (D-00b). Redirects are never
/// followed, so no other page can be reached.
class BcClient {
  BcClient({
    http.Client? client,
    RequestScheduler? scheduler,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _scheduler = scheduler ?? RequestScheduler();

  final http.Client _client;
  final RequestScheduler _scheduler;
  final Duration timeout;

  /// The event list, also used to read the search menus.
  ///
  /// Without [cid] all event types; without [rid] all regions. With
  /// [soloAperte] only events with enrollment open or still to open (V-02).
  Future<String> paginaElenco({
    String? rid,
    String? cid,
    bool soloAperte = true,
    Annullamento? annullamento,
  }) {
    final query = {
      if (rid != null && rid.isNotEmpty) 'RID': rid,
      if (cid != null && cid.isNotEmpty) 'CID': cid,
      if (!soloAperte) 'All': '1',
    };
    // An empty map would add a trailing `?`.
    final uri = Uri.https(bcHost, _eventsPath, query.isEmpty ? null : query);
    return _get(uri, annullamento: annullamento);
  }

  /// The page of the event [id].
  ///
  /// Throws [EventoNonDisponibileException] when the site redirects to the
  /// list, which is what it does for an event that does not exist.
  Future<String> paginaEvento(int id, {Annullamento? annullamento}) {
    final uri = Uri.https(bcHost, _eventPath, {'e': '$id'});
    return _get(uri, annullamento: annullamento, eventId: id);
  }

  void close() => _client.close();

  Future<String> _get(Uri uri, {Annullamento? annullamento, int? eventId}) =>
      _scheduler.esegui(
        () => _send(uri, annullamento, eventId),
        annullamento: annullamento,
      );

  Future<String> _send(
    Uri uri,
    Annullamento? annullamento,
    int? eventId,
  ) async {
    annullamento?.verifica();
    final abort = Completer<void>();
    if (annullamento != null) {
      unawaited(annullamento.segnale.then((_) => _complete(abort)));
    }
    final request =
        http.AbortableRequest('GET', uri, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers['User-Agent'] = userAgent;

    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      _complete(abort);
      throw const BcNetworkException(
        'BuonaCaccia non ha risposto in tempo. Riprova più tardi.',
      );
    } on http.RequestAbortedException {
      throw const EstrazioneAnnullataException();
    } on http.ClientException {
      annullamento?.verifica();
      throw const BcNetworkException(
        'Impossibile raggiungere BuonaCaccia. Controlla la connessione.',
      );
    } finally {
      _complete(abort);
    }
    annullamento?.verifica();

    if (eventId != null && _isRedirectToList(response)) {
      throw EventoNonDisponibileException(eventId);
    }
    if (response.statusCode != 200) {
      throw BcNetworkException(
        'BuonaCaccia ha risposto con un errore (${response.statusCode}). '
        'Riprova più tardi.',
      );
    }
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      throw const BcNetworkException(
        'La risposta di BuonaCaccia non è leggibile.',
      );
    }
  }

  static void _complete(Completer<void> completer) {
    if (!completer.isCompleted) completer.complete();
  }

  static bool _isRedirectToList(http.Response response) {
    if (response.statusCode < 300 || response.statusCode >= 400) return false;
    final location = response.headers['location'];
    if (location == null) return false;
    final target = Uri.https(bcHost, '/').resolve(location);
    return target.host == bcHost && target.path == _eventsPath;
  }
}
