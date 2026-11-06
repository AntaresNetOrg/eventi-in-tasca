# eventi_bc (nome provvisorio)

[![Licenza: MIT](https://img.shields.io/badge/licenza-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Piattaforme](https://img.shields.io/badge/piattaforme-Android%20%7C%20iOS-lightgrey.svg)](#)
[![App non ufficiale](https://img.shields.io/badge/app-non%20ufficiale%20AGESCI-orange.svg)](#app-non-ufficiale)
<!-- Badge CI da aggiungere quando sarà deciso il repository (V-07):
[![CI](https://github.com/<owner>/<repo>/actions/workflows/ci.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/ci.yml)
-->

App per telefoni e tablet che estrae dal portale
[BuonaCaccia](https://buonacaccia.agesci.it/Events.aspx) l'elenco degli eventi di un
tipo (per esempio Piccole Orme, campi Capi Squadriglia), facoltativamente di una sola
regione, e lo esporta in **PDF** e/o **Excel** da condividere con genitori e ragazzi.

## App non ufficiale

Questa app **non sostituisce BuonaCaccia**: ne semplifica la consultazione degli eventi.
Iscrizioni, informazioni ufficiali e dati aggiornati restano su
[buonacaccia.agesci.it](https://buonacaccia.agesci.it).

- Legge solo le pagine pubbliche dell'elenco eventi e dei singoli eventi.
- Non accede ad aree riservate e non chiede credenziali.
- Non salva nulla sul dispositivo; il file da condividere è temporaneo.
- Nessuna analitica, nessun tracciamento, nessuna pubblicità.

## Funzioni

- Scelta del tipo di evento e, facoltativamente, della regione.
- Elenco con titolo, regione, partenza, rientro, quota, località, iscritti, stato.
- Opzione "Estrai dettagli": capi campo, apertura e chiusura iscrizioni, link di
  presentazione, informazioni dalla segreteria, contatti.
- Esportazione in PDF e/o Excel e condivisione.

## Sviluppo

Progetto Flutter, sviluppato con Android Studio e Claude Code.

- Specifica: [`docs/Progettazione.md`](docs/Progettazione.md)
- Istruzioni per lo sviluppo: [`CLAUDE.md`](CLAUDE.md)

```bash
mise run analyze
mise run test
flutter run
```

## Licenza

Codice: [MIT](LICENSE) © 2026 Andrea Bruno.
Font Titillium Web: [SIL Open Font License 1.1](assets/fonts/OFL.txt).

AGESCI e BuonaCaccia sono dell'Associazione Guide e Scouts Cattolici Italiani; questa
app non è un prodotto ufficiale dell'associazione.
