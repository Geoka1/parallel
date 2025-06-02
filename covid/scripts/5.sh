#!/bin/bash
# Hours each bus is active each day

# Records are day, hour, line, bus
# use gawk
MAX_PROCS=${MAX_PROCS:-$(nproc)}
chunk_size=${chunk_size:-100M}
sed_chunk() {
    sed 's/T\(..\):..:../,\1/'
}
export -f sed_chunk

parallel --pipe --block "$MAX_PROCS" sed_chunk < "$1" > temp_sed_output.txt
awk -F, '
!seen[$1 $2 $4] { seen[$1 $2 $4] = 1; hours[$1 $4]++; bus[$4] = 1; day[$1] = 1; }
END {
   PROCINFO["sorted_in"] = "@ind_str_asc"
   for (d in day)
     printf("\t%s", d);
   printf("\n");
   for (b in bus) {
     printf("%s", b);
     for (d in day)
       printf("\t%s", hours[d b]);
     printf("\n");
   }
}' temp_sed_output.txt

rm -rf temp_sed_output.txt