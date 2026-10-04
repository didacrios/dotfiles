#!/bin/bash
set -uo pipefail

# ──────────────────────────────────────────
#  dot-download-album  —  download a Spotify album
#  Song-by-song with configurable delay + retries
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
TRACK_LIST="${SCRIPT_DIR}/album_tracks.spotdl"

# ── Config (override with env vars or CLI) ─
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
    # Replace problematic chars, collapse spaces
    echo "$1" | sed 's/[<>:"/\\|?*]/-/g' | sed 's/  */ /g; s/^ //; s/ *$//'
}

# ── Parse args ─────────────────────────────
INPUT_FILE=""
OUTPUT_DIR=""

for arg in "$@"; do
    case "$arg" in
        --source=*)     INPUT_FILE="${arg#*=}"     ; shift ;;
        --output=*)     OUTPUT_DIR="${arg#*=}"     ; shift ;;
        --delay=*)      DELAY="${arg#*=}"          ; shift ;;
        --retries=*)    RETRY="${arg#*=}"          ; shift ;;
        --audio=*)      AUDIO_PROVIDERS="${arg#*=}" ; shift ;;
        --provider=*)   AUDIO_PROVIDERS="${arg#*=}" ; shift ;;
        -o|--output)    OUTPUT_DIR="$2"; shift 2   ;;
        -d|--delay)     DELAY="$2"; shift 2        ;;
        *)
            if [[ "$arg" =~ ^https?:// ]]; then
                INPUT_FILE="$arg"
            else
                echo "Unknown argument: $arg"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$INPUT_FILE" ]; then
    cat <<EOF
Usage: $0 https://open.spotify.com/album/... [--output=/path] [--delay=N] [--retries=N] [--audio=youtube-music|soundcloud|piped]

Environment variables (alternative):
  DELAY_BETWEEN_SONGS   seconds between tracks  (default: 45)
  RETRY_COUNT           retries per track       (default: 3)
  AUDIO_PROVIDER        audio source            (default: youtube-music)
EOF
    exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"
mkdir -p "$OUTPUT_DIR"

# ── Extract album metadata from Spotify ──
echo "Fetching album info..."
HTML=$(curl -s "$INPUT_FILE")
album_name=$(echo "$HTML" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)' | jq -r '.name' 2>/dev/null || echo "Unknown")
year=$(echo "$HTML" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)' | jq -r '.datePublished' | cut -d'-' -f1 2>/dev/null || echo "???")
artist_name=$(echo "$HTML" | grep -oP '<a [^>]*href="/artist/[^>]+">\K[^<]+' | head -n 1 || echo "Unknown")

dir_name="$OUTPUT_DIR/${artist_name} - ${album_name} (${year})"
echo ""
echo "Album: $artist_name — $album_name ($year)"
echo "Output: $dir_name"
# Convert comma-separated to space-separated for spotdl
AUDIO_FLAGS=()
IFS=',' read -ra PROVIDERS <<< "$AUDIO_PROVIDERS"
for p in "${PROVIDERS[@]}"; do
    p=$(echo "$p" | xargs)
    [ -n "$p" ] && AUDIO_FLAGS+=(--audio "$p")
done
echo "Audio source: ${AUDIO_FLAGS[*]:1:-1}"
echo "Delay between tracks: ${DELAY}s"
echo ""

mkdir -p "$dir_name"

# ── Phase 1: Try batch download ────────────
echo "━━━ Phase 1: Batch download ━━━"
cd "$dir_name"

COOKIES_OPTS=""
[ -f "$COOKIE_FILE" ] && COOKIES_OPTS="--cookie-file $COOKIE_FILE"

spotdl "$INPUT_FILE" \
    "${AUDIO_FLAGS[@]}" \
    --bitrate 192k \
    --yt-dlp-args '--js-runtimes node' \
    --output "${artist_name} - {title}.{output-ext}" \
    $COOKIES_OPTS \
    2>&1 | grep -iE 'download|found|error|audio' || true
batch_count=$(find . \( -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' \) -type f 2>/dev/null | wc -l)
echo ""
echo "  Batch result: $batch_count files"

if [ "$batch_count" -ge 10 ]; then
    echo "  Sufficient tracks! Done."
    cd - > /dev/null
    echo ""
    echo "=== Done ($batch_count files) ==="
    exit 0
fi

# ── Phase 2: Generate track list ───────────
echo "━━━ Phase 2: Extracting track list ━━━"
spotdl "$INPUT_FILE" \
    "${AUDIO_FLAGS[@]}" \
    --yt-dlp-args '--js-runtimes node' \
    --save-file "$TRACK_LIST" \
    --simple-tui \
    2>&1 | grep -iE 'found|track|song' || true
if [ ! -f "$TRACK_LIST" ] || [ ! -s "$TRACK_LIST" ]; then
    echo "  No track list generated."
    cd - > /dev/null
    final=$(find "$dir_name" \( -name '*.mp3' -o -name '*.flac' \) -type f 2>/dev/null | wc -l)
    echo ""
    echo "=== Done ($final files) ==="
    exit 0
fi

# Parse with jq — extract query and download_url
total_tracks=$(jq length "$TRACK_LIST" 2>/dev/null || echo 0)
echo "  Total tracks from album: $total_tracks"

if [ "$total_tracks" -eq 0 ]; then
    echo "  No tracks in save file."
    cd - > /dev/null
    exit 0
fi

echo ""
echo "━━━ Phase 3: Downloading individual tracks with delay ━━━"

# Use jq to generate a clean list: track_name<TAB>download_url
jq -r '.[] | [.name, (.download_url // "")] | @tsv' "$TRACK_LIST" > "${SCRIPT_DIR}/track_queries.tsv"

current=0
while IFS=$'\t' read -r track_name dl_url; do
    [ -z "$track_name" ] && continue
    current=$((current + 1))

    # Build filename
    safe_name=$(sanitize_filename "$track_name")
    track_file="${artist_name} - ${safe_name}.mp3"

    # Skip if exists
    if [ -f "$track_file" ] && [ -s "$track_file" ]; then
        echo "  [$current/$total_tracks] SKIP: $(basename "$track_file")"
        continue
    fi

    # Build search query from track name + artist
    query="$track_name $artist_name"
    echo "  [$current/$total_tracks] Downloading: $(basename "$track_file")"
    echo "    Query: $query"

    retry=0
    downloaded=false

    while [ $retry -lt $RETRY ]; do
        rm -rf "${track_file%.mp3}" 2>/dev/null || true
        local_output="$track_file"

        spotdl "$query" \
            "${AUDIO_FLAGS[@]}" \
            --bitrate 192k \
            --yt-dlp-args '--js-runtimes node' \
            --output "$(basename "$local_output")" \
            $COOKIES_OPTS \
            > /dev/null 2>&1

        # spotdl 4.x creates a dir named after --output, puts the mp3 inside
        mp3_found=false
        if [ -f "$track_file" ] && [ -s "$track_file" ]; then
            mp3_found=true
        fi
        if [ ! "$mp3_found" = true ] && [ -d "$track_file" ]; then
            found_mp3=$(find "$track_file" -maxdepth 1 -name '*.mp3' -type f 2>/dev/null | head -n 1)
            if [ -n "$found_mp3" ] && [ -s "$found_mp3" ]; then
                mp3_found=true
                tmp_dir="${track_file}.spotdl-dir"
                mv "$track_file" "$tmp_dir" 2>/dev/null || true
                mp3_name=$(basename "$found_mp3")
                mv "${tmp_dir}/${mp3_name}" "$track_file" 2>/dev/null || true
                rm -rf "$tmp_dir" 2>/dev/null || true
            fi
        fi
        if [ "$mp3_found" = true ]; then
            echo "    ✓ downloaded"
            downloaded=true
            break
        fi

        retry=$((retry + 1))
        if [ $retry -lt $RETRY ]; then
            wait_time=$(( (retry + 1) * 20 ))
            echo "    Retry $retry/$RETRY (waiting ${wait_time}s)..."
            sleep "$wait_time"
        fi
    done

    if [ "$downloaded" = false ]; then
        echo "    ✗ FAILED after $RETRY attempts"
    fi

    # Delay between tracks (not after last one)
    if [ $current -lt "$total_tracks" ]; then
        echo "  Waiting ${DELAY}s before next track..."
        sleep "$DELAY"
    fi
done < "${SCRIPT_DIR}/track_queries.tsv"

cd - > /dev/null

# ── Summary ────────────────────────────────
echo ""
echo "=== Summary ==="
final=$(find "$dir_name" \( -name '*.mp3' -o -name '*.flac' \) -type f 2>/dev/null | wc -l)
echo "Total: $final files → $dir_name"
echo ""
if [ "$final" -lt "$total_tracks" ]; then
    echo "Tip: failed tracks may work with a different provider:"
    echo "  AUDIO_PROVIDER=soundcloud dot-download-album <url>"
fi