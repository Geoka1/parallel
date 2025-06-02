#!/bin/bash
# source: posh benchmark suite

HOME="$1"
dest="$2"

#mogrify  -format gif -path "$dest" -thumbnail 100x100 $input/*.jpg

export dest

find ~ -name '*.jpg' | parallel --jobs "$(nproc)" \
  'mogrify -format gif -path "$dest" -thumbnail 100x100 "{}"'