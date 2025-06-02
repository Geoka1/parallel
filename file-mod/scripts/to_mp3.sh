#!/bin/bash
# tag: wav-to-mp3
# inputs: $1=absolute source directory path with .wav's, $2=destination directory for output wavs

# Overwrite HOME variable
mkdir -p "$2"
HOME="$1"
pure_func() {
    ffmpeg -y -i pipe:0 -f mp3 -ab 192000 pipe:1 2>/dev/null
}
export -f pure_func

export dest="$2"

find ~ -type f | parallel --jobs "$(nproc)" ' \
    out="$dest/$(basename {}).mp3"; \
    cat {} | pure_func > "$out" \
'