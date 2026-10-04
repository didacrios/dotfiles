#!/bin/bash
set -uo pipefail

# ──────────────────────────────────────────
#  dot-download-track  —  download a Spotify track
#  With retries, delay, and configurable source
# ──────────────────────────────────────────

for cmd in spotdl ffmpeg jq curl python3; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed."
        exit 1
    fi
done

# ── Paths ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COOKIE_FILE="${SCRIPT_DIR}/cookies.txt"

# ── Config defaults ────────────────────────
DELAY="${DELAY_BETWEEN_SONGS:-45}"
RETRY="${RETRY_COUNT:-3}"
AUDIO_PROVIDERS="${AUDIO_PROVIDERS:-youtube-music}"

# ── Generate cookies if missing ────────────
if [ ! -f "$COOKIE_FILE" ]; then
    echo "Generating YouTube cookies..."
    python3 "${SCRIPT_DIR}/extract_cookies.py" 2>/dev/null || true
fi

# ── Helpers ────────────────────────────────
sanitize_filename() {
    echo "$1" | sed 's/[<>:"/\\|?*]/-/g' | sed 's/  */ /g; s/^ //; s/ *$//'
}

# ── Parse args ─────────────────────────────
TRACK_URL=""
OUTPUT_DIR=""

for arg in "$@"; do
    case "$arg" in
        --source=*)     TRACK_URL="${arg#*=}"     ; shift ;;
        --output=*)     OUTPUT_DIR="${arg#*=}"    ; shift ;;
        --delay=*)      DELAY="${arg#*=}"         ; shift ;;
        --retries=*)    RETRY="${arg#*=}"         ; shift ;;
        --audio=*)      AUDIO_PROVIDERS="${arg#*=}"; shift ;;
        --provider=*)   AUDIO_PROVIDERS="${arg#*=}"; shift ;;
        -o|--output)    OUTPUT_DIR="$2"; shift 2   ;;
        -d|--delay)     DELAY="$2"; shift 2        ;;
        *)
            if [[ "$arg" =~ ^https?:// ]]; then
                TRACK_URL="$arg"
            else
                echo "Unknown argument: $arg"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$TRACK_URL" ]; then
    cat <<EOF
Usage: $0 https://open.spotify.com/track/xxx [--output=/path] [--delay=N] [--retries=N] [--audio=youtube-music|piped|youtube]

Environment variables (alternative):
  DELAY_BETWEEN_SONGS   seconds between tracks  (default: 45)
  RETRY_COUNT           retries per track       (default: 3)
  AUDIO_PROVIDERS       comma-separated sources   (default: youtube-music)
EOF
    exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit

# ── Convert comma-separated providers → space-separated spotdl flags ──
AUDIO_FLAGS=()
IFS=',' read -ra PROVIDERS <<< "$AUDIO_PROVIDERS"
for p in "${PROVIDERS[@]}"; do
    p=$(echo "$p" | xargs)  # trim whitespace
    [ -n "$p" ] && AUDIO_FLAGS+=(--audio "$p")
done

# Display friendly name (all providers joined with +)
AUDIO_DISPLAY=""
for i in "${!AUDIO_FLAGS[@]}"; do
    if [ "${AUDIO_FLAGS[$i]}" != "--audio" ]; then
        [ -n "$AUDIO_DISPLAY" ] && AUDIO_DISPLAY+=" + "
        AUDIO_DISPLAY+="${AUDIO_FLAGS[$i]}"
    fi
done

# ── Extract track metadata from Spotify ──
echo "Fetching track info..."
HTML=$(curl -s "$TRACK_URL")
track_name=$(echo "$HTML" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)' | jq -r '.name' 2>/dev/null || echo "Unknown")

# Try multiple description formats from JSON-LD
raw_desc=$(echo "$HTML" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)' | jq -r '.description' 2>/dev/null)

# Format: "Song · Artist · Year" or "Listen to <track> on Spotify. Song · Artist · Year"
# Separator is middle dot · (U+00B7), not bullet •
artist_name=$(echo "$raw_desc" | sed -nE 's/.*Song · (.*) · [0-9]{4}.*$/\1/p' | head -n 1)

# Fallback: extract the first artist name from the <a> tag
if [ -z "$artist_name" ] || [ "$artist_name" = "null" ]; then
    artist_name=$(echo "$HTML" | grep -oP '<a [^>]*href="/artist/[^>]+">\K[^<]+' | head -n 1 || echo "Unknown")
fi

# ── Output filename ───────────────────────
safe_name=$(sanitize_filename "$track_name")
track_file="${artist_name} - ${safe_name}.mp3"

echo ""
echo "Track: $artist_name — $track_name"
echo "Output: $track_file"
echo "Audio source: $AUDIO_DISPLAY"
echo "Retries: $RETRY"
echo ""

# ── Download with retries ─────────────────
COOKIES_OPTS=""
[ -f "$COOKIE_FILE" ] && COOKIES_OPTS="--cookie-file $COOKIE_FILE"

retry=0
downloaded=false

while [ $retry -lt $RETRY ]; do
    rm -rf "${track_file%.mp3}" 2>/dev/null || true

    spotdl "$TRACK_URL" \
        "${AUDIO_FLAGS[@]}" \
        --bitrate 192k \
        --yt-dlp-args '--js-runtimes node' \
        --output "$(basename "$track_file")" \
        $COOKIES_OPTS \
        2>&1 | grep -iE 'download|found|error|audio' || true

    # spotdl 4.x creates a dir named after --output, puts the mp3 inside
    mp3_found=false
    if [ -f "$track_file" ] && [ -s "$track_file" ]; then
        mp3_found=true
    fi
    # Check if a directory was created with mp3 inside (spotdl 4.x)
    if [ ! "$mp3_found" = true ] && [ -d "$track_file" ]; then
        found_mp3=$(find "$track_file" -maxdepth 1 -name '*.mp3' -type f 2>/dev/null | head -n 1)
        if [ -n "$found_mp3" ] && [ -s "$found_mp3" ]; then
            mp3_found=true
            # Rename dir first, then move mp3 out
            tmp_dir="${track_file}.spotdl-dir"
            mv "$track_file" "$tmp_dir" 2>/dev/null || true
            mp3_name=$(basename "$found_mp3")
            mv "${tmp_dir}/${mp3_name}" "$track_file" 2>/dev/null || true
            rm -rf "$tmp_dir" 2>/dev/null || true
        fi
    fi
    if [ "$mp3_found" = true ]; then
        echo ""
        echo "✓ Downloaded to $track_file"
        downloaded=true
        break
    fi

    retry=$((retry + 1))
    if [ $retry -lt $RETRY ]; then
        wait_time=$(( (retry + 1) * 20 ))
        echo "Retry $retry/$RETRY (waiting ${wait_time}s)..."
        sleep "$wait_time"
    fi
done

if [ "$downloaded" = false ]; then
    echo ""
    echo "✗ Failed after $RETRY attempts"
    exit 1
fi

echo ""
echo "Done!"