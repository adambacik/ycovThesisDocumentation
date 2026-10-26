#!/usr/bin/env bash
# make_genes_gtf.sh
# Produces phases/phase2/data/genes.gtf.gz with chrX and chrY gene annotations
# on T2T-CHM13v2.0 (hs1) coordinates.
#
# Strategy:
#   - Download official UCSC T2T-CHM13v2.0 Assembly Hub gene annotations:
#     catLiftOffGenesV1.gtf.gz (GENCODE v35 / Liftoff models mapped to CHM13v2.0).
#   - Stream, decompress, and filter for header lines and features on chrX and chrY.
#   - Compress directly into phases/phase2/data/genes.gtf.gz.
#
# Output: phases/phase2/data/genes.gtf.gz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
OUT="${DATA_DIR}/genes.gtf.gz"

T2T_GENES_GTF="${DATA_DIR}/catLiftOffGenesV1.gtf.gz"
T2T_GENES_URL="https://hgdownload.soe.ucsc.edu/hubs/GCA/009/914/755/GCA_009914755.4/genes/catLiftOffGenesV1.gtf.gz"

# ── 1. Download official T2T gene annotations if not present ───────────────
if [[ ! -f "${T2T_GENES_GTF}" ]]; then
    echo "[1/3] Downloading official T2T-CHM13v2.0 gene annotations..."
    curl -fL -o "${T2T_GENES_GTF}" "${T2T_GENES_URL}"
else
    echo "[1/3] T2T genes file already present: ${T2T_GENES_GTF}"
fi

# ── 2. Filter chrX and chrY into genes.gtf.gz ──────────────────────────────
echo "[2/3] Extracting chrX and chrY annotations..."
gzip -dc "${T2T_GENES_GTF}" \
    | awk '$1 ~ /^#/ || $1 == "chrX" || $1 == "chrY"' \
    | gzip -c > "${OUT}"

# ── 3. Summary and verification ───────────────────────────────────────────
echo "[3/3] Done. Output written to: ${OUT}"
echo ""

echo "=== Verification ==="
echo "File size: $(du -h "${OUT}" | cut -f1)"

echo -n "Total lines: "
gzip -dc "${OUT}" | wc -l

echo -n "chrY feature lines: "
gzip -dc "${OUT}" | awk '$1 == "chrY"' | wc -l

echo -n "chrX feature lines: "
gzip -dc "${OUT}" | awk '$1 == "chrX"' | wc -l

echo -n "Unique chrY gene names: "
gzip -dc "${OUT}" | awk '$1 == "chrY" && $0 ~ /gene_name "[^"]+"/ { match($0, /gene_name "([^"]+)"/, m); print m[1] }' | sort -u | wc -l

echo ""
echo "Key genes check:"
gzip -dc "${OUT}" | awk '
BEGIN {
    split("SRY ZFY AMELY DDX3Y USP9Y DAZ1 DAZ2 SHOX", list, " ")
    for (i in list) targets[list[i]] = 1
}
$1 ~ /^chr[XY]$/ {
    for (g in targets) {
        if ($0 ~ ("gene_name \"" g "\"") && !(g in found)) {
            found[g] = $1 ":" $4 "-" $5
        }
    }
}
END {
    split("SRY ZFY AMELY DDX3Y USP9Y DAZ1 DAZ2 SHOX", list, " ")
    for (i = 1; i <= length(list); i++) {
        g = list[i]
        printf "  %-8s %s\n", g ":", (g in found ? found[g] : "NOT FOUND")
    }
}'

echo ""
echo "=== Sample preview (first 5 records) ==="
# Use sed or head without triggering broken pipe
gzip -dc "${OUT}" | awk '!/^#/ { print; if (++n == 5) exit }' || true
echo ""
