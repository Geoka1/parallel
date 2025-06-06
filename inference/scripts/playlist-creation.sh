#!/bin/bash

IN="$1"
OUT="$2"
mkdir -p "$OUT"

# files=$(find "$IN" -type f \( -iname "*.mp3" -o -iname "*.wav" \) | sort)
# num_files=$(printf '%s\n' "$files" | wc -l)

process_dir() {
    local dir_path="$1"
    [ -d "$dir_path" ] || return

    dir=$(basename "$dir_path")
    echo "Processing directory: $dir"

    files=$(find "$dir_path" -type f -name '*.mp3' | sort)
    num_files=$(printf '%s\n' "$files" | wc -l)

    abs_prefix=$(realpath "$dir_path")
    llm embed-multi -m clap songs --binary \
        --files "$abs_prefix" '*.mp3' --prefix "$abs_prefix/"

    first_song=$(printf '%s\n' "$files" | head -n 1)
    last_song=$(printf '%s\n' "$files" | tail -n 1)

    mkdir -p "$OUT/$dir"
    playlist_path="$OUT/$dir/playlist.m3u"

    llm interpolate songs "$first_song" "$last_song" -n "$num_files" \
        | jq .[] > "$playlist_path"
}
export -f process_dir        # make it visible to parallel
export OUT                   # needed inside each job

###############################################################################
# Feed one directory per parallel job.
###############################################################################
find "$IN" -mindepth 1 -maxdepth 1 -type d -print0 \
  | parallel --null --jobs 4 --env OUT process_dir {}