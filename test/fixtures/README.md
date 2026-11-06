# Fixture

Pagine HTML di BuonaCaccia **anonimizzate**, usate dai test dei parser.

Si producono in fase F1:

1. `mise run fixtures` scarica le pagine originali in `tool/fixtures_raw/` (ignorata da git);
2. lo script di anonimizzazione in `tool/` le copia qui sostituendo nomi dei capi campo,
   email non istituzionali e campi nascosti (`__VIEWSTATE`, `__EVENTVALIDATION`).

Prima di committare una fixture, controlla a mano che non contenga nomi o recapiti reali.
Ogni fixture va annotata qui con la data di cattura e il caso che copre.

| File | Catturata il | Caso coperto |
| --- | --- | --- |
| — | — | — |
