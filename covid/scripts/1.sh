#!/bin/bash
# Vehicles on the road per day

# <in.csv sed 's/T..:..:..//' |
# awk -F, '!seen[$1 $3] {onroad[$1]++; seen[$1 $3] = 1}
#    END { OFS = "\t"; for (d in onroad) print d, onroad[d]}' |
# sort > out1

# curl https://balab.aueb.gr/~dds/oasa-$(date --date='1 days ago' +'%y-%m-%d').bz2 |
#   bzip2 -d |              # decompress
# Replace the line below with the two lines above to stream the latest file
INPUT="$1"
MAX_PROCS=${MAX_PROCS:-$(nproc)}
chunk_size=${chunk_size:-100M}
process_chunk() {
  sed 's/T..:..:..//'|
  cut -d ',' -f 1,3
}
export -f process_chunk

tmp_dir=$(mktemp -d)
trap "rm -rf $tmp_dir" EXIT  

cat "$INPUT" | parallel --pipe --block "$chunk_size" -j "$d ." process_chunk > "$tmp_dir/combined.tmp"

sort -u "$tmp_dir/combined.tmp" |
  cut -d ',' -f 1 |               
  sort |                          
  uniq -c |                       
  awk '{print $2,$1}'             

# diff out{1,}
