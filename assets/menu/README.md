# Elenco di riserva dei menu (D-03)

Qui andrà `menu.json` con regioni (`RID`) e tipi evento (`CID`), usato **solo** quando
il sito non è raggiungibile. È una risorsa inclusa nell'app, non scritta sul dispositivo.

Il file si genera in F1 dai `<select>` dell'HTML reale di `Events.aspx`, mai a mano o a
memoria. Valori noti finora, da riconfermare sull'HTML (Progettazione §1.2):
`RID=H` Lazio e `CID=1010101` Piccole Orme (verificati sul sito il 05/11/2026);
`RID=A` Nazionale, `E` Campania, `CID=2010101` Specialità, `2010102` Capi Squadriglia,
`2010104` Competenza, `2010105` Candidature Competenza (da BCEventScraper-rs).
