#!/usr/bin/env bash

DIR="${1:-.}"

for entry in "$DIR"/*; do
  [ -d "$entry" ] || continue
  name="$(basename -- "$entry")"

  # Extract date from folder name (YYYY-MM-DD format)
  if [[ "$name" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    folder_date="${BASH_REMATCH[1]}"
    echo "📁 Checking folder: '$name' (Date: $folder_date)"

    # Find all photos in the folder
    photos=$(find "$entry" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null)

    if [[ -z "$photos" ]]; then
      echo "❌ No photos found in '$name'"
      continue
    fi

    # Get EXIF dates from all photos
    photo_dates=()
    exif_found=false

    while IFS= read -r photo; do
      exif_date=$(exiftool -s -s -s -DateTimeOriginal "$photo" 2>/dev/null | head -n1)
      if [[ -n "$exif_date" ]]; then
        # exiftool retorna "YYYY:MM:DD HH:MM:SS"
        y=$(echo "$exif_date" | cut -d: -f1)
        m=$(echo "$exif_date" | cut -d: -f2)
        d=$(echo "$exif_date" | cut -d: -f3 | awk '{print $1}')
        photo_date="$y-$m-$d"
        photo_dates+=("$photo_date")
        exif_found=true
      fi
    done <<< "$photos"

    if [[ "$exif_found" == false ]]; then
      echo "❌ No EXIF data found in photos from '$name'"
      continue
    fi

    # Check if all photo dates match folder date
    all_match=true
    for photo_date in "${photo_dates[@]}"; do
      if [[ "$photo_date" != "$folder_date" ]]; then
        all_match=false
        break
      fi
    done

    if [[ "$all_match" == true ]]; then
      echo "✅ All photos in '$name' match folder date ($folder_date)"
    else
      echo "⚠️  Date discrepancy in '$name':"
      echo "   Folder date: $folder_date"
      echo "   Photo dates: ${photo_dates[*]}"
    fi

  else
    echo "❌ Folder '$name' doesn't start with YYYY-MM-DD format"
  fi
done
