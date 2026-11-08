# Pubblicazione sugli store — istruzioni

Guida per la fase F7: pubblicare "Eventi in tasca" su Google Play e sull'App Store.
Scritta l'08/11/2026. I requisiti degli store cambiano spesso: ogni punto riporta la fonte e
se è **verificato** (pagina ufficiale letta l'08/11/2026), **da confermare** (fonte non
ufficiale o non letta per intero) o **inferenza**. Prima di ogni passo, fa fede quello che
mostrano Play Console e App Store Connect.

Legenda: 👤 = lo può fare solo Andrea (account, pagamenti, documenti, firme).
🤖 = si può fare nel repository con Claude Code.

---

## 0. Ordine consigliato

1. 👤 Chiedere l'autorizzazione scritta ad AGESCI (V-06). Serve per Apple e protegge anche su
   Google Play. Si può fare tutto il resto in parallelo, ma **non** pubblicare in produzione
   senza.
2. 👤 Aprire gli account sviluppatore (§2) e dichiarare lo stato di operatore UE (§2.3).
3. 🤖 Preparare il repository (§3): icone, firma Android, versione, informativa pubblicata.
4. 👤 Preparare testi e immagini delle schede (§4).
5. Android: test interno → test chiuso con 12 tester per 14 giorni → produzione (§5).
6. iOS: TestFlight → revisione → pubblicazione (§6). Può procedere in parallelo ai 14 giorni
   del test chiuso Android.

---

## 1. Requisiti attuali degli store (V-08)

| Requisito | Valore | Stato | Fonte |
| --- | --- | --- | --- |
| Play: API di destinazione per app nuove e aggiornamenti | Android 16 (API 36) dal 31/08/2026 | Verificato | [developer.android.com — Target API level](https://developer.android.com/google/play/requirements/target-sdk) |
| L'app oggi | `targetSdk = 36`, `compileSdk = 36`, `minSdk = 24` (valori predefiniti di Flutter 3.47.9) | Verificato nel repository | `flutter_tools/.../FlutterExtension.kt` |
| Play: account personali creati dopo il 13/11/2023 | Test chiuso con almeno **12 tester** iscritti **senza interruzioni per 14 giorni** prima di poter chiedere la produzione | Verificato | [Play Console Help 14151465](https://support.google.com/googleplay/android-developer/answer/14151465) |
| Play: costo dell'account | Quota una tantum (25 USD secondo fonti non ufficiali) | Importo da confermare | [Play Console Help 6112435](https://support.google.com/googleplay/android-developer/answer/6112435) |
| Play: verifica d'identità | Documento d'identità e carta di credito intestati al titolare | Verificato (pagina ufficiale) | stessa fonte |
| Apple: SDK per i caricamenti | Xcode 26 o successivo, SDK iOS 26, dal 28/04/2026 | Verificato | [Apple — Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) |
| L'app oggi | iOS minimo 15.0 (`IPHONEOS_DEPLOYMENT_TARGET`) | Verificato nel repository | `ios/Runner.xcodeproj` |
| Apple: costo | Abbonamento annuale (99 USD l'anno secondo fonti non ufficiali; in Italia il prezzo è in euro) | Da confermare | pagina di iscrizione all'Apple Developer Program |
| Apple e Google: Digital Services Act | Dichiarazione obbligatoria di "operatore commerciale" (trader) o no; se trader, indirizzo, telefono ed email diventano pubblici nella scheda UE | Apple verificato; Google da confermare in console (scadenza indicata da fonti non ufficiali: febbraio 2027) | [App Store Connect Help — DSA](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-compliance-information) |
| Apple: linea guida 5.2.2 | Un'app che mostra contenuti di un servizio terzo deve esserne autorizzata; l'autorizzazione va fornita su richiesta | Verificato il 05/11/2026 (D-12) | App Store Review Guidelines |

---

## 2. Account (👤)

### 2.1 Google Play Console

1. Vai su <https://play.google.com/console/signup> con l'account Google che userai per
   sempre (non si trasferisce facilmente). Tipo di account: **personale** (D-12).
2. Inserisci nome legale, indirizzo, telefono, email di contatto; carica il documento
   d'identità; paga la quota con una carta intestata a te.
3. Attendi la verifica (nessun tempo garantito). Verifica anche telefono ed email dalla
   console.
4. *Da confermare:* Google sta introducendo la "verifica sviluppatore Android" per tutte le
   app installabili sui dispositivi certificati. Per chi pubblica su Play la registrazione in
   Play Console dovrebbe bastare; controlla i banner della console.

### 2.2 Apple Developer Program

1. Serve un **Mac con Xcode 26 o successivo** (requisito di caricamento, §1).
2. Attiva l'autenticazione a due fattori sull'Apple ID.
3. Iscriviti come **individuo** su <https://developer.apple.com/programs/enroll/> (dal sito
   o dall'app Apple Developer). Paga l'abbonamento annuale.
4. Su App Store Connect → **Accordi, imposte e coordinate bancarie**: accetta il Free Apps
   Agreement. Per un'app gratuita non servono coordinate bancarie (*inferenza*).

### 2.3 Stato di operatore commerciale (DSA)

Da dichiarare su entrambi gli store (Apple: App Store Connect → Business; Google: Play Console
→ Dettagli account → Dichiara stato).

- L'app è gratuita, senza pubblicità né acquisti e non legata a un'attività d'impresa: la
  scelta naturale è **non operatore commerciale**, e in questo caso i tuoi recapiti non
  diventano pubblici. È una valutazione legale tua: questo documento non la può fare per te.
- Se ti dichiari operatore, indirizzo, telefono ed email saranno visibili agli utenti UE: in
  quel caso valuta di usare recapiti di AntaresNet anziché personali.

---

## 3. Preparazione del repository (🤖, con le tue scelte)

Ognuno di questi punti è un commit separato, con analyze e test verdi.

### 3.1 Icone

Sorgente: `docs/icona/icona.svg` (D-13).

- **Android:** icona adattiva (primo piano = calendario e tasca, sfondo = verde `#1E4A30`)
  in `mipmap-anydpi-v26`, più le PNG di riserva in `mipmap-*dpi`. Icona monocromatica per i
  temi di Android 13+.
- **iOS:** `AppIcon.appiconset`, partendo dalla 1024×1024 **senza trasparenza** (Apple la
  rifiuta).
- **Store:** PNG 512×512 per Play; la 1024×1024 per Apple viene presa dal pacchetto.
- Strumento: `flutter_launcher_icons` solo come dipendenza di sviluppo e solo dopo aver
  verificato la licenza su pub.dev (regola 11); in alternativa le immagini si generano una
  volta con uno script in `tool/` e si committano.

### 3.2 Firma Android (upload key)

Google firma l'app distribuita (Play App Signing); tu firmi solo il pacchetto che carichi,
con una **chiave di caricamento**.

1. 👤 Crea la chiave **fuori dal repository** e salvane una copia di sicuro (gestore di
   password). Se la perdi si può reimpostare tramite l'assistenza Google, ma è una procedura
   lenta.
   ```bash
   keytool -genkey -v -keystore ~/chiavi/eventi-in-tasca-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. 👤 Crea `android/key.properties` (già escluso da git, righe 22–25 di `.gitignore`):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/bruand/chiavi/eventi-in-tasca-upload.jks
   ```
3. 🤖 In `android/app/build.gradle.kts`: leggere `key.properties` e usare quella firma per il
   build `release`; oggi `release` usa la firma di debug (riga 36). Se il file manca, il build
   `release` deve fallire con un messaggio chiaro anziché firmare in debug.

### 3.3 Versione

- `pubspec.yaml` → `version: 1.0.0+1` (nome visibile + numero di build). Il numero di build
  deve crescere a **ogni** caricamento, su entrambi gli store.
- 🤖 `lib/data/bc_client.dart` ha `appVersion = '1.0.0'` scritto a mano per lo User-Agent:
  va tenuto allineato al `pubspec.yaml`, oppure ricavato in fase di build
  (`--dart-define`), così non si dimentica.

### 3.4 iOS

- 🤖 `Info.plist`: aggiungere `ITSAppUsesNonExemptEncryption = false`. L'app usa solo HTTPS
  del sistema, che è esente (*inferenza* da confermare: App Store Connect lo chiede comunque a
  ogni build se la chiave manca).
- *Da verificare al primo caricamento:* manifest della privacy (`PrivacyInfo.xcprivacy`). I
  plugin Flutter ne hanno uno proprio; se App Store Connect segnala API "required reason"
  nell'app, se ne aggiunge uno a livello di app.
- In Xcode → Runner → Signing & Capabilities: Team = il tuo account, firma automatica,
  Bundle Identifier `org.antaresnet.eventi-in-tasca`.

### 3.5 Informativa privacy su GitHub Pages (P-05)

1. 👤 Scegli l'indirizzo email di contatto da scrivere nell'informativa (oggi "da definire").
   Consiglio: una casella di AntaresNet o un alias dedicato, non l'email personale.
2. 🤖 Completare `docs/privacy.md`: togliere "bozza", aggiungere contatto e data, correggere la
   frase sui file temporanei secondo la decisione su V-15.
3. 🤖 Pubblicarla con GitHub Pages dalla cartella `docs/` del ramo `main` (Settings → Pages),
   più una pagina di supporto (`docs/index.md`: cos'è l'app, nota "non ufficiale", come
   segnalare un problema tramite le issue).
   Indirizzi risultanti (*inferenza*, da controllare dopo l'attivazione):
   `https://antaresnetorg.github.io/eventi-in-tasca/privacy` e
   `https://antaresnetorg.github.io/eventi-in-tasca/`.
4. Attenzione: con Pages su `docs/` diventano pubbliche come pagine web anche
   `Progettazione.md` e questo file. Sono già pubblici nel repository, quindi non cambia nulla
   sul piano della riservatezza; se preferisci, si usa una cartella dedicata (`site/`) tramite
   un workflow.

### 3.6 Pacchetti da caricare

```bash
flutter build appbundle --release     # → build/app/outputs/bundle/release/app-release.aab
flutter build ipa --release           # → build/ios/ipa/*.ipa (solo su Mac, con firma configurata)
```

Prima di ogni caricamento: `mise run analyze`, `mise run test`, e il test live
(`flutter test --run-skipped --tags live`) per essere sicuri che il sito non sia cambiato.

---

## 4. Materiali per le schede (👤, con bozze 🤖)

| Elemento | Google Play | App Store |
| --- | --- | --- |
| Nome | "Eventi in tasca" (max 30 caratteri) | "Eventi in tasca" (max 30) |
| Sottotitolo / descrizione breve | max 80 caratteri | sottotitolo max 30 |
| Descrizione | max 4000 caratteri | max 4000 |
| Parole chiave | — | max 100 caratteri |
| Icona | PNG 512×512 | dal pacchetto |
| Grafica in evidenza | PNG/JPG 1024×500, obbligatoria | — |
| Screenshot | telefono (almeno 2); tablet consigliati | iPhone 6,9" obbligatori; iPad se l'app gira su iPad |
| Categoria | Strumenti o Produttività | Utility o Produttività |
| Informativa privacy | URL (§3.5) | URL (§3.5) |
| Sito / supporto | URL (§3.5) | URL di supporto obbligatorio |
| Email di contatto | obbligatoria, pubblica | — |

Limiti e dimensioni: valori noti al momento della scrittura, da confermare nei moduli delle
console, che li indicano accanto a ogni campo.

**La descrizione deve contenere la frase di D-00:**
> App non ufficiale: semplifica la consultazione degli eventi di BuonaCaccia; iscrizioni e
> informazioni ufficiali restano su buonacaccia.agesci.it.

Bozza di descrizione breve (78 caratteri):
> Elenca gli eventi di BuonaCaccia e condividili in PDF o Excel. App non ufficiale.

Regole per testi e immagini:
- Niente logo AGESCI, giglio o trifoglio, niente "ufficiale" (D-00, P-06), salvo diversa
  indicazione nell'autorizzazione di AGESCI.
- 🤖 Screenshot dall'emulatore con dati reali: controllare che nelle schermate non compaiano
  nomi di capi campo o recapiti personali (regola 9). Usare ricerche senza "Estrai dettagli"
  oppure eventi con soli recapiti istituzionali.

---

## 5. Google Play, passo per passo

### 5.1 Crea l'app

Play Console → **Crea app**: nome "Eventi in tasca", lingua predefinita italiano, App, Gratuita,
accetta le dichiarazioni. Il nome del pacchetto si fissa al primo caricamento:
`org.antaresnet.eventi_in_tasca` (non modificabile dopo).

### 5.2 Contenuti dell'app (Policy → Contenuti dell'app)

| Sezione | Risposta |
| --- | --- |
| Norme sulla privacy | URL dell'informativa |
| Annunci | No, l'app non contiene annunci |
| Accesso all'app | Tutte le funzionalità disponibili senza restrizioni (nessun login) |
| Classificazione dei contenuti | Questionario IARC: categoria "Utilità/Produttività"; nessun contenuto sensibile; nessuna interazione tra utenti. L'app mostra testi di terzi (BuonaCaccia), non generati dagli utenti |
| Pubblico di destinazione | **18 anni e oltre** (gli utenti sono capi e genitori). Scegliere fasce sotto i 13 anni attiva il programma Famiglie, con requisiti aggiuntivi |
| App di notizie | No |
| App governative | No |
| Funzionalità finanziarie | Nessuna |
| Salute | Nessuna |
| Sicurezza dei dati | Vedi §5.3 |

### 5.3 Sicurezza dei dati (Data safety)

Risposte proposte:
- **L'app raccoglie o condivide dati utente?** No.
- Motivazione: l'app non invia dati dell'utente a nessuno. Fa solo GET su pagine pubbliche di
  BuonaCaccia con i filtri scelti (tipo di evento, regione); non legge contatti, posizione,
  file o identificativi. I file esportati restano sul dispositivo finché l'utente non li
  condivide di sua iniziativa con il menu di sistema.
- *Inferenza da confermare leggendo le definizioni del modulo:* l'indirizzo IP che arriva a
  BuonaCaccia come a qualunque browser non rientra nei "dati raccolti" dall'app. Se il modulo
  lo considera tale, si dichiara come dato trasmesso a terzi.

Con "No" il modulo non chiede crittografia in transito né cancellazione dei dati.

### 5.4 Scheda dello store

Store principale → Scheda dello store principale: testi e immagini del §4. Impostazioni dello
store: categoria, email di contatto, sito.

### 5.5 Test interno (facoltativo, consigliato)

Test → Test interno → crea release → carica `app-release.aab`. Aggiungi te stesso come tester,
installa dal link di adesione e prova l'intero flusso sul telefono vero. È anche il momento per
chiudere **V-15** (condividere su Gmail e WhatsApp e controllare che l'allegato arrivi).

### 5.6 Test chiuso con 12 tester (V-09)

1. Test → Test chiuso → crea un canale (es. "Capi tester").
2. Tester: crea un elenco con le email Google dei capi (almeno 12, meglio 15–20 perché
   qualcuno si disiscrive o non usa l'app) oppure un Google Group.
3. Paesi: Italia. Carica la release e inviala in revisione (la prima revisione può richiedere
   alcuni giorni).
4. Manda ai tester il link di adesione. Ognuno deve: aprire il link con l'account Google
   dell'elenco → "Diventa un tester" → installare da Play. Chi si disiscrive prima dei 14
   giorni non conta.
5. Chiedi ai tester di usare davvero l'app più volte nei 14 giorni e di lasciare un feedback
   privato: Google valuta anche il coinvolgimento e può chiedere altro test.
6. Durante il test puoi caricare correzioni (numero di build crescente) senza azzerare i
   14 giorni (*inferenza*: la regola conta i tester iscritti, non le release).

### 5.7 Richiesta di accesso alla produzione

Dopo i 14 giorni la Dashboard sblocca **Richiedi l'accesso alla produzione**. Il questionario
chiede come hai trovato i tester, che feedback hai ricevuto, cosa hai cambiato, a chi è rivolta
l'app e quante installazioni ti aspetti. Risposte sincere e concrete; la revisione può
richiedere fino a circa una settimana (*da confermare*).

### 5.8 Produzione

Produzione → crea release → stessa versione del test chiuso (o successiva) → note di rilascio in
italiano → Paesi: Italia (eventualmente tutti) → invia in revisione. Puoi usare un rilascio
graduale (es. 20%) e completarlo dopo qualche giorno.

---

## 6. App Store, passo per passo

### 6.1 Identificativo e app

1. developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → App ID esplicito
   `org.antaresnet.eventi-in-tasca`, senza capability aggiuntive. (Con la firma automatica Xcode
   lo crea da sé.)
2. App Store Connect → App → **+** → Nuova app: iOS, nome "Eventi in tasca", lingua principale
   italiano, bundle ID quello sopra, SKU a scelta (es. `eventi-in-tasca`), accesso completo.

### 6.2 Build e caricamento

```bash
flutter build ipa --release
```
poi apri `build/ios/archive/Runner.xcarchive` in Xcode → Organizer → **Distribute App** →
App Store Connect. In alternativa carica il `.ipa` con l'app Transporter. La build compare
in App Store Connect dopo l'elaborazione (in genere minuti). Se compaiono avvisi su crittografia
o manifest della privacy, vedi §3.4.

### 6.3 TestFlight

- Test interni (fino a 100 membri del tuo account): disponibili subito.
- Test esterni (i capi, con link pubblico o email): la prima build passa una revisione
  TestFlight rapida. Utile per far provare l'app agli stessi capi del test Android.

### 6.4 Informazioni dell'app

| Sezione | Risposta |
| --- | --- |
| Privacy dell'app | URL informativa; **Dati non raccolti** |
| Classificazione per età | Questionario: nessun contenuto elencato; accesso web libero = No (l'app apre le pagine di BuonaCaccia nel browser esterno, non contiene un browser) |
| Categoria | Utility (principale), Produttività (secondaria) |
| Prezzo e disponibilità | Gratuita; Italia o tutti i Paesi |
| Copyright | "2026 Andrea Bruno" |
| URL di supporto | pagina del §3.5 |
| Dispositivi | iPhone e iPad (l'app ha il layout tablet); servono screenshot iPad |

### 6.5 Note per la revisione (App Review Information)

- Accesso: nessun account richiesto (lasciare vuote le credenziali demo).
- Contatto: nome, telefono, email (visibili solo ad Apple).
- Allegato: **l'autorizzazione scritta di AGESCI** (PDF), per la linea guida 5.2.2.
- Testo proposto:

> Eventi in tasca è un'app gratuita e non ufficiale per i capi scout AGESCI. Legge le pagine
> pubbliche del catalogo eventi di BuonaCaccia (buonacaccia.agesci.it), il portale
> dell'associazione, e permette di condividere l'elenco degli eventi in PDF o Excel. Non
> richiede account, non raccoglie dati e non offre iscrizioni: per ogni evento rimanda alla
> pagina ufficiale. In allegato l'autorizzazione di AGESCI all'uso dei contenuti.
> Per provarla: scegliere un tipo di evento (es. "Campi di Formazione Metodologica"), toccare
> "Estrai", poi "Condividi".

  (🤖 Prima dell'invio controllare che il nome del tipo di evento citato esista nel menu.)

### 6.6 Rischi noti della revisione Apple

- **5.2.2 (contenuti di terzi):** senza l'autorizzazione AGESCI il rifiuto è probabile.
- **4.2 (funzionalità minima):** Apple può considerare l'app un semplice "involucro" di un sito.
  Argomenti: esportazione PDF/Excel, layout per tablet, lettura dei dettagli in parallelo,
  funziona anche con menu di riserva senza rete. Se contestato, rispondere nel Resolution
  Center con questi punti.
- **Nome:** niente riferimenti ad AGESCI o BuonaCaccia nel nome o nel sottotitolo (solo nella
  descrizione), per non sembrare ufficiale (D-00).

Poi **Aggiungi per la revisione** → **Invia**. Alla scelta della pubblicazione, "manuale"
permette di decidere il giorno dopo l'approvazione.

---

## 7. Dopo la pubblicazione

- Aggiornare `README.md` con i link agli store e `docs/Progettazione.md` (F7 completata,
  V-06, V-08, V-09 risolte).
- Il workflow settimanale `live.yml` resta il primo allarme: se apre una issue, il sito è
  cambiato e serve un aggiornamento rapido.
- Ogni aggiornamento: numero di build +1, `appVersion` allineata, test live, poi stessi
  canali (test chiuso → produzione su Play; TestFlight → revisione su Apple). Dopo l'accesso
  alla produzione, su Play il test chiuso non è più obbligatorio per gli aggiornamenti
  (*inferenza*).
- Ogni anno: controllare il nuovo livello API richiesto da Play (in genere a fine agosto) e
  la versione minima di Xcode richiesta da Apple (in genere in primavera); rinnovare
  l'abbonamento Apple, altrimenti l'app sparisce dall'App Store.

---

## 8. Riepilogo delle azioni di Andrea

- [ ] Inviare la richiesta di autorizzazione ad AGESCI (V-06) e ottenere la risposta scritta
- [ ] Aprire l'account Google Play Console (personale) e completare la verifica d'identità
- [ ] Iscriversi all'Apple Developer Program e accettare il Free Apps Agreement
- [ ] Dichiarare lo stato DSA su entrambi gli store
- [ ] Scegliere l'email di contatto per informativa e schede
- [ ] Creare la chiave di caricamento Android e `android/key.properties`
- [ ] Trovare almeno 12 tester (meglio 15–20) con account Google (V-09)
- [ ] Rivedere testi delle schede e screenshot
- [ ] Confermare la scelta su V-15 dopo la prova sul telefono

## 9. Riepilogo dei lavori nel repository (🤖, su richiesta)

- [ ] Icone Android (adattiva + monocromatica) e iOS da `docs/icona/icona.svg`
- [ ] Firma `release` da `key.properties` in `build.gradle.kts`
- [ ] `appVersion` allineata al `pubspec.yaml`
- [ ] `ITSAppUsesNonExemptEncryption` in `Info.plist`
- [ ] Informativa completa e pagina di supporto su GitHub Pages
- [ ] Bozze dei testi delle schede e screenshot senza dati personali
- [ ] Grafica in evidenza 1024×500 per Play

## Fonti

- [Google Play — Target API level requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Play Console Help — App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Play Console Help — Registrazione dell'account](https://support.google.com/googleplay/android-developer/answer/6112435)
- [Android developer verification — FAQ](https://developer.android.com/developer-verification/guides/faq)
- [Apple — Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)
- [App Store Connect Help — EU Digital Services Act](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-compliance-information)
- [Apple — Apps without trader status will be removed](https://developer.apple.com/news/?id=einwn76m)
- App Store Review Guidelines, 4.2 e 5.2.2: <https://developer.apple.com/app-store/review/guidelines/>
