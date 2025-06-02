#!/bin/bash

IN=$1
OUT=$2
mkdir -p "$OUT"

ollama serve > ollama_serve.log 2>&1 &
ollama pull gemma3
process_one() {
    local img="$1"

    # Original logic — unchanged
    title=$(llm -m gemma3 \
        "Your only output should be a **single** small title for this image:" \
        -a "$img" -o seed 0 -o temperature 0 < /dev/null)

    base=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g; s/[^a-z0-9_-]//g')
    filename="${base}.jpg"
    count=1

    while [ -e "$OUT/$filename" ]; do
        filename="${base}_${count}.jpg"
        count=$((count + 1))
    done

    cp "$img" "$OUT/$filename"
}
export -f process_one
export OUT         

find "$IN" -type f -iname '*.jpg' -print0 |
  parallel --null --jobs "$(nproc)" --env OUT process_one {}