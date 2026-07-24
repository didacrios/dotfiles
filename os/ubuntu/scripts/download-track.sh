#!/bin/bash

# Check for required software
for cmd in spotdl ffmpeg jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed."
        exit 1
    fi
done

# Resolve script directory for finding extract_cookies.py
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COOKIE_FILE="${SCRIPT_DIR}/cookies.txt"

# Generate cookie file if it doesn't exist
if [ ! -f "$COOKIE_FILE" ]; then
    echo "Generating YouTube cookies..."
    python3 "${SCRIPT_DIR}/extract_cookies.py"
    if [ ! -f "$COOKIE_FILE" ]; then
        echo "Warning: Failed to generate cookie file. YouTube downloads may fail."
    fi
fi

# Function to extract metadata from a Spotify track URL
extract_metadata() {
    local url="$1"
    local html=$(curl -s "$url")

    # Extract JSON metadata from the <script type="application/ld+json">
    local json=$(echo "$html" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)')

    # Extract track name from JSON-LD
    track_name=$(echo "$json" | jq -r '.name')

    # Artist is in the description field: "Song · Rick Astley · 1987"
    artist_name=$(echo "$json" | jq -r '.description' | sed -E 's/^Song • //; s/ • [0-9]{4}$//')

    # Fallback: extract the first artist name from the <a> tag containing /artist/
    if [ -z "$artist_name" ] || [ "$artist_name" = "null" ] || [ "$artist_name" = "\"\"" ]; then
        artist_name=$(echo "$html" | grep -oP '<a [^>]*href="/artist/[^>]+">\K[^<]+' | head -n 1)
    fi
}

# Parse named parameters
for arg in "$@"
do
  case $arg in
    --source=*)
      TRACK_URL="$(eval echo "${arg#*=}")"
      shift
      ;;
    --output=*)
      OUTPUT_DIR="$(eval echo "${arg#*=}")"
      shift
      ;;
    --cookies)
      COOKIE_FILE="$(eval echo "${arg#*=}")"
      shift
      ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

# Check if URL is set
if [ -z "$TRACK_URL" ]; then
    echo "Usage: $0 --source=https://open.spotify.com/track/xxx [--output=/path/to/output_dir] [--cookies=/path/to/cookies.txt]"
    exit 1
fi

# Use current directory as default if OUTPUT_DIR is not provided
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Processing: $TRACK_URL"

# Extract metadata
extract_metadata "$TRACK_URL"

echo "Track: $track_name"
echo "Artist: $artist_name"

# Build spotdl arguments
SPOTDL_ARGS="--bitrate 192k --output $OUTPUT_DIR"
if [ -f "$COOKIE_FILE" ]; then
    SPOTDL_ARGS="$SPOTDL_ARGS --cookie-file $COOKIE_FILE"
fi

# Run spotdl command
if spotdl $SPOTDL_ARGS "$TRACK_URL"; then
    echo "Download complete!"
else
    echo "Download failed!"
    exit 1
fi
