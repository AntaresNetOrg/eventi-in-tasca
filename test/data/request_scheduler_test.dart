import 'dart:async';

import 'package:eventi_bc/data/annullamento.dart';
import 'package:eventi_bc/data/bc_exceptions.dart';
import 'package:eventi_bc/data/request_scheduler.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the defaults are those of the specification', () {
    final scheduler = RequestScheduler();

    expect(scheduler.maxParallel, 2);
    expect(scheduler.pausa, const Duration(milliseconds: 300));
  });

  test('runs at most two requests at the same time', () {
    fakeAsync((async) {
      final scheduler = RequestScheduler();
      final richieste = List.generate(5, (_) => Completer<void>());
      var attive = 0;
      var massimo = 0;

      for (final richiesta in richieste) {
        scheduler.esegui(() async {
          attive++;
          if (attive > massimo) massimo = attive;
          await richiesta.future;
          attive--;
        });
      }

      for (final richiesta in richieste) {
        async.flushMicrotasks();
        richiesta.complete();
        async.elapse(const Duration(seconds: 1));
      }

      expect(massimo, 2);
      expect(attive, 0);
    });
  });

  test('waits the pause before the next request of the same slot', () {
    fakeAsync((async) {
      final scheduler = RequestScheduler(maxParallel: 1);
      final avvii = <Duration>[];

      for (var i = 0; i < 3; i++) {
        scheduler.esegui(() async => avvii.add(async.elapsed));
      }
      async.elapse(const Duration(seconds: 2));

      expect(avvii, [
        Duration.zero,
        const Duration(milliseconds: 300),
        const Duration(milliseconds: 600),
      ]);
    });
  });

  test('returns the result or the error of each request', () {
    fakeAsync((async) {
      final scheduler = RequestScheduler();
      int? risultato;
      Object? errore;

      scheduler.esegui(() async => 42).then((value) => risultato = value);
      scheduler
          .esegui<int>(() async => throw const FormatException('x'))
          .then<void>((_) {}, onError: (Object e) => errore = e);
      async.elapse(const Duration(seconds: 1));

      expect(risultato, 42);
      expect(errore, isA<FormatException>());
    });
  });

  test('a failed request does not block the queue', () {
    fakeAsync((async) {
      final scheduler = RequestScheduler(maxParallel: 1);
      var eseguite = 0;

      scheduler
          .esegui<void>(() async => throw StateError('x'))
          .catchError((Object _) {});
      scheduler.esegui(() async => eseguite++);
      async.elapse(const Duration(seconds: 1));

      expect(eseguite, 1);
    });
  });

  test('cancellation drops the queued requests', () {
    fakeAsync((async) {
      final scheduler = RequestScheduler();
      final annullamento = Annullamento();
      final inCorso = Completer<void>();
      var avviate = 0;
      final esiti = <Object>[];

      for (var i = 0; i < 5; i++) {
        scheduler
            .esegui(() async {
              avviate++;
              await inCorso.future;
            }, annullamento: annullamento)
            .catchError((Object e) => esiti.add(e));
      }
      async.flushMicrotasks();
      annullamento.annulla();
      async.flushMicrotasks();

      expect(avviate, 2);
      expect(esiti, hasLength(3));
      expect(esiti, everyElement(isA<EstrazioneAnnullataException>()));

      inCorso.complete();
      async.elapse(const Duration(seconds: 1));
      expect(avviate, 2);
    });
  });

  test('a request is refused after cancellation', () {
    final annullamento = Annullamento()..annulla();

    expect(
      () => RequestScheduler().esegui(() async {}, annullamento: annullamento),
      throwsA(isA<EstrazioneAnnullataException>()),
    );
  });
}
