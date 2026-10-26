#!/usr/bin/env bash
# make_mappability.sh
# Produces phases/phase2/data/mappability.bw for T2T-CHM13v2.0 (hs1)
# containing k=150 mappability for chrY, chrX, and baseline autosomes (chr19-chr22).
#
# Strategy:
#   - Source: Official UCSC T2T-CHM13v2.0 Hoffman Mappability track (k=150):
#     https://hgdownload.soe.ucsc.edu/gbdb/hs1/hoffmanMappability/k150.Umap.MultiTrackMappability.bw
#   - Fetch chromosome sizes (from local .fai or UCSC hs1.chrom.sizes).
#   - Extract chrY, chrX, and baseline autosomes (chr19-22) into bedGraph
#     (bigWigToBedGraph streams remote HTTP ranges without needing the full 855 MB download).
#   - Convert the subset bedGraph back into an indexed bigWig: mappability.bw.
#
# Requirements:
#   - bigWigToBedGraph, bedGraphToBigWig (from UCSC userApps / bioconda: ucsc-bigwigtobedgraph, ucsc-bedgraphtobigwig)
#   - curl
#
# Output: phases/phase2/data/mappability.bw

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
OUT="${DATA_DIR}/mappability.bw"

# UCSC track URL (k=150 multi-track mappability for hs1)
UCSC_BW_URL="https://hgdownload.soe.ucsc.edu/gbdb/hs1/hoffmanMappability/k150.Umap.MultiTrackMappability.bw"
CHROM_SIZES_URL="https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.chrom.sizes"
CHROM_SIZES="${DATA_DIR}/hs1.chrom.sizes"

# Chromosomes needed for ycov: chrY, chrX, and baseline autosomes (chr19-chr22)
TARGET_CHROMS=("chrY" "chrX" "chr19" "chr20" "chr21" "chr22")

# Check required tools
for tool in curl bigWigToBedGraph bedGraphToBigWig; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: Required tool '$tool' not found."
        echo "Install via conda/mamba:"
        echo "  conda install -c bioconda ucsc-bigwigtobedgraph ucsc-bedgraphtobigwig"
        exit 1
    fi
done

mkdir -p "${DATA_DIR}"
TMP_DIR="$(mktemp -d -t mappability_XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

# ── 1. Obtain chromosome sizes ───────────────────────────────────────────────
if [[ ! -f "${CHROM_SIZES}" ]]; then
    echo "[1/4] Fetching hs1 chromosome sizes..."
    curl -fL -o "${CHROM_SIZES}" "${CHROM_SIZES_URL}"
else
    echo "[1/4] Chromosome sizes already present: ${CHROM_SIZES}"
fi

# Subset chrom.sizes to only target chromosomes
TARGET_SIZES="${TMP_DIR}/target.chrom.sizes"
for c in "${TARGET_CHROMS[@]}"; do
    awk -v chrom="$c" '$1 == chrom { print $1 "\t" $2 }' "${CHROM_SIZES}"
done > "${TARGET_SIZES}"

# ── 2. Extract target chromosomes from UCSC BigWig ──────────────────────────
echo "[2/4] Extracting target chromosomes (${TARGET_CHROMS[*]}) from UCSC BigWig..."
TMP_BG="${TMP_DIR}/target_mappability.bg"
: > "${TMP_BG}"

for c in "${TARGET_CHROMS[@]}"; do
    echo "  -> Extracting ${c}..."
    bigWigToBedGraph -chrom="${c}" "${UCSC_BW_URL}" "${TMP_DIR}/${c}.bg"
    cat "${TMP_DIR}/${c}.bg" >> "${TMP_BG}"
    rm -f "${TMP_DIR}/${c}.bg"
done

# ── 3. Sort and convert to BigWig ────────────────────────────────────────────
echo "[3/4] Converting extracted regions into indexed BigWig: ${OUT}..."
# Ensure bedGraph is sorted by target.chrom.sizes order
LC_ALL=C sort -k1,1 -k2,2n "${TMP_BG}" > "${TMP_DIR}/sorted.bg"
bedGraphToBigWig "${TMP_DIR}/sorted.bg" "${TARGET_SIZES}" "${OUT}"

# ── 4. Summary and verification ──────────────────────────────────────────────
echo "[4/4] Done! Mappability BigWig generated at: ${OUT}"
echo ""
echo "=== Verification ==="
echo "File size: $(du -h "${OUT}" | cut -f1)"

if command -v bigWigInfo &>/dev/null; then
    echo ""
    echo "bigWigInfo output:"
    bigWigInfo "${OUT}"
fi

echo ""
echo "Sample values on chrY (first 10 intervals):"
bigWigToBedGraph -chrom=chrY "${OUT}" stdout | head -n 10
echo ""
