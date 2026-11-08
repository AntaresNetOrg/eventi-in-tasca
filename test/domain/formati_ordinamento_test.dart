import 'package:eventi_bc/domain/evento.dart';
import 'package:eventi_bc/domain/formati.dart';
import 'package:eventi_bc/domain/ordinamento.dart';
import 'package:flutter_test/flutter_test.dart';

Evento _evento(String titolo, DateTime? partenza) =>
    Evento(sigla: 'PO', titolo: titolo, regione: 'Lazio', partenza: partenza);

void main() {
  group('ordinaEventi', () {
    test('by departure date, then title, without a date last', () {
      final ordinati = ordinaEventi([
        _evento('Zeta', DateTime(2026, 12, 5)),
        _evento('senza data', null),
        _evento('alfa', DateTime(2026, 12, 5)),
        _evento('Prima', DateTime(2026, 11, 1)),
      ]);

      expect(ordinati.map((e) => e.titolo), [
        'Prima',
        'alfa',
        'Zeta',
        'senza data',
      ]);
    });
  });

  group('formati', () {
    test('dates and periods', () {
      expect(formatData(DateTime(2026, 1, 3)), '03/01/2026');
      expect(formatData(null), '—');
      expect(
        formatPeriodo(DateTime(2026, 12, 5), DateTime(2026, 12, 8)),
        '05/12/2026 – 08/12/2026',
      );
      expect(
        formatPeriodo(DateTime(2026, 12, 5), DateTime(2026, 12, 5)),
        '05/12/2026',
      );
    });

    test('fee in cents', () {
      expect(formatQuota(2100), '21,00 €');
      expect(formatQuota(5), '0,05 €');
      expect(formatQuota(null), 'nessuna quota');
    });

    test('participants', () {
      expect(formatIscritti(29, 28), '29 su 28 posti');
      expect(formatIscritti(12, null), '12 (senza limite)');
    });

    test('state labels of D-09', () {
      expect(etichettaStato(StatoIscrizioni.chiuse), 'Chiuse');
      expect(etichettaStato(StatoIscrizioni.listaAttesa), "Lista d'attesa");
    });

    test('duration estimate', () {
      expect(stimaDurata(51), 'meno di un minuto');
      expect(stimaDurata(200), 'circa 1-2 minuti');
      expect(stimaDurata(298), 'circa 2-3 minuti');
    });
  });
}
