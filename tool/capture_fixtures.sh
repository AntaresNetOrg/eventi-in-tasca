#!/usr/bin/env bash
# Scarica pagine di BuonaCaccia in tool/fixtures_raw/ per costruire le fixture dei test.
#
# I file scaricati NON sono anonimizzati (contengono nomi reali dei capi campo):
# la cartella è ignorata da git. Le fixture da committare si producono con lo
# script di anonimizzazione (fase F1) in test/fixtures/.
#
# Uso:
#   bash tool/capture_fixtures.sh                 # pagine di default
#   bash tool/capture_fixtures.sh 26533 26719     # dettagli di eventi specifici
set -euo pipefail

BASE="https://buonacaccia.agesci.it"
# User-Agent identificabile, senza email (D-04).
UA="eventi_bc-dev/0.1 (cattura fixture per test; app non ufficiale)"
OUT="$(cd "$(dirname "$0")" && pwd)/fixtures_raw"
PAUSE=2  # secondi tra una richiesta e l'altra

mkdir -p "$OUT"

fetch() {
  local name="$1" url="$2"
  echo "→ $name  ($url)"
  curl -sS --fail --max-time 30 -A "$UA" -o "$OUT/$name.html" "$url"
  sleep "$PAUSE"
}

# Elenchi (casi verificati il 05/11/2026, Progettazione §1.2)
fetch "events_all"            "$BASE/Events.aspx"
fetch "events_lazio_po"       "$BASE/Events.aspx?RID=H&CID=1010101"

# Dettagli: 26719 (base), 26870 (sottotitolo), 26533 (link di presentazione + segreteria)
IDS=("$@")
if [ ${#IDS[@]} -eq 0 ]; then
  IDS=(26719 26870 26533)
fi
for id in "${IDS[@]}"; do
  fetch "event_$id" "$BASE/Event.aspx?e=$id"
done

echo "Fatto: $(ls "$OUT" | wc -l | tr -d ' ') file in $OUT"
echo "Ricorda: non committare questi file; anonimizzali prima (test/fixtures/)."
