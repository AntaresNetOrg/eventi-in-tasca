# Elenco di riserva dei menu (D-03)

`menu.json` contiene regioni (`rid`) e tipi evento (`cid`), ed è usato **solo** quando il
sito non è raggiungibile. È una risorsa inclusa nell'app, non scritta sul dispositivo.

Si genera con `mise run menu` dai `<select>` dell'HTML reale di `Events.aspx` catturato con
`mise run fixtures`, mai a mano o a memoria. `catturatoIl` indica la data della pagina usata.
`gruppo` distingue le voci di gruppo del menu; solo per queste `livello` riporta il numero
della classe CSS `LevelN` del sito.
