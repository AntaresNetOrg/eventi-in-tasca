import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eventi_bc/data/annullamento.dart';
import 'package:eventi_bc/data/bc_client.dart';
import 'package:eventi_bc/data/bc_exceptions.dart';
import 'package:eventi_bc/data/request_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final requests = <http.Request>[];

  BcClient clientWith(
    Future<http.Response> Function(http.Request request) handler, {
    Duration timeout = const Duration(seconds: 30),
  }) => BcClient(
    client: MockClient((request) {
      requests.add(request);
      return handler(request);
    }),
    scheduler: RequestScheduler(pausa: Duration.zero),
    timeout: timeout,
  );

  BcClient answering(String body) =>
      clientWith((_) async => http.Response.bytes(utf8.encode(body), 200));

  setUp(requests.clear);

  group('addresses', () {
    test('search with region, type and closed events', () async {
      await answering('x')
          .paginaElenco(rid: 'H', cid: '1010101', soloAperte: false);

      expect(
        requests.single.url.toString(),
        'https://buonacaccia.agesci.it/Events.aspx?RID=H&CID=1010101&All=1',
      );
    });

    test('search of a type in every region, open events only', () async {
      await answering('x').paginaElenco(cid: '1000000');

      expect(
        requests.single.url.toString(),
        'https://buonacaccia.agesci.it/Events.aspx?CID=1000000',
      );
    });

    test('page for the menus', () async {
      await answering('x').paginaElenco();

      expect(
        requests.single.url.toString(),
        'https://buonacaccia.agesci.it/Events.aspx',
      );
    });

    test('event page', () async {
      await answering('x').paginaEvento(26719);

      expect(
        requests.single.url.toString(),
        'https://buonacaccia.agesci.it/Event.aspx?e=26719',
      );
    });
  });

  group('requests', () {
    test('are GET, without cookies and without following redirects', () async {
      await answering('x').paginaEvento(26719);
      final request = requests.single;

      expect(request.method, 'GET');
      expect(request.followRedirects, isFalse);
      expect(
        request.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('cookie')),
      );
    });

    test('identify the app without an email address', () async {
      await answering('x').paginaEvento(26719);

      expect(requests.single.headers['User-Agent'], userAgent);
      expect(userAgent, startsWith('eventi-in-tasca/'));
      expect(userAgent, contains(repositoryUrl));
      expect(userAgent, isNot(contains('@')));
    });

    test('the version in the User-Agent is the one of pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version: ([^+\s]+)',
        multiLine: true,
      ).firstMatch(pubspec)![1];

      expect(appVersion, version);
    });
  });

  group('responses', () {
    test('are decoded as UTF-8', () async {
      final body = await answering('Località €').paginaEvento(1);

      expect(body, 'Località €');
    });

    test('a redirect to the list means the event no longer exists', () async {
      final client = clientWith(
        (_) async => http.Response(
          '',
          302,
          headers: {'location': 'https://buonacaccia.agesci.it/Events.aspx'},
        ),
      );

      await expectLater(
        client.paginaEvento(99999999),
        throwsA(
          isA<EventoNonDisponibileException>().having(
            (e) => e.id,
            'id',
            99999999,
          ),
        ),
      );
    });

    test('a relative redirect to the list is recognized too', () async {
      final client = clientWith(
        (_) async =>
            http.Response('', 302, headers: {'location': '/Events.aspx'}),
      );

      await expectLater(
        client.paginaEvento(1),
        throwsA(isA<EventoNonDisponibileException>()),
      );
    });

    test('a redirect elsewhere is an error and is not followed', () async {
      final client = clientWith(
        (_) async => http.Response(
          '',
          302,
          headers: {'location': 'https://buonacaccia.agesci.it/Utenti'},
        ),
      );

      await expectLater(
        client.paginaEvento(1),
        throwsA(isA<BcNetworkException>()),
      );
      expect(requests, hasLength(1));
    });

    test('a server error is reported', () async {
      final client = clientWith((_) async => http.Response('', 500));

      await expectLater(
        client.paginaElenco(),
        throwsA(
          isA<BcNetworkException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('a network error is reported', () async {
      final client = clientWith(
        (request) async => throw http.ClientException('offline', request.url),
      );

      await expectLater(
        client.paginaElenco(),
        throwsA(isA<BcNetworkException>()),
      );
    });

    test('a slow answer is a timeout', () async {
      final client = clientWith(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        client.paginaElenco(),
        throwsA(
          isA<BcNetworkException>().having(
            (e) => e.message,
            'message',
            contains('in tempo'),
          ),
        ),
      );
    });
  });

  group('cancellation', () {
    test('no request is sent after cancellation', () async {
      final annullamento = Annullamento()..annulla();

      await expectLater(
        Future.sync(
          () => answering('x').paginaElenco(annullamento: annullamento),
        ),
        throwsA(isA<EstrazioneAnnullataException>()),
      );
      expect(requests, isEmpty);
    });

    test('a request in progress is aborted', () async {
      final annullamento = Annullamento();
      // The streaming mock receives the original request, with its abort
      // trigger; the handler aborts like a real connection would.
      final client = BcClient(
        client: MockClient.streaming((request, _) async {
          await (request as http.Abortable).abortTrigger;
          throw http.RequestAbortedException(request.url);
        }),
        scheduler: RequestScheduler(pausa: Duration.zero),
      );

      final pagina = client.paginaElenco(annullamento: annullamento);
      annullamento.annulla();

      await expectLater(pagina, throwsA(isA<EstrazioneAnnullataException>()));
    });
  });
}
