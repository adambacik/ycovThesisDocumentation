#!/usr/bin/env bash
# Check which regions are masked (N) in the three CHM13v2.0 reference FASTAs.
# For each PAR in chm13v2.0.PAR.bed and for the whole chrX / chrY it prints
# the region length, the number of N bases and the masked percentage.
#
# Usage (in WSL, needs samtools):
#   bash check_par_masking.sh <reference_dir>
set -euo pipefail

REF=${1:?reference directory required}
cd "$REF"

count_n() {  # count_n <fasta> <region>  ->  "<length> <N count>"
  samtools faidx "$1" "$2" | grep -v '^>' | tr -d '\n' \
    | awk '{print length($0), gsub(/[Nn]/, "")}'
}

printf "%-20s %-28s %12s %12s %8s\n" fasta region length N_bases masked
for fa in chm13v2.0.fasta chm13v2.0.XX.fasta chm13v2.0.XY.fasta; do
  # BED is 0-based, half-open -> samtools region is start+1..end
  # "|| [[ -n $chrom ]]" also processes a last line without a trailing newline
  while read -r chrom start end _ || [[ -n "$chrom" ]]; do
    [[ -z "$chrom" || "$chrom" == \#* ]] && continue
    region="$chrom:$((start + 1))-$end"
    read -r len n < <(count_n "$fa" "$region")
    printf "%-20s %-28s %12d %12d %7.1f%%\n" "$fa" "$region" "$len" "$n" "$(echo "$n $len" | awk '{print 100*$1/$2}')"
  done < chm13v2.0.PAR.bed
  for chrom in chrX chrY; do
    read -r len n < <(count_n "$fa" "$chrom")
    printf "%-20s %-28s %12d %12d %7.1f%%\n" "$fa" "$chrom (whole)" "$len" "$n" "$(echo "$n $len" | awk '{print 100*$1/$2}')"
  done
  echo
done
