#!/bin/bash

# Check if the input file argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: ./split-file.sh <input_file>"
  exit 1
fi

# Input file path
input_file="$1"

# Number of lines per file (default: 5000)
lines_per_file="${2:-5000}"

# Directory to store split files
split_dir="split-file"

# Create the directory to store split files
mkdir -p "$split_dir"

# Counter for split file names
split_counter=1

# Current split file
current_split_file="$split_dir/split_$split_counter.sql"

# Read the input SQL file line by line
while IFS= read -r line; do
  # Write the line to the current split file
  echo "$line" >> "$current_split_file"

  # Check if the current split file has reached the maximum lines
  if [ $(wc -l < "$current_split_file") -eq $lines_per_file ]; then
    # Move to the next split file
    ((split_counter++))
    current_split_file="$split_dir/split_$split_counter.sql"
  fi
done < "$input_file"

echo "Splitting complete!"
