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

# Function to extract metadata from a Spotify album URL
extract_metadata() {
    local url="$1"
    local html=$(curl -s "$url")

    # Extract JSON metadata from the <script type="application/ld+json">
    local json=$(echo "$html" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)')

    # Extract album name and publication date
    album_name=$(echo "$json" | jq -r '.name')
    year=$(echo "$json" | jq -r '.datePublished' | cut -d'-' -f1)

    # Extract the first artist name from the <a> tag containing /artist/
    artist_name=$(echo "$html" | grep -oP '<a [^>]*href="/artist/[^>]+">\K[^<]+' | head -n 1)
}

# Function to process a single URL
process_url() {
    local line="$1"

    echo "Processing: $line"

    # Extract metadata
    extract_metadata "$line"

    echo "Album: $album_name"
    echo "Artist: $artist_name"
    echo "Year: $year"

    # Create directory inside the output directory
    dir_name="$OUTPUT_DIR/${artist_name} - ${album_name} (${year})"
    echo "Output Directory: $dir_name"
    mkdir -p "$dir_name"
    cd "$dir_name" || exit

    # Build spotdl arguments
    SPOTDL_ARGS="--bitrate 192k"
    if [ -f "$COOKIE_FILE" ]; then
        SPOTDL_ARGS="$SPOTDL_ARGS --cookie-file $COOKIE_FILE"
    fi

    # Run spotdl command
    if spotdl $SPOTDL_ARGS "$line"; then
        # If successful, remove the processed line from the input file if applicable
        if [[ -f "$INPUT_FILE" ]]; then
            sed -i "\|$line|d" "$INPUT_FILE"
        fi
    else
        # If failed, remove the created directory
        cd ..
        rm -rf "$dir_name"
    fi

    # Return to the original directory
    cd - > /dev/null
}

# Parse named parameters
for arg in "$@"
do
  case $arg in
    --source=*)
      INPUT_FILE="$(eval echo "${arg#*=}")"
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

# Check if input file or URL is set
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 --source=/path/to/input.txt|https://spotify.link [--output=/path/to/output_dir] [--cookies=/path/to/cookies.txt]"
    exit 1
fi

# Use current directory as default if OUTPUT_DIR is not provided
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

if [[ "$INPUT_FILE" =~ ^https?:// ]]; then
    # If source is a URL, process directly
    process_url "$INPUT_FILE"
else
    # Otherwise treat it as a text file with multiple URLs
    while IFS= read -r line; do
        if [[ "$line" =~ open.spotify.com/album/ ]]; then
            process_url "$line"
        else
            echo "Skipping invalid link: $line"
        fi
    done < "$INPUT_FILE"
fi
