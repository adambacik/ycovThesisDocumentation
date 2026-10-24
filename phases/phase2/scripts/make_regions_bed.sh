#!/usr/bin/env bash
# make_regions_bed.sh
# Produces phases/phase2/data/regions.bed with PAR1, PAR2, AZFa, AZFb, AZFc
# on T2T-CHM13v2.0 (hs1) coordinates.
#
# Strategy:
#   - PAR1 / PAR2: taken directly from sequence_classes.bed (T2T coordinates from Rhie et al. 2023)
#   - AZFa / AZFb / AZFc: official T2T Consortium curated coordinates from:
#     https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0Y_AZF_DYZ_v1.bed
#     (Rhie et al. 2023 Nature paper, MARBL T2T repository)
#
# Output: phases/phase2/data/regions.bed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
OUT="${DATA_DIR}/regions.bed"

T2T_AZF_BED="${DATA_DIR}/chm13v2.0Y_AZF_DYZ_v1.bed"
T2T_AZF_URL="https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0Y_AZF_DYZ_v1.bed"

# ── 1. Download official T2T AZF/DYZ annotations if not present ───────────────
if [[ ! -f "${T2T_AZF_BED}" ]]; then
    echo "[1/3] Downloading official T2T Consortium AZF coordinates..."
    curl -fL -o "${T2T_AZF_BED}" "${T2T_AZF_URL}"
else
    echo "[1/3] T2T AZF file already present: ${T2T_AZF_BED}"
fi

# ── 2. Combine PAR1/PAR2 + AZFa/b/c ───────────────────────────────────────────
echo "[2/3] Extracting PAR1/PAR2 and AZFa/b/c..."
{
    # PAR1 and PAR2 from sequence_classes.bed (strip \r to handle CRLF)
    awk '{ sub(/\r$/, ""); if ($4 == "PAR1" || $4 == "PAR2") print $1 "\t" $2 "\t" $3 "\t" $4 }' "${DATA_DIR}/sequence_classes.bed"

    # AZFa, AZFb, AZFc from official T2T annotation
    awk '{ sub(/\r$/, ""); if ($4 ~ /^AZF/) print $1 "\t" $2 "\t" $3 "\t" $4 }' "${T2T_AZF_BED}"
} | sort -k1,1 -k2,2n > "${OUT}"

# ── 3. Summary and verification ───────────────────────────────────────────────
echo "[3/3] Done. Output written to: ${OUT}"
echo ""
echo "=== regions.bed ==="
column -t "${OUT}"
echo ""
echo "Region spans on T2T-CHM13v2.0:"
awk '{ printf "  %-6s %12d - %12d  (%10.2f kb)\n", $4, $2, $3, ($3 - $2)/1000 }' "${OUT}"

