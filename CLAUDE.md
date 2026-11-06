# CLAUDE.md

Istruzioni per Claude Code (e per chi sviluppa) in questo repository.

## Cos'è

App Flutter per Android e iOS che estrae dal portale AGESCI **BuonaCaccia** l'elenco
degli eventi di un tipo (e, opzionalmente, di una regione) e lo esporta in PDF e/o
Excel da condividere. È un'utilità **non ufficiale**: non sostituisce BuonaCaccia.

- **Specifica:** `docs/Progettazione.md`. Contiene decisioni (D-nn), verifiche aperte
  (V-nn), *proposte* (scelte non ancora confermate da Andrea) e *inferenze* (da
  verificare). Prima di implementare una funzione, leggi le decisioni che la riguardano.
- **Nome provvisorio:** `eventi_bc` (pacchetto Dart). Il nome definitivo è V-07: non
  inventarne uno.
- **Stato:** solo scheletro. Non esiste ancora codice Dart né cartelle `android/` e
  `ios/`: le genera la fase F0.

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
   `--org it.bruand81` è la *proposta* P-10 (Progettazione §0): se Andrea non l'ha
   confermata, chiedigli prima di eseguire.
4. `git status` e `git diff`: `flutter create` non dovrebbe sovrascrivere i file
   esistenti (*inferenza*). Se ha toccato `README.md`, `.gitignore`, `LICENSE`,
   `CLAUDE.md` o `analysis_options.yaml`, ripristinali con `git checkout -- <file>`.
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

Riferimenti per i parser (Progettazione §1.2):
- griglia `table#MainContent_EventsGridView`;
- dettaglio `span#MainContent_EventFormView_` + `lbTitle`, `lblSottotitolo`, `lbOwners`,
  `lbLocation`, `lbSubsFrom`, `lbSubsTo`, `lbSeats`, `lbTaken` (da BCEventScraper-rs, da
  riconfermare in F1);
- link di presentazione, informazioni dalla segreteria, contatti, `<select>` dei menu:
  id **non noti**, da ricavare dalle fixture in F1.

## Fixture

- `tool/capture_fixtures.sh` scarica le pagine in `tool/fixtures_raw/` (ignorata da git).
- Lo script di anonimizzazione (da scrivere in F1, in Dart sotto `tool/`) produce
  `test/fixtures/` e deve:
  - sostituire i nomi dei capi campo con nomi fittizi fissi (es. `CAPO UNO - CAPO DUE`);
  - sostituire indirizzi email non istituzionali (quelli `@agesci.it` e
    `@<regione>.agesci.it` possono restare);
  - svuotare `__VIEWSTATE`, `__EVENTVALIDATION` e campi nascosti simili;
  - lasciare intatto tutto il resto (struttura, id, classi, icone, `title`).
- Prima di committare una fixture, controlla a mano che non contenga nomi o recapiti reali.

## Test

- Unitari: nessuna rete, solo fixture.
- Test contro il sito reale: marcati con il tag `live`, esclusi dall'esecuzione normale,
  eseguiti dal workflow settimanale (F4).

## Comandi

```bash
mise run analyze     # flutter analyze
mise run test        # flutter test
mise run format      # dart format
mise run fixtures    # cattura le pagine in tool/fixtures_raw/ (F1)
flutter run          # su emulatore o dispositivo
```

Editor: Android Studio con i plugin Flutter e Claude Code.
