# Data preview

## Extraction of needed regions

### Extract regions

/usr/bin/time -v samtools view -u -T ${FASTA_FILE_PATH} "${CRAM_LINK}##idx##${CRAM_INDEX_LINK}" chr19 chr20 chr21 chr22 chrX chrY | samtools view -C -T ${FASTA_FILE_PATH} -o ${OUTPUT_FILE_NAME}.cram --write-index -

### Find out the file disk size

du -h ${CRAM_PATH}

### Preview table

| Sample ID | Regions extracted | CRAM file name | CRAM index file name | Tool | CRAM disk size (GB) |
| --- | --- | --- | --- | --- | --- |
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
| HG00096 | /usr/bin/time -v mosdepth -t 4 -n --by 1000 --fasta ${FASTA_PATH} HG00096.all ${CRAM_FILE_PATH} | 55.01 | HG00096.all.mosdepth.global.dist.txt, HG00096.all.mosdepth.summary.txt, HG00096.all.regions.bed.gz.csi, HG00096.all.mosdepth.region.dist.txt, HG00096.all.regions.bed.gz | Runs on 4 threads, computes depths in 1 kb (1000 bp) windows, all reads (no MAPQ filter), stores stats |
| HG00096 | /usr/bin/time -v mosdepth -t 4 -n --by 1000 --fasta ${FASTA_PATH} HG00096.q20 ${CRAM_FILE_PATH} | 40.53 | HG00096.q20.mosdepth.global.dist.txt, HG00096.q20.mosdepth.summary.txt, HG00096.q20.regions.bed.gz.csi, HG00096.q20.mosdepth.region.dist.txt, HG00096.q20.regions.bed.gz | Runs on 4 threads, computes depths in 1 kb (1000 bp) windows, reads with MAPQ ≥ 20, stores stats |

## Runtime of `ycov prepare` on the real 1KGP subset (Week 4-5, step 5)

Machine: AMD Ryzen 7 7840HS, Ubuntu Linux in a virtual machine, 4 cores and ~7 GB RAM visible
Data on: the VM's virtual disk (~27 GB)
Date: 20 Nov 2026, ycov 0.1.0
Input: full mosdepth outputs (all reads, `--by 1000`) of the subset CRAMs, not the `example_data/real` slices.
The input files are named `<ID>.regions.bed.gz` (see `project_10/manifest.json`), not
`<ID>.all.regions.bed.gz` as in the mosdepth runs above, so the sample ID is the plain
1000 Genomes ID.

These are the Week 4-5 runs on 1-10 real samples. The Week 7 measurement in
`phase2_plan.md` (about 0.13 s per sample) is a separate, later run.

### `ycov prepare` per run

Command:
/usr/bin/time -v ycov prepare <real_mosdepth>/<samples>.regions.bed.gz -o <project>

| Samples | Wall time (s) | Time per sample (s) | Peak memory (MB) |
| --- | --- | --- | --- |
| 1 | 1.28 | 1.28 | 310.00 |
| 5 | 3.32 | 0.66 | 513.14 |
| 10 | 12.66 | 1.27 | 678.21 |

## Plausibility of the real-data project

| Sample ID | Karyotype | Genome depth (data_sources.md) | ycov baseline | X-DEG median RC | AMPL median RC | HET median RC |
| --- | --- | --- | --- | --- | --- | --- |
| HG00096 | XY | 33.3 | 34.87 | 0.93 | 0.94 | 0.70 |
| HG00101 | XY | 33.3 | 35.10 | 0.95 | 0.95 | 0.72 |
| HG00103 | XY | 32.0 | 33.52 | 0.94 | 0.93 | 0.57 |
| HG00105 | XY | 28.9 | 30.14 | 0.96 | 0.95 | 0.58 |
| HG00107 | XY | 32.4 | 33.93 | 0.96 | 0.97 | 0.58 |
| HG00108 | XY | 32.1 | 33.47 | 0.95 | 0.95 | 0.66 |
| HG00109 | XY | 35.2 | 36.71 | 0.96 | 0.94 | 0.66 |
| HG00112 | XY | 32.1 | 33.62 | 0.96 | 0.97 | 0.61 |
| HG00097 | XX | 33.1 | 33.79 | 0.00 | 0.00 | 0.00 |
| HG00099 | XX | 37.6 | 38.92 | 0.00 | 0.00 | 0.00 |

Source: `project_10` (`ycov prepare` on all 10 samples). Baseline from `manifest.json`. Median RC over the reliable chrY windows of each class (X-DEG 8666, AMPL 10080, HET 34623 windows per sample).
