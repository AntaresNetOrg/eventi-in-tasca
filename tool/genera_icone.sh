#!/usr/bin/env bash
# Generates the launcher and store icons from the SVG sources in docs/icona/ (D-13, F7).
# Requires Inkscape (SVG -> PNG) and ImageMagick (resize, alpha removal).
# The PNGs are committed: run this again only after changing an SVG.
#
#   tool/genera_icone.sh
set -euo pipefail

cd "$(dirname "$0")/.."
src=docs/icona
res=android/app/src/main/res
ios=ios/Runner/Assets.xcassets/AppIcon.appiconset
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

command -v inkscape >/dev/null || { echo "Inkscape non trovato" >&2; exit 1; }
command -v magick >/dev/null || { echo "ImageMagick non trovato" >&2; exit 1; }

render() { # svg size out
  inkscape "$1" --export-type=png --export-width="$2" --export-height="$2" \
    --export-filename="$3" >/dev/null 2>&1
}

# High-resolution masters, downscaled below.
render "$src/icona.svg" 1024 "$tmp/full.png"
render "$src/icona_primo_piano.svg" 1024 "$tmp/fg.png"
render "$src/icona_monocromatica.svg" 1024 "$tmp/mono.png"

# Android: legacy icon (48 dp) and adaptive layers (108 dp) per density.
for pair in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  dpi=${pair%%:*}
  scale=${pair##*:}
  legacy=$(awk "BEGIN { print int(48 * $scale) }")
  layer=$(awk "BEGIN { print int(108 * $scale) }")
  mkdir -p "$res/mipmap-$dpi" "$res/drawable-$dpi"
  magick "$tmp/full.png" -resize "${legacy}x${legacy}" "$res/mipmap-$dpi/ic_launcher.png"
  magick "$tmp/fg.png" -resize "${layer}x${layer}" "$res/drawable-$dpi/ic_launcher_foreground.png"
  magick "$tmp/mono.png" -resize "${layer}x${layer}" "$res/drawable-$dpi/ic_launcher_monochrome.png"
done

# iOS: every size listed in Contents.json, without alpha (App Store requirement).
grep -o '"filename" *: *"[^"]*"' "$ios/Contents.json" | sed 's/.*"\([^"]*\)"$/\1/' |
  while read -r name; do
    # Icon-App-<points>x<points>@<scale>x.png
    points=$(echo "$name" | sed -E 's/^Icon-App-([0-9.]+)x.*/\1/')
    factor=$(echo "$name" | sed -E 's/.*@([0-9]+)x\.png$/\1/')
    px=$(awk "BEGIN { print int($points * $factor + 0.5) }")
    magick "$tmp/full.png" -resize "${px}x${px}" -background '#1E4A30' -alpha remove \
      -alpha off "PNG24:$ios/$name"
  done

# Store listing (Google Play): icon 512x512 and feature graphic 1024x500.
mkdir -p docs/store
magick "$tmp/full.png" -resize 512x512 -depth 8 docs/store/icona_512.png

fonts=assets/fonts
render "$src/icona_primo_piano.svg" 640 "$tmp/art.png"
magick -size 1024x500 xc:'#1E4A30' \
  \( "$tmp/art.png" \) -geometry +-90+-70 -composite \
  -font "$fonts/TitilliumWeb-Bold.ttf" -pointsize 76 -fill white \
  -annotate +470+215 'Eventi in tasca' \
  -font "$fonts/TitilliumWeb-SemiBold.ttf" -pointsize 36 -fill '#F2B33D' \
  -annotate +474+280 'Gli eventi di BuonaCaccia' \
  -annotate +474+326 'in PDF ed Excel, da condividere' \
  -font "$fonts/TitilliumWeb-Regular.ttf" -pointsize 24 -fill '#CFE3D5' \
  -annotate +474+390 'App non ufficiale' \
  -alpha off -depth 8 docs/store/grafica_1024x500.png

echo "Icone generate."
