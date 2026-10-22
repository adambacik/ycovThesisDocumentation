#!/usr/bin/env bash
# Download the CHM13v2.0 reference files (unmasked, XX, XY) used by AnVIL ANVIL_T2T_CHRY.
# MD5 checksums are taken from the AnVIL manifest. Files are fetched from the
# public AnVIL S3 mirror, where each file is named by its MD5 (the manifest's
# files.azul_url links return 404 since AnVIL re-indexed the dataset).
#
# Usage (in WSL):
#   bash download_reference.sh <manifest.tsv> <output_dir>
set -euo pipefail

MANIFEST=${1:?manifest .tsv required}
OUT=${2:?output directory required}
mkdir -p "$OUT"

# file_name <TAB> md5 <TAB> url  for the reference files we want
awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}
  $h["files.file_name"] ~ /^chm13v2\.0\.(XX\.|XY\.)?(fasta|fasta\.fai|dict)$|^chm13v2\.0\.PAR\.bed$/ \
  {md5 = $h["files.file_md5sum"]
   print $h["files.file_name"]"\t"md5"\thttps://anvilproject.s3.amazonaws.com/file/"md5".md5"}' "$MANIFEST" \
  | sort -u -k1,1 > "$OUT/reference_files.tsv"

while IFS=$'\t' read -r name md5 url; do
  if [ -f "$OUT/$name" ] && echo "$md5  $OUT/$name" | md5sum -c --quiet - 2>/dev/null; then
    echo "OK (already present): $name"
    continue
  fi
  echo "Downloading $name ..."
  # -C - resumes a partial download
  curl -fL --retry 5 -C - -o "$OUT/$name" "$url"
  echo "$md5  $OUT/$name" | md5sum -c -
done < "$OUT/reference_files.tsv"

echo "Done. Files in $OUT:"
ls -lh "$OUT"
