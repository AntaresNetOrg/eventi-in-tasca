# Fixture

Pagine HTML di BuonaCaccia **anonimizzate**, usate dai test dei parser.

Come si producono:

1. `mise run fixtures` scarica le pagine originali in `tool/fixtures_raw/` (ignorata da git);
2. `mise run anonymize` le copia qui sostituendo nomi dei capi campo, email non istituzionali
   e valori dei campi nascosti.

Lo script non riconosce i nomi nel testo libero: "Informazioni dalla segreteria" può citare
relatori o riportare IBAN. Le pagine con questi dati non si pubblicano (nella prima cattura
26887, 26843, 26677, 26682): l'elenco delle pagine pubblicate è `fixtureNames` in
`tool/anonymize_fixtures.dart`.

Prima di committare una fixture, controlla a mano che non contenga nomi o recapiti reali.
`test/fixtures_privacy_test.dart` è un controllo in più, non sostituisce quello a mano.
Ogni fixture va annotata qui con la data di cattura e il caso che copre.
I file sono esclusi dalla normalizzazione di git (`.gitattributes`): i caratteri CR sono dati.

| File | Catturata il | Caso coperto |
| --- | --- | --- |
| `events_all_1.html` | 06/11/2026 | `All=1`, 298 righe: casella non spuntata, quota `-`, `(*)`, `(da definire)`, icone informative, posti negativi, sottotitolo nel `title`, sigla vuota (26479), tutti e quattro i semafori |
| `events_lazio_po.html` | 06/11/2026 | Filtri `RID` e `CID`, casella spuntata, iscritti oltre il massimo |
| `event_26719.html` | 06/11/2026 | Dettaglio base, senza link di presentazione né segreteria |
| `event_26870.html` | 06/11/2026 | Sottotitolo, contatto metodologico `(non disponibile)`, `mailto` con `%0d%0a` |
| `event_26533.html` | 06/11/2026 | Link di presentazione, segreteria con righe vuote |
| `event_26575.html` | 06/11/2026 | Appuntamenti senza `lbLocation`, `<a href>` nella segreteria |
| `event_26698.html` | 06/11/2026 | `<strong>` nella segreteria |
| `event_26886.html` | 06/11/2026 | `<br />` nella segreteria, sottotitolo, link a un PDF |
| `event_26678.html` | 06/11/2026 | Email non istituzionale nella segreteria (sostituita) |
| `event_26770.html` | 06/11/2026 | Evento senza quota e senza limite di posti |
| `event_26748.html` | 06/11/2026 | Località `(da definire)`, tre capi campo |
