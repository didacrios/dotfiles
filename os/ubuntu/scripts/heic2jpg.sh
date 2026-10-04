#!/usr/bin/env bash
# heic2jpg.sh — Convert HEIC files to JPG using ImageMagick
# Usage:
#   ./heic2jpg.sh <file.heic>          # Convert single file
#   ./heic2jpg.sh <directory>          # Convert all HEIC files in directory
#   ./heic2jpg.sh --dry-run <arg>      # Show what would be done without converting
#
# Output goes next to the source file with .jpg extension.
set -euo pipefail

DRY_RUN=0
COUNT=0
FAILURES=0

usage() {
  echo "Usage: $0 [--dry-run] <file.heic | directory>"
  exit 1
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *) break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  echo "Error: no file or directory specified." >&2
  usage
fi

TARGET="$1"

if [[ ! -e "$TARGET" ]]; then
  echo "Error: '$TARGET' does not exist." >&2
  exit 1
fi

convert_file() {
  local src="$1"
  local dst="${src%.heic}.jpg"
  dst="${src%.HEIC}.jpg"
  dst="${src%.Heic}.jpg"

  # Fallback if the basename substitution didn't work
  if [[ "$dst" == "${src%.heic}.jpg" && "$dst" == "${src%.HEIC}.jpg" && "$dst" == "${src%.Heic}.jpg" ]]; then
    echo "  ⚠ Skipping: doesn't look like a HEIC extension → $(basename "$src")" >&2
    ((FAILURES++))
    return
  fi

  if [[ -f "$dst" && ! "$DRY_RUN" -eq 1 ]]; then
    echo "  ⚠ Skipping (already exists): $dst" >&2
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $src → $dst"
  else
    if convert "$src" -quality 92 "$dst" 2>/dev/null; then
      echo "  ✓ $src → $dst"
      ((COUNT++))
    else
      echo "  ✗ Failed: $src" >&2
      ((FAILURES++))
    fi
  fi
}

if [[ -f "$TARGET" ]]; then
  convert_file "$TARGET"
elif [[ -d "$TARGET" ]]; then
  shopt -s nullglob
  files=("$TARGET"/*.{heic,HEIC,Heic})
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No HEIC files found in '$TARGET'." >&2
    exit 1
  fi

  echo "Converting ${#files[@]} HEIC file(s) in '$TARGET'..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "(dry-run mode — nothing will be written)"
  fi
  echo ""

  for f in "${files[@]}"; do
    convert_file "$f"
  done
else
  echo "Error: '$TARGET' is neither a file nor a directory." >&2
  exit 1
fi

echo ""
echo "Done. ✓ $COUNT converted  ✗ $FAILURES failed"