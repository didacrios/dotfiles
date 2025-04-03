#!/bin/bash

# Function to extract metadata from a Spotify album URL
extract_metadata() {
    local url="$1"
    local html=$(curl -s "$url")

    # Extract JSON metadata from the <script type="application/ld+json">
    local json=$(echo "$html" | grep -oP '<script type="application/ld\+json">\K.*?(?=</script>)')

    # Extract album name and publication date
    album_name=$(echo "$json" | jq -r '.name')
    year=$(echo "$json" | jq -r '.datePublished' | cut -d'-' -f1)

    # Extract artist name from the <a> tag containing /artist/
    artist_name=$(echo "$html" | grep -oP '<a [^>]*href="/artist/[^>]+">\K[^<]+' | head -n 1)

}

# Check if parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <file_with_spotify_links.txt> <output_directory>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="$2"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Read each line from the input file
while IFS= read -r line; do
    if [[ "$line" =~ open.spotify.com/album/ ]]; then
        echo "Processing: $line"

        # Extract metadata
        extract_metadata "$line"

        echo "Album: $album_name"
        echo "Artist: $artist_name"
        echo "Year: $year"

        # Create directory inside the output directory
        dir_name="$OUTPUT_DIR/${artist_name} - ${album_name} (${year})"
        mkdir -p "$dir_name"
        cd "$dir_name" || exit

        # Run spotdl command
        spotdl --bitrate 192k "$line"

        # Return to the original directory
        cd - > /dev/null
    else
        echo "Skipping invalid link: $line"
    fi

done < "$INPUT_FILE"
