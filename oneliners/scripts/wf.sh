#!/bin/bash
# Calculate the frequency of each word in the document, and sort by frequency

cat "$1" | parallel --pipe --block "$BLOCK_SIZE" '
  tr -c "A-Za-z" "[\n*]" |
  grep -v "^[[:space:]]*$" |
  tr A-Z a-z
' | sort | uniq -c | sort -rn