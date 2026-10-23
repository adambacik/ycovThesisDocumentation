# Data preview

## Extraction of needed regions

### Extract regions and track time

/usr/bin/time -v samtools view -u -T ${FASTA_FILE_PATH} "${CRAM_LINK}##idx##${CRAM_INDEX_LINK}" chr19 chr20 chr21 chr22 chrY | samtools view -C -T ${FASTA_FILE_PATH} -o ${OUTPUT_FILE_NAME}.cram --write-index -

### Find out the file disk size

du -h ${CRAM_PATH}

### Preview table

| Sample ID | Regions extracted | CRAM file name | CRAM index file name | Tool | CRAM disk size (GB) |
| --- | --- | --- | --- | --- | --- | --- |
| HG00096 | chr19-22, chrX, chrY | HG00096.subset.cram  | HG00096.subset.crai | samtools |  1.1 |
| HG00101 | chr19-22, chrX, chrY | HG00101.subset.cram  | HG00101.subset.crai | samtools |  1.3 |
| HG00103 | chr19-22, chrX, chrY | HG00103.subset.cram  | HG00103.subset.crai | samtools |  1.1 |
| HG00105 | chr19-22, chrX, chrY | HG00105.subset.cram  | HG00105.subset.crai | samtools |  1.1 |
| HG00107 | chr19-22, chrX, chrY | HG00107.subset.cram  | HG00107.subset.crai | samtools |  1.2 |
| HG00108 | chr19-22, chrX, chrY | HG00108.subset.cram  | HG00108.subset.crai | samtools |  1.2 |
| HG00109 | chr19-22, chrX, chrY | HG00109.subset.cram  | HG00109.subset.crai | samtools |  1.3 |
| HG00112 | chr19-22, chrX, chrY | HG00112.subset.cram  | HG00112.subset.crai | samtools |  1.2 |
| HG00097 | chr19-22, chrX, chrY | HG00097.subset.cram  | HG00097.subset.crai | samtools |  1.3 |
| HG00099 | chr19-22, chrX, chrY | HG00099.subset.cram  | HG00099.subset.crai | samtools |  1.5 |

## Coverage with mosdepth on one sample

| Sample ID | Command | Time (s) | Output files | Meaning |
| --- | --- | --- | --- | --- |
| HG00096 | /usr/bin/time -v mosdepth -t 4 -n --by 1000 --fasta ${FASTA_PATH} HG00096.all ${CRAM_FILE_PATH} | 55.01 | HG0096.all.mosdepth.global.dist.txt, HG0096.all.mosdepth.summary.txt, HG0096.all.regions.bed.gz.csi, HG0096.all.mosdepth.region.dist.txt, HG0096.all.regions.bed.gz | Runs on 4 threads, computes depths by 1000 kb windows, with MAPQ 0, stores stats |
| HG00096 | /usr/bin/time -v mosdepth -t 4 -n --by 1000 --fasta ${FASTA_PATH} HG00096.q20 ${CRAM_FILE_PATH} | 40.53 | HG0096.q20.mosdepth.global.dist.txt, HG0096.q20.mosdepth.summary.txt, HG0096.q20.regions.bed.gz.csi, HG0096.q20.mosdepth.region.dist.txt, HG0096.q20.regions.bed.gz | Runs on 4 threads, computes depths by 1000 kb windows, with MAPQ 20, stores stats |
