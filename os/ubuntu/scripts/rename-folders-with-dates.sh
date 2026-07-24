#!/usr/bin/env bash

DIR="${1:-.}"

for entry in "$DIR"/*; do
  [ -d "$entry" ] || continue
  name="$(basename -- "$entry")"

  # Si ja comença amb data YYYY-MM-DD → no fem res
  if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}([[:space:]]|-) ]]; then
    echo "⏩ Ja correcte: '$name'"
    continue
  fi

  new_date=""
  match=""

  # Busquem data al nom (última coincidència)
  match=$(printf '%s\n' "$name" | grep -oE '([0-9]{1,2})[-/]+([0-9]{1,2})[-/]+([0-9]{2,4})' | tail -n1 || true)

  if [[ -n "$match" ]]; then
    # Separar
    read -r d m y <<< "$(printf '%s\n' "$match" | sed -E 's#[-/]# #g')"
    if [[ ${#y} -eq 2 ]]; then
      y=$((2000 + 10#$y))
    fi
    if new_date=$(date -d "$y-$m-$d" +%F 2>/dev/null); then
      : # vàlida
    else
      echo "⚠️  Data invàlida trobada '$match' dins '$name'"
      new_date=""
    fi
  fi

  # Si encara no tenim data → intentem extreure EXIF
  if [[ -z "$new_date" ]]; then
    first_photo=$(find "$entry" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | head -n1)
    if [[ -n "$first_photo" ]]; then
      exif_date=$(exiftool -s -s -s -DateTimeOriginal "$first_photo" 2>/dev/null | head -n1)
      if [[ -n "$exif_date" ]]; then
        # exiftool retorna "YYYY:MM:DD HH:MM:SS"
        y=$(echo "$exif_date" | cut -d: -f1)
        m=$(echo "$exif_date" | cut -d: -f2)
        d=$(echo "$exif_date" | cut -d: -f3 | awk '{print $1}')
        if new_date=$(date -d "$y-$m-$d" +%F 2>/dev/null); then
          autodate=true
        fi
      fi
    fi
  fi

  # Si tampoc no tenim EXIF → demanem manualment
  if [[ -z "$new_date" ]]; then
    while true; do
      read -rp "No s'ha detectat data per '$name'. Introdueix data (YYYY-MM-DD): " input
      if date -d "$input" +%F >/dev/null 2>&1; then
        new_date=$(date -d "$input" +%F)
        break
      fi
      echo "Data invàlida, torna-ho a provar."
    done
  fi

  # Eliminem la coincidència trobada (si n'hi havia)
  clean_name="$name"
  if [[ -n "$match" ]]; then
    clean_name=$(perl -e '$_=shift; $m=shift; s/\Q$m\E(?!.*\Q$m\E)//s; print $_' "$name" "$match")
  fi

  # Substituïm guions per espais
  clean_name=$(printf '%s' "$clean_name" | tr '-' ' ')
  clean_name=$(echo "$clean_name" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')

  # Construïm nom final
  if [[ "$autodate" == true ]]; then
    new_name="$new_date - $clean_name - AUTODATE"
  else
    new_name="$new_date - $clean_name"
  fi

  # Evitem col·lisions
  target="$DIR/$new_name"
  if [ -e "$target" ]; then
    suffix=1
    base="$new_name"
    while [ -e "$DIR/$base ($suffix)" ]; do
      suffix=$((suffix+1))
    done
    new_name="$base ($suffix)"
    target="$DIR/$new_name"
  fi

  mv -- "$entry" "$target"
  echo "✅ '$name' → '$(basename -- "$target")'"
  unset autodate
done
