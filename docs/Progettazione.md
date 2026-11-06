# App eventi BuonaCaccia — Documento di progettazione

App per telefoni e tablet (Android e iOS, pubblicata sugli store) che estrae dal portale AGESCI
BuonaCaccia l'elenco degli eventi di un tipo, eventualmente filtrato per regione, e lo esporta in
PDF e/o Excel da condividere con genitori e ragazzi.

- **Nome:** da decidere (V-07). Nome provvisorio del pacchetto: `eventi_bc`.
- **Stato:** analisi chiusa salvo le proposte del §0; scheletro del repository pronto (05/11/2026)
  in `~/Developer/Personal/eventi_bc`; sviluppo non iniziato.
- **Repository GitHub:** da decidere insieme al nome (V-07). Licenza MIT, © Andrea Bruno.
- **Pubblicazione:** account sviluppatore personale di Andrea su App Store e Google Play.
- **Sviluppo:** Claude Code in Android Studio (D-16).

Convenzioni: le decisioni sono **D-nn**, le verifiche aperte **V-nn**. Le *proposte* sono scelte
di progetto non ancora confermate esplicitamente da Andrea. Le *inferenze* sono deduzioni da
verificare prima di usarle.

---

## 0. Proposte da approvare

Andrea le rivede qui. Quelle non contestate valgono come approvate.

| N. | Proposta | Dove | Alternativa |
| --- | --- | --- | --- |
| P-01 | Pausa di 300 ms tra le richieste di dettaglio, massimo 2 in parallelo | D-04 | Pausa più lunga (più lento, più rispettoso) |
| P-02 | Test settimanale nel CI contro il sito reale, che apre una issue se i parser falliscono | D-05 | Solo test manuali |
| P-03 | Interruttore "solo iscrizioni aperte o da aprire" (se il sito lo permette via GET, V-02) | D-08 | Nessun filtro |
| P-04 | Voci di gruppo del menu tipi (es. "L/C", "Formazione Capi") selezionabili, se il sito le accetta (V-03) | D-08 | Solo voci foglia |
| P-05 | Informativa privacy pubblicata su GitHub Pages del repository | D-12 | Pagina su un tuo dominio |
| P-06 | Nessun logo AGESCI nell'app e nei file finché l'autorizzazione non ne copre l'uso; icona originale neutra | D-13 | Logo dopo l'autorizzazione |
| P-07 | Ordinamento per data di partenza, poi titolo | D-15 | Ordine del sito ("per tipologia") |
| P-08 | Riverpod per lo stato dell'app | §6 | Provider, Bloc, solo `setState` |
| P-09 | PDF A4 orizzontale; tabella o scheda per evento da decidere con un mockup | §5, V-10 | — |
| P-10 | Organizzazione `it.bruand81` per gli identificativi dell'app (es. `it.bruand81.eventi_bc` su Android) | §12 | Altro dominio inverso |
| P-11 | Fixture HTML anonimizzate come contratto comune futuro con BCEventScraper-rs | D-02 | — |
| P-12 | Struttura `lib/` in data / parsing / domain / export / ui | §7 | — |
| P-13 | Avviso iniziale "app non ufficiale" mostrato a ogni avvio (non si può ricordare la chiusura: niente persistenza) | D-00 | Solo schermata Informazioni |

---

## 1. Scopo

I capi devono spesso mandare ai genitori o ai ragazzi l'elenco degli eventi di un certo tipo
(es. tutte le Piccole Orme, tutti i campi Capi Squadriglia del Lazio). BuonaCaccia mostra
l'elenco ma non permette di esportarlo. L'app:

1. legge da BuonaCaccia i menu di regione e tipo evento;
2. scarica l'elenco degli eventi della selezione;
3. opzionalmente ("Estrai dettagli") apre la pagina di ogni evento per i dati aggiuntivi;
4. produce un PDF e/o un Excel e li condivide con il menu nativo del sistema.

L'app **non sostituisce BuonaCaccia** e non vi accede in modo riservato (D-00, D-00b).

### 1.1 Rapporto con i progetti esistenti

| Progetto | Rapporto con l'app |
| --- | --- |
| `AGESCI-Campania/BCEventScraper` (Python, Selenium) | Origine storica. Non riusato. |
| `AGESCI-Campania/BCEventScraper-rs` (Rust) | Fonte degli id ASP.NET verificati per lista e dettaglio (`bc.rs`, `reports.rs`). Il codice non si riusa (D-02); se ne porta la conoscenza. |

Nota per BCEventScraper-rs, rilevata durante l'analisi: `bc.rs` usa `BASE = "https://buonacaccia.net"`.
Il portale avvisa che il vecchio indirizzo sarà dismesso e che il reindirizzamento automatico
resta attivo fino al 28/02/2027. Va portato su `buonacaccia.agesci.it`.

### 1.2 Struttura del sito (verificata il 05/11/2026)

Verificata leggendo le pagine renderizzate (WebFetch), non l'HTML grezzo: l'ambiente di analisi
non raggiunge il sito. Gli id HTML vengono da BCEventScraper-rs e vanno riconfermati (V-01).

**Lista** `https://buonacaccia.agesci.it/Events.aspx?RID=<regione>&CID=<tipo>`
- Semplice GET, nessun postback necessario per filtrare. Verificati: `RID=H` Lazio,
  `CID=1010101` Piccole Orme. Da BCEventScraper-rs: `RID=A` Nazionale, `RID=E` Campania,
  `CID=2010101` Specialità, `2010102` Capi Squadriglia, `2010104` Competenza,
  `2010105` Candidature Competenza; parametro `All=1` per "tutti gli eventi" (V-02).
- Griglia `table#MainContent_EventsGridView` (da BCEventScraper-rs). Nessuna paginazione con
  ~200 eventi senza filtri (V-04).
- Colonne: Tipo (icona `branch_xx.png` + sigla, es. `PO`, `CapiSq`), Titolo (link a
  `Event.aspx?e=<id>`; l'attributo `title` contiene titolo + sottotitolo, a volte troncato),
  Regione, Partenza, Rientro, Quota, Località, Iscritti, icone informative, Stato.
- Valori particolari osservati:
  - Quota `-` (evento senza quota); quote in formato `21,00 €`.
  - Località `(da definire)`.
  - Iscritti `29 / 28` (gli iscritti possono superare il massimo: lista d'attesa) e `20 / (*)`
    (nessun limite).
  - Regioni abbreviate nella lista: `EmiRo`, `FVG`, `TAA` (nel dettaglio sono per esteso).
- Icone informative, con il dato nell'attributo `title`:
  - `calendar.png` "Evento in più appuntamenti";
  - `map.png` "Posti liberi per fuori regione: N" (N può essere negativo, es. `-2`);
  - `user.png` "Posti liberi Moz.45/2023: N".
- Stato (semaforo): `light_green.png`, `light_yellow.png`, `light_dual.png`, `light_red.png`.

**Dettaglio** `https://buonacaccia.agesci.it/Event.aspx?e=<id>`

Id da BCEventScraper-rs (`span#MainContent_EventFormView_*`):

| Campo | Id |
| --- | --- |
| Titolo | `lbTitle` |
| Sottotitolo | `lblSottotitolo` |
| Capi campo | `lbOwners` (stringa unica, nomi separati da ` - `) |
| Località | `lbLocation` |
| Apertura iscrizioni | `lbSubsFrom` |
| Chiusura iscrizioni | `lbSubsTo` |
| Posti | `lbSeats` |
| Iscritti | `lbTaken` |

Campi osservati ma **con id non noti** (V-01):
- link di presentazione (icona `link.png`): URL esterno (es. evento 26533,
  `foca.agesci.it/...`) oppure il testo "(link di presentazione non disponibile)";
- "Informazioni dalla segreteria": sezione presente solo in alcuni eventi, testo libero seguito
  da molte righe vuote (26533: "Campo fisso");
- contatti metodologici e amministrativi: email oppure "(non disponibile)"; gli `href mailto:`
  possono avere un `%0d%0a` finale.

Il testo "Apriranno il …" resta tale anche a iscrizioni già aperte (26533): l'etichetta non indica lo stato.

---

## 2. Decisioni

### D-00 — L'app non sostituisce BuonaCaccia
Deve essere evidente in ogni punto:
- **Store**: descrizione con frase esplicita "App non ufficiale: semplifica la consultazione degli
  eventi di BuonaCaccia; iscrizioni e informazioni ufficiali restano su buonacaccia.agesci.it".
- **App**: schermata "Informazioni" sempre raggiungibile e avviso iniziale (P-13).
- **Ogni evento** porta il link alla sua pagina su BuonaCaccia; l'app non offre iscrizioni.
- **PDF ed Excel**: "Fonte: BuonaCaccia (buonacaccia.agesci.it) — dati estratti il gg/mm/aaaa
  alle hh:mm. Per iscriversi e per i dati aggiornati usare BuonaCaccia."
- **Nome**: non deve far pensare a un'app ufficiale o sostitutiva (vincolo per V-07).

### D-00b — Solo pagine pubbliche, nessuna credenziale, niente salvato sul dispositivo
- L'app legge solo `Events.aspx` ed `Event.aspx`. Non apre `/Utenti`, `Subscribe.aspx`,
  `Status.aspx` o qualunque area riservata; non gestisce cookie di sessione.
- Non chiede, non accetta e non conserva credenziali.
- Nessuna persistenza: niente database, preferenze, cache dei risultati o dei menu.
- Eccezione confermata da Andrea: il PDF/Excel da condividere è un **file temporaneo** nella
  cartella cache dell'app, cancellato dopo la condivisione e comunque a ogni avvio. Il
  salvataggio permanente lo fa l'utente dal menu di condivisione.
- Nessuna analitica, nessun tracciamento, nessuna pubblicità.

### D-01 — Solo client, nessun backend
Scraping ed export avvengono sul dispositivo. Nessun server, nessun account utente.

### D-02 — Flutter, Dart puro
Un solo codice per Android e iOS, con layout per telefono e tablet.
Valutato e scartato il riuso di BCEventScraper-rs via `flutter_rust_bridge`:
- la parte riusabile è ~150 righe di `bc.rs`; il resto (polars, parquet, CLI, trasformazioni per
  tipi di campo specifici, report CSV) non serve all'app;
- `ureq` è sincrono e polars appesantirebbe molto il binario mobile;
- i record sono mappe di stringhe non tipizzate; non estrae link, segreteria, contatti, icone, stato;
- servirebbe la compilazione incrociata per iOS e Android nel CI.

Si porta la **conoscenza** (id, URL, insidie). Vedi P-11.

### D-03 — Menu letti dal sito
Regioni e tipi evento si estraggono dai `<select>` di `Events.aspx` a ogni avvio. Senza rete:
elenco **incluso nell'app** (`assets/menu/menu.json`, generato in F1 dall'HTML reale, non scritto
sul dispositivo) e avviso che potrebbe non essere aggiornato.

### D-04 — Scraping rispettoso
- Al massimo 2 richieste di dettaglio in parallelo, con pausa tra una e l'altra (P-01).
- User-Agent che identifica l'app e il repository, **senza email**.
- Barra di avanzamento ("12 di 87") e pulsante Annulla; con ~200 eventi si avvisa prima di partire.
- Errori per singolo evento: l'evento resta in elenco senza dettagli, con segnalazione.
- I limiti non sono configurabili dall'interfaccia.

### D-05 — Parser
- Primo criterio: gli **id ASP.NET** (`MainContent_EventsGridView`,
  `span#MainContent_EventFormView_*`); riserva: le etichette di testo ("I Capi Campo",
  "Iscrizioni", …). Correzione di un'ipotesi precedente: la struttura "variabile" vista
  sull'evento 26870 era un effetto della conversione in markdown, non dell'HTML.
- Funzioni pure `String html → modello`, senza rete, testate su fixture.
- Fixture = HTML reali salvati e **anonimizzati** (nomi dei capi campo, email non istituzionali,
  `__VIEWSTATE` e campi nascosti) da uno script del repository. Nessun nome reale nel repository.
- Valore fuori formato: l'evento non si scarta mai; si conserva il testo grezzo e si aggiunge
  un'anomalia mostrata all'utente.
- Test periodico contro il sito reale (P-02). Serve perché non esiste un export ufficiale
  (confermato da Andrea) e lo scraping è l'unica fonte.

### D-06 — Export
PDF e/o Excel a scelta (almeno uno), poi condivisione con il menu nativo (`share_plus`).

### D-07 — Repository
MIT © Andrea Bruno, `.gitignore` Flutter, badge nel README, `CLAUDE.md` alla radice,
`mise.toml` per i comandi, CI su GitHub Actions.

### D-08 — Filtri
- **Tipo evento**: selezione singola, obbligatoria (P-04 per le voci di gruppo).
- **Regione**: selezione singola, facoltativa (default "Tutte le regioni").
- **Solo iscrizioni aperte o da aprire**: P-03.
- **Estrai dettagli**: interruttore, spento di default.

### D-09 — Stato
| Icona | Etichetta nell'app |
| --- | --- |
| `light_green` | Aperte |
| `light_yellow` | In esaurimento |
| `light_dual` | Lista d'attesa |
| `light_red` | Chiuse |

### D-10 — Icone informative
Si estraggono dall'attributo `title` con espressioni regolari sul testo (non sul nome del file):
più appuntamenti (sì/no), posti liberi fuori regione (intero, anche negativo), posti liberi
Moz. 45/2023 (intero). Etichetta di quest'ultimo riportata com'è sul sito.

### D-11 — Dettagli
Con "Estrai dettagli": sottotitolo, capi campo (elenco), apertura e chiusura iscrizioni, link di
presentazione, informazioni dalla segreteria (righe vuote rimosse), contatti metodologico e
amministrativo.

### D-12 — Pubblicazione
- Account personali. Costi e requisiti attuali da ricontrollare alla pubblicazione (V-08).
- **Google Play**: gli account personali creati dopo il 13/11/2023 devono fare un test chiuso con
  almeno 12 tester iscritti in modo continuativo per almeno 14 giorni prima della produzione
  (verificato sulla guida di Play Console il 05/11/2026). Tester: capi volontari (V-09).
- **Apple**: la linea guida 5.2.2 richiede che un'app che mostra contenuti di un servizio terzo
  sia autorizzata dai termini del servizio, con autorizzazione "fornita su richiesta".
  L'autorizzazione scritta di AGESCI (V-06) va allegata alle note per la revisione.
- Privacy: "nessun dato raccolto" (Apple) e modulo Data safety (Google); informativa pubblica
  (bozza in `docs/privacy.md`, P-05).

### D-13 — Grafica
- Icona e logo: P-06.
- Font Titillium Web (licenza OFL, `assets/fonts/OFL.txt`): Regular, Italic, SemiBold, Bold.
- Interfaccia solo in italiano.

### D-14 — Host
Solo `https://buonacaccia.agesci.it`. Mai `buonacaccia.net`.

### D-15 — Ordinamento
P-07.

### D-16 — IDE: Android Studio
Scelto tra JetBrains e VS Code:
- il plugin Flutter ufficiale supporta Android Studio e IntelliJ IDEA (docs.flutter.dev);
- il plugin Claude Code per JetBrains supporta Android Studio (code.claude.com);
- Android Studio serve comunque per SDK ed emulatori Android; è IntelliJ, quindi coerente con
  RustRover e PyCharm già in uso;
- Xcode serve comunque per firma, simulatore e caricamento iOS.

VS Code è un'alternativa valida (estensione Flutter ufficiale), ma non aggiunge nulla qui.

---

## 3. Modello dati

Nomi di dominio in italiano. Importi in centesimi interi, mai `double`.

| Campo | Tipo | Fonte | Note |
| --- | --- | --- | --- |
| `id` | int | lista | da `Event.aspx?e=` |
| `url` | Uri | lista | assoluto su `buonacaccia.agesci.it` |
| `sigla` | String | lista | `PO`, `CapiSq`, `CFM L/C`… |
| `branca` | enum | lista | da `branch_lc/eg/rs/fc/aa.png`; `aa` = riunioni e assemblee (*inferenza*) |
| `titolo` | String | lista | |
| `regione` | String | lista | nome completo; `EmiRo`, `FVG`, `TAA` convertiti; sigla ignota → testo grezzo + anomalia |
| `partenza`, `rientro` | data | lista | `gg/mm/aaaa` |
| `quotaCentesimi` | int? | lista | null se `-` |
| `localita` | String? | lista | null se `(da definire)`, mostrato "da definire" |
| `iscritti` | int | lista | |
| `iscrittiMax` | int? | lista | null se `(*)`, mostrato "senza limite" |
| `stato` | enum | lista | D-09 |
| `piuAppuntamenti` | bool | lista | D-10 |
| `postiFuoriRegione` | int? | lista | D-10 |
| `postiMoz45` | int? | lista | D-10 |
| `sottotitolo` | String? | dettaglio | |
| `capiCampo` | List<String> | dettaglio | split su ` - ` |
| `aperturaIscrizioni`, `chiusuraIscrizioni` | data? | dettaglio | |
| `linkPresentazione` | Uri? | dettaglio | |
| `infoSegreteria` | String? | dettaglio | |
| `contattoMetodologico`, `contattoAmministrativo` | String? | dettaglio | `%0d%0a` rimosso |
| `anomalie` | List<String> | parser | D-05 |

---

## 4. Interfaccia (proposta)

1. **Ricerca**: tipo evento, regione, interruttori (solo aperte, dettagli), formati (PDF, Excel),
   pulsante "Estrai". Link a "Informazioni" (D-00).
2. **Avanzamento**: conteggio, barra, Annulla.
3. **Risultati**: elenco con stato e date; tocco → pagina su BuonaCaccia nel browser; avviso se
   ci sono anomalie; pulsante "Condividi".

Tablet: ricerca e risultati affiancati.

---

## 5. File esportati

**PDF** (P-09)
- Intestazione: tipo evento, regione, data e ora di estrazione.
- Per ogni evento: titolo cliccabile, regione (solo se "Tutte"), partenza, rientro, quota,
  località, iscritti/max, stato; con i dettagli anche capi campo, periodo di iscrizione,
  presentazione (cliccabile), informazioni dalla segreteria.
- Legenda dello stato; piè di pagina D-00.

**Excel**
- Un foglio; date come date, quota come numero in euro, iscritti e massimo in colonne separate,
  URL come collegamenti; intestazione bloccata e filtro automatico; riga finale con la nota D-00.

Nome file: `eventi_<tipo>_<regione>_<aaaammgg>.pdf|xlsx`.

---

## 6. Stack

| Componente | Scelta |
| --- | --- |
| Flutter / Dart | Ultima stabile (3.47.9 con Dart 3.13.7 al 29/10/2026, fonte docs Shorebird); versione effettiva annotata in F0 |
| HTTP | `http` |
| Parsing HTML | `html` |
| PDF | `pdf` |
| Excel | `excel` |
| Condivisione | `share_plus`, `path_provider` (solo cartella temporanea) |
| Link esterni | `url_launcher` (pagina dell'evento su BuonaCaccia) |
| Stato | `flutter_riverpod` (P-08) |
| Date e numeri | `intl` (formato italiano) |
| Lint | `flutter_lints` + regole in `analysis_options.yaml` |

Versioni e licenze dei pacchetti: scelte da `flutter pub add` in F0 e riportate qui, mai scritte
a memoria. Esclusi pacchetti con licenze non open source o con analitica.

| Pacchetto | Versione | Licenza |
| --- | --- | --- |
| *(da compilare in F0)* | | |

---

## 7. Struttura del repository

```
eventi_bc/
├── CLAUDE.md  README.md  LICENSE  .gitignore  .editorconfig  mise.toml  analysis_options.yaml
├── .claude/settings.json      # comandi flutter/dart/git consentiti a Claude Code
├── .github/workflows/ci.yml   # format, analyze, test
├── lib/                       # (F0) data / parsing / domain / export / ui (P-12)
├── android/  ios/             # (F0) generati da flutter create
├── assets/fonts/              # Titillium Web + OFL.txt
├── assets/menu/               # (F1) elenco di riserva regioni/tipi (D-03)
├── test/fixtures/             # (F1) HTML anonimizzati
├── tool/capture_fixtures.sh   # cattura pagine in tool/fixtures_raw/ (ignorata da git)
└── docs/Progettazione.md, docs/privacy.md (bozza)
```

---

## 8. Fasi di sviluppo

| Fase | Contenuto |
| --- | --- |
| F0 | `flutter create`, dipendenze, font, app minima, CI verde (procedura in CLAUDE.md) |
| F1 | Verifiche V-01…V-05 sull'HTML grezzo; cattura e anonimizzazione delle fixture; `menu.json` |
| F2 | Parser menu e lista, con test |
| F3 | Parser dettaglio, con test |
| F4 | Client HTTP, scheduler rispettoso, annullamento; test "live" e workflow settimanale |
| F5 | Interfaccia |
| F6 | Export PDF ed Excel, file temporanei, condivisione |
| F7 | Store: icona, schermate, informativa, test chiuso Play, TestFlight, note per la revisione |

---

## 9. Verifiche aperte

| N. | Verifica | Come si procede intanto |
| --- | --- | --- |
| V-01 | Su HTML grezzo: id della griglia, dei `<select>` e dei loro `value`, degli span del dettaglio (anche link di presentazione, segreteria, contatti) su `buonacaccia.agesci.it` | Id di BCEventScraper-rs + etichette di testo |
| V-02 | "Solo iscrizioni aperte o da aprire": parametro GET (`All=`?) o postback? | Interruttore nascosto se richiede postback |
| V-03 | Le voci di gruppo del menu tipi funzionano come `CID`? | Solo voci foglia |
| V-04 | La griglia ha paginazione oltre una certa soglia? | Nessuna paginazione |
| V-05 | "Informazioni dalla segreteria" può contenere link o formattazione? | Solo testo |
| V-06 | Autorizzazione scritta AGESCI: a chi chiederla, e se copre scraping, nome e logo | Nessun logo (P-06) |
| V-07 | Nome dell'app e posizione del repository GitHub | Nome provvisorio `eventi_bc` |
| V-08 | Costi e requisiti attuali di Apple Developer Program e Google Play Console; obbligo di informativa privacy | Da verificare alla pubblicazione |
| V-09 | 12 tester per il test chiuso su Play | — |
| V-10 | Layout del PDF (tabella o schede) leggibile su telefono | Mockup prima di F6 |
| V-11 | Condizioni d'uso / `robots.txt` di BuonaCaccia | Da leggere prima di V-06 |
| V-12 | Identificativi generati da `flutter create` (applicationId Android, bundle id iOS): un `_` nel nome potrebbe essere convertito per iOS (*inferenza*) | Annotarli in §12 dopo F0; fissarli prima del primo caricamento sugli store |

---

## 10. Vincoli per l'implementazione (riportati in CLAUDE.md)

- **Anti-confabulazione**: verificare sul sito o sulle fixture prima di affermare la forma di un dato;
  dichiarare le inferenze; mai inventare id, selettori o versioni.
- **Ambito**: solo `Events.aspx` ed `Event.aspx` su `buonacaccia.agesci.it`; nessuna area riservata,
  nessuna credenziale, nessun cookie di sessione.
- **Nessuna persistenza** salvo i file temporanei di condivisione (D-00b).
- **Parser puri** e testati su fixture; nessuna rete nei test unitari.
- **Fixture anonimizzate**: nessun nome reale nel repository.
- **Rispetto del sito**: limiti di D-04 non disattivabili dall'interfaccia.
- **Importi** in centesimi interi.
- **Nessun evento scartato** in silenzio: anomalie visibili.
- **Testi utente** in italiano, senza codici di decisione (D-nn, V-nn, P-nn); codice e commenti in inglese.
- **D-00** presente in store, schermata Informazioni, PDF ed Excel.

---

## 11. Riferimenti

- https://buonacaccia.agesci.it/Events.aspx
- https://buonacaccia.agesci.it/Event.aspx?e=26533 (link di presentazione e segreteria)
- https://buonacaccia.agesci.it/Event.aspx?e=26719, https://buonacaccia.agesci.it/Event.aspx?e=26870
- `AGESCI-Campania/BCEventScraper-rs` — `src/bc.rs`, `src/reports.rs`, `CLAUDE.md`
- Google Play Console, requisiti di test per i nuovi account personali:
  https://support.google.com/googleplay/android-developer/answer/14151465
- App Store Review Guidelines, 5.2.2
- Versione Flutter: https://docs.shorebird.dev/getting-started/flutter-version.md
- Flutter in Android Studio e IntelliJ: https://docs.flutter.dev/tools/android-studio
- Claude Code nei JetBrains IDE: https://code.claude.com/docs/en/jetbrains

---

## 12. Scheletro del repository (05/11/2026)

Preparato senza Flutter installato nell'ambiente di analisi, quindi:
- **non contiene** `pubspec.yaml`, `lib/`, `android/`, `ios/`: li genera `flutter create` in F0
  con la procedura di CLAUDE.md (commit iniziale prima, controllo con `git diff` dopo);
- **non fissa versioni** di pacchetti: le sceglie `flutter pub add` in F0;
- versioni delle action GitHub (`actions/checkout@v4`, `subosito/flutter-action@v2`) da aggiornare in F0;
- nessuna configurazione di esecuzione `.run/`: Android Studio crea quella di `main.dart` all'apertura
  (*inferenza*).

Identificativi (P-10, V-12):

| Piattaforma | Identificativo | Stato |
| --- | --- | --- |
| Android `applicationId` | *(da annotare dopo F0)* | |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | *(da annotare dopo F0)* | |

Gli identificativi non si possono cambiare dopo il primo caricamento sugli store: se il nome
definitivo (V-07) arriva dopo F0, vanno aggiornati prima di F7.
