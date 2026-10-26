#!/usr/bin/env bash
# make_gaps_bed.sh
# Scans a reference FASTA file for N-runs (assembly gaps or hard-masked regions)
# and produces a 0-based BED4 file: <chrom> <start> <end> gap
#
# Usage:
#   bash make_gaps_bed.sh <reference.fasta[.gz]> [output.bed]
#
# Example:
#   bash make_gaps_bed.sh /path/to/chm13v2.0.XY.fasta
#   bash make_gaps_bed.sh /path/to/chm13v2.0.XY.fasta phases/phase2/data/gaps.bed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"

FASTA="${1:-}"
OUT="${2:-${DATA_DIR}/gaps.bed}"

if [[ -z "${FASTA}" ]]; then
    echo "Usage: bash make_gaps_bed.sh <reference.fasta[.gz]> [output.bed]"
    echo ""
    echo "Error: Missing reference FASTA file argument."
    exit 1
fi

# Convert Windows paths (e.g. C:/... or D:\...) if running in WSL
if [[ "${FASTA}" =~ ^[A-Za-z]: ]] && command -v wslpath &>/dev/null; then
    FASTA="$(wslpath -u "${FASTA}")"
fi
if [[ "${OUT}" =~ ^[A-Za-z]: ]] && command -v wslpath &>/dev/null; then
    OUT="$(wslpath -u "${OUT}")"
fi

if [[ ! -f "${FASTA}" ]]; then
    echo "Error: FASTA file not found at: ${FASTA}"
    exit 1
fi

echo "[1/2] Scanning ${FASTA} for N-runs..."

python3 - "${FASTA}" "${OUT}" << 'EOF'
import sys
import gzip
import re

fasta_path = sys.argv[1]
out_path = sys.argv[2]

opener = gzip.open if fasta_path.endswith('.gz') else open

with opener(fasta_path, 'rt') as f_in, open(out_path, 'w', encoding='utf-8') as f_out:
    chrom = None
    offset = 0
    in_gap = False
    gap_start = 0

    for line in f_in:
        line = line.rstrip('\r\n')
        if not line:
            continue
        if line.startswith('>'):
            if in_gap:
                f_out.write(f"{chrom}\t{gap_start}\t{offset}\tgap\n")
                in_gap = False
            chrom = line[1:].split()[0]
            offset = 0
            continue

        # Split line into alternating N-runs and non-N segments
        for match in re.finditer(r'[Nn]+|[^Nn]+', line):
            seg = match.group(0)
            seg_len = len(seg)
            if seg[0] in 'Nn':
                if not in_gap:
                    gap_start = offset
                    in_gap = True
            else:
                if in_gap:
                    f_out.write(f"{chrom}\t{gap_start}\t{offset}\tgap\n")
                    in_gap = False
            offset += seg_len

    if in_gap:
        f_out.write(f"{chrom}\t{gap_start}\t{offset}\tgap\n")

EOF

echo "[2/2] Done! Gaps written to: ${OUT}"
echo ""
echo "=== Detected gaps ==="
if [[ -s "${OUT}" ]]; then
    column -t "${OUT}"
    echo ""
    echo "Summary:"
    awk '{ printf "  %-8s %12d - %12d  (%10.2f kb)\n", $1, $2, $3, ($3 - $2)/1000 }' "${OUT}"
else
    echo "(No gaps or N-runs found in reference sequence - clean assembly)"
fi
echo ""
