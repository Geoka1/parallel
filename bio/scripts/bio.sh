#!/bin/bash

cd "$(dirname "$0")"/.. || exit 1

IN="$1"
IN_NAME="$2"
OUT="$3"

process_sample() {
    s_line="$1"
    IN="$2"
    OUT="$3"

    sample=$(echo "$s_line" | cut -d " " -f 2)
    pop=$(echo "$s_line" | cut -f 1 -d " ")

    if [ -z "$pop" ] || [ -z "$sample" ]; then
        return 0
    fi

    echo "Processing Sample $sample"

    samtools view -H "${IN}/${sample}.bam" \
        | sed -e 's/SN:\([0-9XY]\)/SN:chr\1/' -e 's/SN:MT/SN:chrM/' \
        | samtools reheader - "${IN}/${sample}.bam" > "${OUT}/${sample}_corrected.bam"

    samtools index -b "${OUT}/${sample}_corrected.bam"

    cut -f 2 ./Gene_locs.txt | sort | uniq | while read -r chr; do
        echo "Isolating Chromosome $chr from sample ${OUT}/${sample}"
        samtools view -b "${OUT}/${sample}_corrected.bam" "chr${chr}" > "${OUT}/${pop}_${sample}_${chr}.bam"
        echo "Indexing Sample ${pop}_${sample}_${chr}.bam"
        samtools index -b "${OUT}/${pop}_${sample}_${chr}.bam"
    done
}


export -f process_sample
export IN OUT

cat "$IN_NAME" | parallel --jobs "$(nproc)" process_sample {} "$IN" "$OUT"
