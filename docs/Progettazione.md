# App eventi BuonaCaccia — Documento di progettazione

App per telefoni e tablet (Android e iOS, pubblicata sugli store) che estrae dal portale AGESCI
BuonaCaccia l'elenco degli eventi di un tipo, eventualmente filtrato per regione, e lo esporta in
PDF e/o Excel da condividere con genitori e ragazzi.

- **Nome:** "Eventi in tasca" (V-07, deciso da Andrea l'08/11/2026). Il pacchetto Dart resta
  `eventi_bc`: è interno e non compare agli utenti.
- **Stato:** analisi chiusa salvo le verifiche aperte del §9; fasi F0–F4 completate entro
  l'08/11/2026 in `~/Developer/Personal/eventi_bc`; prossima fase F5.
- **Repository GitHub:** https://github.com/AntaresNetOrg/eventi-in-tasca, pubblico.
  Licenza MIT, © Andrea Bruno.
- **Pubblicazione:** account sviluppatore personale di Andrea su App Store e Google Play.
- **Sviluppo:** Claude Code in Android Studio (D-16).

Convenzioni: le decisioni sono **D-nn**, le verifiche aperte **V-nn**. Le *proposte* sono scelte
di progetto non ancora confermate esplicitamente da Andrea. Le *inferenze* sono deduzioni da
verificare prima di usarle.

---

## 0. Proposte

Tutte riviste da Andrea l'08/11/2026, salvo dove indicato.

| N. | Proposta | Dove | Esito |
| --- | --- | --- | --- |
| P-01 | Pausa di 300 ms tra le richieste, massimo 2 in parallelo | D-04 | Realizzata in F4, non contestata |
| P-02 | Test settimanale nel CI contro il sito reale, che apre una issue se i parser falliscono | D-05 | Realizzata in F4, non contestata |
| P-03 | Interruttore "solo iscrizioni aperte o da aprire" | D-08 | **Confermata**, acceso all'avvio |
| P-04 | Voci di gruppo del menu tipi (es. "L/C", "CFM") selezionabili | D-08 | **Confermata** |
| P-05 | Informativa privacy pubblicata su GitHub Pages del repository | D-12 | **Confermata** |
| P-06 | Nessun logo AGESCI nell'app e nei file finché l'autorizzazione non ne copre l'uso; icona originale neutra | D-13 | **Confermata**; icona scelta l'08/11/2026 (D-13) |
| P-07 | Ordinamento per data di partenza, poi titolo | D-15 | **Confermata** |
| P-08 | Riverpod per lo stato dell'app | §6 | **Confermata** |
| P-09 | PDF A4 orizzontale; tabella o scheda per evento da decidere con un mockup | §5, V-10 | **Confermata**: A4 orizzontale, mockup all'inizio di F6 |
| P-10 | Organizzazione degli identificativi | §12 | **Superata**: `org.antaresnet` (08/11/2026, §12) |
| P-11 | Fixture HTML anonimizzate come contratto comune futuro con BCEventScraper-rs | D-02 | **Confermata** l'08/11/2026: Andrea mantiene BCEventScraper-rs e BCEventScraper (§1.1). Eventi in tasca resta la fonte delle fixture, che i due progetti copiano da un commit preciso (`scripts/sync-fixtures.sh`, `tests/fixtures/SOURCE`). **Realizzata l'08/11/2026** sui branch `test/shared-fixtures`: parsing separato dalla rete e test in entrambi (Rust 10 nuovi test; Python 8 con Chrome headless). I test hanno trovato un difetto del Rust: un record spurio per evento dalla tabella annidata nella colonna Tipo, corretto |
| P-12 | Struttura `lib/` in data / parsing / domain / export / ui | §7 | Realizzata, non contestata |
| P-13 | Avviso iniziale "app non ufficiale" mostrato a ogni avvio | D-00 | **Confermata** |

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
| `AGESCI-Campania/BCEventScraper` (Python, Selenium) | Origine storica, ancora in uso. Gestito da Andrea; privato, senza test. Il codice non si riusa. |
| `AGESCI-Campania/BCEventScraper-rs` (Rust) | Porting del Python, gestito da Andrea; privato, 5 test unitari, nessuno sui parser. Fonte degli id ASP.NET di partenza (`bc.rs`, `reports.rs`). Il codice non si riusa (D-02); se ne porta la conoscenza. |

Entrambi usavano `buonacaccia.net` per l'elenco degli eventi. L'08/11/2026 sono stati preparati
i branch `fix/host-buonacaccia-agesci` per passare a `buonacaccia.agesci.it`, con pull request
da approvare da Andrea.

Il portale avvisa che il vecchio indirizzo `buonacaccia.net` sarà dismesso e che il
reindirizzamento automatico resta attivo fino al 28/02/2027.

### 1.2 Struttura del sito (verificata sull'HTML grezzo il 06/11/2026, F1)

Campione: 7 elenchi e 35 dettagli catturati con `tool/capture_fixtures.sh`.

**Lista** `https://buonacaccia.agesci.it/Events.aspx?RID=<regione>&CID=<tipo>[&All=1]`
- Semplice GET, nessun postback necessario per filtrare.
- Menu: `select#MainContent_ddlRegion` (21 regioni, `A` Nazionale; `value=""` "Tutte le
  regioni") e `select#MainContent_ddlCategory` (85 tipi; `value=""` "Tutti gli eventi").
  Etichette con prefissi `- `, `--- `, `----> `; le voci di gruppo hanno classe `LevelN`.
  Il menu `ddlRegionSelector` della barra in alto non include Nazionale: non usarlo.
- Senza `All=1` la casella `MainContent_cbShowUseful` "Mostra solo gli eventi con iscrizioni
  aperte o da aprire" è spuntata; con `All=1` non lo è. Il 06/11/2026: 198 righe contro 298,
  e le 100 in più sono tutte `light_red` (V-02).
- Griglia `table#MainContent_EventsGridView`, nessun paginatore (V-04). Id di riga con indice N:
  `..._EventIcon_N_imgBranch_N`, `..._Fee_N`, `..._Location_N`, `..._Taken_N`, `..._SeatsMax_N`,
  `..._outRegion_N`, `..._moz45_2023_N`. **`..._Type_N` compare due volte per riga: sigla e
  regione**, quindi vanno distinte per colonna. Partenza, rientro e semaforo non hanno id.
- Colonne: Tipo (icona `branch_xx.png` + sigla, es. `PO`, `CapiSq`), una colonna con l'icona
  `calendar.png`, Titolo (link a `Event.aspx?e=<id>`), Regione, Partenza, Rientro, Quota,
  Località, Iscritti, icone `map.png` e `user.png`, Stato.
- L'attributo `title` del link contiene il titolo e, se c'è, un carattere CR seguito dal
  sottotitolo (63 righe su 298), a volte troncato. Il testo del link è il solo titolo.
- Ricerca senza risultati: la griglia esiste, senza intestazione, con la sola riga
  "(nessun evento corrisponde ai criteri di ricerca impostati)".
- Eventi con appuntamenti: l'elenco riporta comunque una località (26575 `Savona (SV)`, 26872
  `(da definire)`).
- Valori particolari osservati:
  - Sigla vuota (evento 26479, tipo "Speciale").
  - In `All=1` le quote sono solo `-` o `N,NN €`; gli iscritti massimi solo interi o `(*)`.
  - Non sono apparse sigle regionali diverse da `EmiRo`, `FVG` e `TAA`, ma Molise e Valle
    d'Aosta non hanno eventi nel campione.
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
  Legenda del sito: verde "Iscrizioni aperte"; giallo "aperte con un numero limitato di posti
  disponibili o leggermente in sovrannumero"; duale "aperte con posti in pesante sovrannumero";
  rosso "Iscrizioni chiuse", anche per eventi non ancora aperti (D-09).

**Dettaglio** `https://buonacaccia.agesci.it/Event.aspx?e=<id>`

Id con prefisso `MainContent_EventFormView_` (pagine che li contengono, su 35):

| Campo | Id | Pagine | Valori |
| --- | --- | --- | --- |
| Titolo | `lbTitle` | 35 | Inizia con `[Regione] `, nome completo |
| Sottotitolo | `lblSottotitolo` | 11 | |
| Capi campo | `lbOwners` | 35 | Stringa unica, da 1 a 4 nomi separati da ` - ` |
| Icona branca | `EventIcon_imgBranch` | 35 | |
| Sigla | `Type` | 35 | |
| Regione | `lbRegion` | 35 | Nome completo |
| Partenza, rientro | `lbEventFrom`, `lbEventTo` | 35 | `gg/mm/aaaa` |
| Località | `lbLocation` | 33 | Assente con gli appuntamenti |
| Appuntamenti | `pnlAppointments`, `gvAppointments` | 2 | Righe `gg/mm/aaaa - gg/mm/aaaa` + località (V-14) |
| Quota | `lbFee` | 35 | `N,NN €` o `nessuna quota d'iscrizione` |
| Link di presentazione | `hlURL` | 35 | `<a href>` oppure, senza `href`, "(link di presentazione non disponibile)" |
| Informazioni dalla segreteria | `lbDescription` | 19 | HTML (V-05) |
| Posti | `lbSeats` | 35 | Intero o `illimitati` |
| Apertura, chiusura iscrizioni | `lbSubsFrom`, `lbSubsTo` | 35 | `gg/mm/aaaa` |
| Iscritti | `lbTaken` | 35 | Intero |
| Contatto metodologico | `hlPoC` | 35 | `<a href="mailto:">` oppure, senza `href`, "(non disponibile)" |
| Contatto amministrativo | `hlAdmin` | 35 | Come sopra; l'`href` può avere `%0d%0a` finale |

Nella tabella degli appuntamenti l'id `gvAppointments_Type_N` compare due volte per riga (date
e località), e la località può essere vuota.

Altre osservazioni (F3, 06-08/11/2026):
- Su 9 dettagli confrontati con l'elenco, titolo (senza il prefisso `[Regione] `), regione,
  date, quota, località, iscritti e posti coincidono; `lbSeats` è il massimo dell'elenco
  (`illimitati` = `(*)`), `nessuna quota d'iscrizione` corrisponde a `-`.
- La segreteria è HTML non valido (`<p>` dentro `<span>` dentro `<p>`): un parser HTML5
  sposta i paragrafi fuori dallo `<span>`, che resta vuoto. Il parser ritaglia il frammento
  dal testo della pagina.
- `Event.aspx?e=<id inesistente>` risponde `302` verso `Events.aspx`, senza pagina d'errore:
  il client (F4) deve trattare il redirect come "evento non più disponibile". Il parser del
  dettaglio rifiuta comunque una pagina senza titolo dell'evento.

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
- Realizzazione (F4, `lib/data/`): i limiti valgono per tutte le richieste, elenco compreso.
  Ognuno dei 2 canali attende 300 ms dopo ogni richiesta prima della successiva; timeout di
  30 s. I redirect non vengono mai seguiti: un `302` verso `Events.aspx` su `Event.aspx` vuol
  dire evento non più disponibile, qualunque altro redirect è un errore. Annulla scarta le
  richieste in coda e interrompe quelle in corso.
- User-Agent: `eventi-in-tasca/1.0.0 (app non ufficiale per BuonaCaccia;
  +https://github.com/AntaresNetOrg/eventi-in-tasca)`.

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
- Test periodico contro il sito reale (P-02): `test/live/` con tag `live`, saltati di
  default (`dart_test.yaml`), eseguiti il lunedì da `.github/workflows/live.yml`, che apre una
  issue con etichetta `live-test` se falliscono (una sola aperta alla volta). Sono 4 GET. Serve perché non esiste un export ufficiale
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

"Chiuse" significa che in quel momento nessuno può iscriversi, qualunque sia il motivo: iscrizioni
non ancora aperte, limiti raggiunti o termini scaduti (confermato da Andrea il 06/11/2026).

### D-10 — Icone informative
Si estraggono dall'attributo `title` con espressioni regolari sul testo (non sul nome del file):
più appuntamenti (sì/no), posti liberi fuori regione (intero, anche negativo), posti liberi
Moz. 45/2023 (intero). Etichetta di quest'ultimo riportata com'è sul sito.

### D-11 — Dettagli
Con "Estrai dettagli": sottotitolo, capi campo (elenco), apertura e chiusura iscrizioni, link di
presentazione, informazioni dalla segreteria (righe vuote rimosse), contatti metodologico e
amministrativo, date e località dei singoli appuntamenti.

I campi già letti dall'elenco (titolo, regione, date, quota, località, iscritti) non vengono
sovrascritti dal dettaglio: se i valori non coincidono si aggiunge un'anomalia, perché può essere
un aggiornamento avvenuto tra le due letture (confermato da Andrea il 06/11/2026).

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
- Icona e logo: P-06. Icona scelta da Andrea l'08/11/2026 tra 5 bozze: un calendario
  (testata rossa, un giorno evidenziato in verde) che spunta inclinato da una tasca gialla con
  cuciture, su sfondo verde scuro. Sorgente: `docs/icona/icona.svg`, 1024×1024, senza testo
  né simboli associativi. Le versioni per Android (adattiva) e iOS si generano in F7.
- Colori: verde scuro `#1E4A30`, verde `#2F6B45`, giallo `#F2B33D`, rosso `#E8573C`.
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

Nel codice (`lib/domain/evento.dart`) `id`, `url`, date, `iscritti`, `branca` e `stato` sono
nullable anche se il sito li fornisce sempre: un valore fuori formato diventa null con
un'anomalia che riporta il testo grezzo, e l'evento resta in elenco (D-05).

| Campo | Tipo | Fonte | Note |
| --- | --- | --- | --- |
| `id` | int | lista | da `Event.aspx?e=` |
| `url` | Uri | lista | assoluto su `buonacaccia.agesci.it` |
| `sigla` | String | lista | `PO`, `CapiSq`, `CFM L/C`…; può essere vuota |
| `branca` | enum | lista | da `branch_lc/eg/rs/fc/aa.png`; nel campione `aa` ha sigle di assemblee e consigli (`AssReg`, `AssZona`, `ConsReg`, `AltroReg`) e l'evento "Speciale" con sigla vuota |
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
| `sottotitolo` | String? | dettaglio | Disponibile anche in lista, dopo il CR nel `title`, ma a volte troncato |
| `capiCampo` | List<String> | dettaglio | split su ` - ` |
| `aperturaIscrizioni`, `chiusuraIscrizioni` | data? | dettaglio | |
| `linkPresentazione` | Uri? | dettaglio | |
| `appuntamenti` | List<Appuntamento> | dettaglio | `dal`, `al` (data), `localita` (String?, null se vuota); lista vuota se l'evento non ne ha (V-14) |
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

Scelte confermate da Andrea l'08/11/2026:
- Formati: all'apertura è selezionato solo il PDF; ne serve almeno uno.
- "Estrai dettagli": oltre 50 eventi si chiede conferma, mostrando il numero di pagine e il
  tempo stimato (circa 0,3-0,5 s per evento, *inferenza* da misurare).
- Anomalie: un riquadro in cima ai risultati con il numero di eventi interessati e un'icona
  sui singoli eventi; i messaggi si leggono aprendo l'evento.
- Tablet: ricerca e risultati affiancati già in F5.

Realizzazione (F5, `lib/ui/`, 08/11/2026):
- Stato con Riverpod: `filtriProvider` (scelte di ricerca) ed `estrazioneControllerProvider`
  (una sola estrazione alla volta: ricerca, eventuale conferma, dettagli, risultato o errore;
  i risultati di un'estrazione annullata vengono scartati). `ProviderScope(retry: null)`: nessun
  nuovo tentativo automatico, ogni richiesta parte da un'azione dell'utente (D-04).
- Sul telefono una sola schermata che passa da Ricerca ad Avanzamento/Risultati; "indietro"
  torna alla ricerca mantenendo le scelte. Da 840 dp di larghezza le due parti sono affiancate.
- Toccando un evento si apre una scheda con tutti i dati, le anomalie e il pulsante "Apri su
  BuonaCaccia" (il tocco non apre subito il browser, così le anomalie si possono leggere).
- La conferma oltre 50 eventi offre tre scelte: estrai i dettagli, solo elenco, annulla.
- "Condividi" mostra per ora un avviso: l'esportazione è F6.
- Verificata sull'emulatore Android contro il sito reale l'08/11/2026 (Piccole Orme, Lazio:
  7 eventi).

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
| Flutter / Dart | Flutter 3.47.9 con Dart 3.13.7 (`flutter --version` del 06/11/2026; ultima stabile secondo l'indice delle release di Flutter) |
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

Rilevati il 06/11/2026 da `pubspec.lock` e dall'API di pub.dev:

| Pacchetto | Versione | Licenza |
| --- | --- | --- |
| `http` | 1.6.0 | BSD-3-Clause |
| `html` | 0.15.7 | MIT (pub.dev indica "unknown"; verificato leggendo il `LICENSE` del pacchetto) |
| `pdf` | 3.12.0 | Apache-2.0 |
| `excel` | 4.0.6 | MIT |
| `share_plus` | 13.3.1 | BSD-3-Clause |
| `path_provider` | 2.1.6 | BSD-3-Clause |
| `url_launcher` | 6.3.3 | BSD-3-Clause |
| `intl` | 0.20.3 | BSD-3-Clause |
| `flutter_riverpod` | 3.4.3 | MIT |
| `cupertino_icons` (da `flutter create`) | 1.0.9 | MIT |
| `flutter_lints` (solo sviluppo) | 6.0.0 | BSD-3-Clause |
| `fake_async` (solo sviluppo, F4) | 1.3.3 | Apache-2.0 |

Anche le dipendenze transitive in `pubspec.lock` hanno licenza MIT, BSD-3-Clause o Apache-2.0.
`excel` 4.0.6 richiede `archive ^3.6.1`: è il vincolo che probabilmente trattiene `pdf` a 3.12.0
(*inferenza*; disponibile 3.13.1).

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
├── test/fixtures/             # HTML anonimizzati
├── tool/capture_fixtures.sh   # cattura pagine in tool/fixtures_raw/ (ignorata da git)
├── tool/anonymize_fixtures.dart, tool/generate_menu.dart
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
| V-01 | **Risolta in F1:** id della griglia, dei `<select>` e del dettaglio confermati e completati sull'HTML grezzo (§1.2) | — |
| V-02 | **Risolta in F1:** parametro GET. Senza `All=1` solo eventi con iscrizioni aperte o da aprire, con `All=1` tutti (§1.2) | P-03 realizzabile senza postback |
| V-03 | **Risolta in F1:** le voci di gruppo funzionano come `CID` ai livelli provati. `1000000` L/C: 15 righe; `4000200` CFM: 27 righe di soli CFM L/C, E/G, R/S; `4010000` Moduli Formativi: 65 righe di MF e formatori | P-04 realizzabile |
| V-04 | **Risolta in F1, entro il volume osservato:** nessun paginatore con 298 righe (`All=1`). Oltre questo numero non è verificabile | Nessuna paginazione; il test settimanale può controllarlo |
| V-05 | **Risolta in F1:** sì, è HTML. Nel campione: `<p>`, `<br />`, `<strong>`, `<a href>`, entità (`&agrave;`, `&nbsp;`). Può citare persone reali e IBAN | Il parser deve convertirlo in testo conservando gli URL; attenzione ai dati personali nelle fixture |
| V-06 | Autorizzazione scritta AGESCI: a chi chiederla, e se copre scraping, nome e logo. Bozza della richiesta preparata l'08/11/2026; destinatario da scegliere (Andrea) | Nessun logo (P-06) |
| V-07 | **Risolta l'08/11/2026 (Andrea):** nome "Eventi in tasca", repository pubblico `AntaresNetOrg/eventi-in-tasca` | — |
| V-08 | Costi e requisiti attuali di Apple Developer Program e Google Play Console; obbligo di informativa privacy | Da verificare alla pubblicazione |
| V-09 | 12 tester per il test chiuso su Play | — |
| V-10 | Layout del PDF (tabella o schede) leggibile su telefono | Mockup prima di F6 |
| V-11 | **Letta l'08/11/2026** (una GET ciascuna, autorizzata da Andrea): `robots.txt` vieta solo `/admin/` e `/utenti/` e consente il resto. `Privacy.aspx` è l'informativa del sito (titolare AGESCI; log con IP conservati 12 mesi). `Instructions.aspx` contiene istruzioni per le iscrizioni. In nessuna delle tre ci sono condizioni d'uso sul riuso dei dati o sull'accesso automatico: nessun divieto, ma nemmeno un permesso. `About.aspx` non è stata letta | L'autorizzazione AGESCI (V-06) resta necessaria |
| V-12 | **Risolta in F0:** il `_` viene convertito solo per iOS (`eventi_bc` → `eventiBc`); valori in §12 | Fissarli prima del primo caricamento sugli store |
| V-13 | **Risolta il 06/11/2026 (Andrea):** l'etichetta resta "Chiuse" anche per gli eventi non ancora aperti, perché nessuno può iscriversi (D-09) | — |
| V-14 | **Risolta il 06/11/2026 (Andrea):** con "Estrai dettagli" si estraggono date e località dei singoli appuntamenti (D-11, §3) | — |

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
- versioni delle action GitHub aggiornate in F0 (06/11/2026): `actions/checkout@v7` (node24),
  `subosito/flutter-action@v2` (ultima major; v2.23.0, composite, usa `actions/cache@v5` su node24);
- nessuna configurazione di esecuzione `.run/`: Android Studio crea quella di `main.dart` all'apertura
  (*inferenza*).

Identificativi (P-10, V-12):

| Piattaforma | Identificativo | Stato |
| --- | --- | --- |
| Android `applicationId` e `namespace` | `org.antaresnet.eventi_in_tasca` | Deciso da Andrea l'08/11/2026 |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `org.antaresnet.eventi-in-tasca` | Deciso da Andrea l'08/11/2026: iOS non ammette `_` |
| Nome visualizzato | "Eventi in tasca" | Android `android:label`, iOS `CFBundleDisplayName` e `CFBundleName` |

Gli identificativi non si possono cambiare dopo il primo caricamento sugli store: se il nome
definitivo (V-07) arriva dopo F0, vanno aggiornati prima di F7.
