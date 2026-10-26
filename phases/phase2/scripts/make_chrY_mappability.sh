#!/usr/bin/env bash
# make_chrY_mappability.sh
# Extracts only chrY mappability from phases/phase2/data/mappability.bw
# and creates a compact, bundled BigWig: phases/phase2/data/mappability_chrY.bw (~11 MB).
#
# Usage:
#   bash make_chrY_mappability.sh [input_mappability.bw] [output_chrY.bw]
#
# Requirements:
#   - bigWigToBedGraph, bedGraphToBigWig
#
# Output: phases/phase2/data/mappability_chrY.bw

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"

IN="${1:-${DATA_DIR}/mappability.bw}"
OUT="${2:-${DATA_DIR}/mappability_chrY.bw}"
CHROM_SIZES="${DATA_DIR}/hs1.chrom.sizes"

# Check required tools
for tool in bigWigToBedGraph bedGraphToBigWig; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: Required tool '$tool' not found."
        echo "Install via conda or download standalone binary from UCSC."
        exit 1
    fi
done

# Check input file
if [[ ! -f "${IN}" ]]; then
    echo "Error: Input BigWig not found at: ${IN}"
    echo "Please run make_mappability.sh first."
    exit 1
fi

if [[ ! -f "${CHROM_SIZES}" ]]; then
    echo "Error: Chromosome sizes not found at: ${CHROM_SIZES}"
    exit 1
fi

TMP_DIR="$(mktemp -d -t chry_map_XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "[1/3] Extracting chrY from ${IN}..."
TMP_BG="${TMP_DIR}/chrY.bg"
bigWigToBedGraph -chrom=chrY "${IN}" "${TMP_BG}"

echo "[2/3] Preparing chrY chromosome sizes..."
CHR_Y_SIZES="${TMP_DIR}/chrY.chrom.sizes"
awk '$1 == "chrY" { print $1 "\t" $2 }' "${CHROM_SIZES}" > "${CHR_Y_SIZES}"

if [[ ! -s "${CHR_Y_SIZES}" ]]; then
    echo "Error: chrY not found in ${CHROM_SIZES}"
    exit 1
fi

echo "[3/3] Creating chrY-only BigWig: ${OUT}..."
bedGraphToBigWig "${TMP_BG}" "${CHR_Y_SIZES}" "${OUT}"

echo ""
echo "Done! Output written to: ${OUT}"
echo ""
echo "=== Verification ==="
echo "File size: $(du -h "${OUT}" | cut -f1)"

if command -v bigWigInfo &>/dev/null; then
    echo ""
    echo "bigWigInfo output:"
    bigWigInfo "${OUT}"
fi

echo ""
echo "Sample values on chrY (first 5 intervals):"
bigWigToBedGraph "${OUT}" stdout | head -n 5
echo ""
