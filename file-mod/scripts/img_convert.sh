#!/bin/bash
# tag: resize image 
# inputs: $1=absolute source directory path with images, $2=destination directory for output images

# Overwrite HOME variable
mkdir -p "$2"

pure_func () {
    convert -resize 70% "-" "-"
}
export -f pure_func

export dest_dir="$2"

find "$1" -type f | parallel --jobs "$(nproc)" \
    'cat {} | pure_func > "$dest_dir/{/}"'