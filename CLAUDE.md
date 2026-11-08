# CLAUDE.md

Istruzioni per Claude Code (e per chi sviluppa) in questo repository.

## Cos'è

App Flutter per Android e iOS che estrae dal portale AGESCI **BuonaCaccia** l'elenco
degli eventi di un tipo (e, opzionalmente, di una regione) e lo esporta in PDF e/o
Excel da condividere. È un'utilità **non ufficiale**: non sostituisce BuonaCaccia.

- **Specifica:** `docs/Progettazione.md`. Contiene decisioni (D-nn), verifiche aperte
  (V-nn), *proposte* (scelte non ancora confermate da Andrea) e *inferenze* (da
  verificare). Prima di implementare una funzione, leggi le decisioni che la riguardano.
- **Nome:** "Eventi in tasca" (V-07). Il pacchetto Dart resta `eventi_bc`. Repository:
  https://github.com/AntaresNetOrg/eventi-in-tasca. Identificativi in Progettazione §12.
- **Stato:** F0–F4 completate (app minima, fixture, menu di riserva, parser, client HTTP con
  limiti e annullamento, test sul sito reale). Prossima fase: F5.

## Lingua

- Conversazione, messaggi di commit e documentazione: **italiano**.
- Codice, identificatori tecnici e commenti: **inglese**.
- Nomi di dominio in italiano (`Evento`, `capiCampo`, `aperturaIscrizioni`), come nel
  modello dati di `docs/Progettazione.md` §3.
- Testi mostrati all'utente: italiano, **senza** codici di progetto (D-nn, V-nn, P-nn); nei
  commenti e nei docstring i codici vanno bene.

## Regole che non si derogano

1. **Anti-confabulazione.** Non inventare id HTML, selettori, parametri URL, valori dei
   menu o versioni di pacchetti. Se un dato non è nelle fixture o nella specifica,
   verificalo (fixture, `curl`, pub.dev) e solo dopo usalo. Dichiara le inferenze.
   Se una verifica fallisce, fermati e riferisci: niente scorciatoie.
2. **Ambito di rete (D-00b, D-14).** Solo GET su
   `https://buonacaccia.agesci.it/Events.aspx` e `https://buonacaccia.agesci.it/Event.aspx`.
   Mai `buonacaccia.net`. Mai `/Utenti`, `Subscribe.aspx`, `Status.aspx` o altre aree
   riservate. Nessuna credenziale, nessun cookie di sessione.
3. **Nessuna persistenza (D-00b).** Niente database, `shared_preferences`, cache su
   disco. Unica eccezione: il file PDF/Excel da condividere, scritto nella cartella
   temporanea, cancellato dopo la condivisione e a ogni avvio.
4. **Rispetto del sito (D-04).** Massimo 2 richieste in parallelo, pausa tra le
   richieste, User-Agent che identifica app e repository **senza email**. I limiti non
   sono configurabili dall'interfaccia.
5. **Non sostituisce BuonaCaccia (D-00).** La nota "non ufficiale / iscrizioni su
   BuonaCaccia" deve comparire in schermata Informazioni, avviso iniziale, PDF ed Excel.
   L'app non offre iscrizioni.
6. **Parser puri (D-05).** Funzioni `String html → modello`, senza rete, coperte da test
   su fixture. Prima gli id ASP.NET, poi le etichette di testo come riserva.
7. **Nessun evento scartato in silenzio.** Un valore fuori formato diventa un'anomalia
   associata all'evento e visibile all'utente.
8. **Importi in centesimi interi**, mai `double`.
9. **Nessun dato personale reale nel repository.** Le fixture si anonimizzano (vedi sotto);
   `tool/fixtures_raw/` è ignorata da git e non va mai aggiunta.
10. **Nessuna analitica, tracciamento o pubblicità.** Non aggiungere pacchetti che li
    includono (es. Firebase Analytics, Crashlytics).
11. **Licenze.** Solo dipendenze con licenza open source compatibile con MIT; verifica
    la licenza su pub.dev prima di aggiungere un pacchetto.

## Fase F0 — avvio del progetto (da fare per prima, in quest'ordine)

1. `git init`, poi commit di tutto lo scheletro ("Scheletro iniziale"), così le modifiche
   di `flutter create` sono visibili con `git diff`.
2. `flutter --version`: annota versione di Flutter e Dart in `docs/Progettazione.md` §6.
3. Genera le piattaforme:
   ```bash
   flutter create --org it.bruand81 --project-name eventi_bc --platforms android,ios .
   ```
   Fatto in F0 con `it.bruand81` (P-10); l'08/11/2026 gli identificativi sono passati a
   `org.antaresnet` (Progettazione §12).
4. `git status` e `git diff`: `flutter create` non dovrebbe sovrascrivere i file
   esistenti (*inferenza*). Se ha toccato `README.md`, `.gitignore`, `LICENSE`,
   `CLAUDE.md` o `analysis_options.yaml`, ripristinali con `git checkout -- <file>`.
   Eccezione verificata in F0 (Flutter 3.47.9): ogni comando `flutter` aggiunge di nuovo
   a `analysis_options.yaml` le esclusioni `build/**`, `android/**`, `ios/**`; quelle tre
   righe restano nel repository.
5. Controlla e annota in Progettazione §12 gli identificativi generati: `applicationId`
   Android (`android/app/build.gradle*`) e `PRODUCT_BUNDLE_IDENTIFIER` iOS
   (`ios/Runner.xcodeproj/project.pbxproj`). Diventano definitivi al primo caricamento
   sugli store.
6. Dipendenze (versioni scelte da `pub add`, non scritte a mano):
   ```bash
   flutter pub add http html pdf excel share_plus path_provider url_launcher intl flutter_riverpod
   ```
   Per ognuna verifica la licenza su pub.dev e riporta pacchetto, versione e licenza in
   Progettazione §6. Riverpod è una *proposta*: se Andrea l'ha cambiata, segui la sua scelta.
7. In `pubspec.yaml` dichiara la famiglia di font `TitilliumWeb` con i file in
   `assets/fonts/` (Regular 400, Italic 400 corsivo, SemiBold 600, Bold 700) e includi
   `assets/fonts/OFL.txt` negli asset.
8. Sostituisci l'app d'esempio con un'app minima (titolo provvisorio, schermata vuota)
   e un test che la carica.
9. Aggiorna le versioni delle action in `.github/workflows/ci.yml` alle ultime stabili.
10. Verifica: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
    `flutter test` tutti verdi. Poi commit.

## Fasi successive (dettaglio in Progettazione §8)

| Fase | Contenuto |
| --- | --- |
| F1 | Cattura fixture (`tool/capture_fixtures.sh`), script di anonimizzazione, verifiche V-01…V-05 sull'HTML grezzo; elenco di riserva dei menu in `assets/menu/` |
| F2 | Parser menu e lista + test |
| F3 | Parser dettaglio + test |
| F4 | Client HTTP, scheduler (D-04), annullamento; test "live" e workflow settimanale |
| F5 | Interfaccia |
| F6 | Export PDF ed Excel, file temporanei, condivisione |
| F7 | Pubblicazione sugli store |

Ogni fase si chiude con analyze e test verdi e un commit. Le risposte alle verifiche
V-nn vanno scritte in `docs/Progettazione.md` (tabella §9 e sezione interessata).

## Architettura (proposta)

```
lib/
├── main.dart
├── data/       # BcClient (HTTP), RequestScheduler (limiti D-04)
├── parsing/    # parseMenu, parseEventList, parseEventDetail — funzioni pure
├── domain/     # Evento, StatoIscrizioni, Branca, Anomalia
├── export/     # PdfExporter, XlsxExporter, TempFiles
└── ui/         # schermate Ricerca, Avanzamento, Risultati, Informazioni
```

Riferimenti per i parser: Progettazione §1.2, verificata sull'HTML grezzo in F1. Attenzione:
nella griglia l'id `MainContent_EventsGridView_Type_N` compare due volte per riga (sigla e
regione).

## Fixture

- `tool/capture_fixtures.sh` scarica le pagine in `tool/fixtures_raw/` (ignorata da git).
- `tool/anonymize_fixtures.dart` produce `test/fixtures/`:
  - sostituisce i nomi dei capi campo con nomi fittizi fissi (es. `CAPO UNO - CAPO DUE`);
  - sostituisce indirizzi email non istituzionali (quelli `@agesci.it` e
    `@<regione>.agesci.it` restano);
  - svuota `__VIEWSTATE`, `__EVENTVALIDATION` e campi nascosti simili;
  - lascia intatto tutto il resto (struttura, id, classi, icone, `title`).
- Lo script non riconosce nomi e IBAN nel testo libero della segreteria: pubblica solo le
  pagine in `fixtureNames`, scelte senza questi dati (vedi `test/fixtures/README.md`).
- Prima di committare una fixture, controlla a mano che non contenga nomi o recapiti reali.

## Test

- Unitari: nessuna rete, solo fixture.
- Test contro il sito reale: marcati con il tag `live`, saltati di default (`dart_test.yaml`),
  eseguiti dal workflow settimanale `.github/workflows/live.yml`. A mano:
  `flutter test --run-skipped --tags live` (4 GET sul sito).

## Comandi

```bash
mise run analyze     # flutter analyze
mise run test        # flutter test
mise run format      # dart format
mise run fixtures    # cattura le pagine in tool/fixtures_raw/
mise run anonymize   # produce test/fixtures/ dalle pagine catturate
mise run menu        # genera assets/menu/menu.json dalle pagine catturate
flutter run          # su emulatore o dispositivo
```

Editor: Android Studio con i plugin Flutter e Claude Code.
