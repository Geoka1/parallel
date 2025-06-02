#!/bin/bash
# Hours monitored each day

# <in.csv sed 's/T\(..\):..:../,\1/' |
# awk -F, '!seen[$1 $2] {hours[$1]++; seen[$1 $2] = 1}
#    END { OFS = "\t"; for (d in hours) print d, hours[d]}' |
#   sort

# curl https://balab.aueb.gr/~dds/oasa-$(date --date='1 days ago' +'%y-%m-%d').bz2 |
#   bzip2 -d |                  # decompress
# Replace the line below with the two lines above to stream the latest file
INPUT="$1"
MAX_PROCS=${MAX_PROCS:-$(nproc)}
chunk_size=${chunk_size:-100M}
process_chunk() {
  sed 's/T\(..\):..:../,\1/'|
  cut -d ',' -f 1,2                    
}
export -f process_chunk

tmp_dir=$(mktemp -d)
trap "rm -rf $tmp_dir" EXIT  

cat "$INPUT" |
  parallel --pipe --block "$chunk_size" -j "$MAX_PROCS" process_chunk > "$tmp_dir/combined.tmp"

sort -u "$tmp_dir/combined.tmp" |
  cut -d ',' -f 1 |               
  sort |                         
  uniq -c |                      
  awk '{print $2,$1}'            

# diff out{1,}
