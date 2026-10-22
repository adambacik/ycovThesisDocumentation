# Data sources

## Data preview table

Source: AnVIL `ANVIL_T2T_CHRY` (CRAMs aligned to CHM13v2.0). Selection: 10 samples from 1000 Genomes GBR (EUR): 8 males, 2 females.
Population from the IGSR 3202-sample sheet; depth = whole-genome mean coverage from `<ID>.mosdepth.summary.txt`; karyotype confirmed from chrX/chrY mean coverage.
CRAM / CRAI path is the public AnVIL S3 mirror, where each file is named by its MD5: `https://anvilproject.s3.amazonaws.com/file/<files.file_md5sum>.md5`.
(The `files.azul_url` links in the manifest stopped working (HTTP 404) after AnVIL re-indexed the dataset; checked 17 Oct 2026, S3 file sizes match the manifest.)
Read regions remotely with `samtools view "<CRAM>##idx##<CRAI>" chrY ...`, or download with `curl -o <ID>.cram "<URL>"`.

| ID  | Karyotype | Population | Superpopulation | Depth | CRAM path | CRAI path |
| --- | --- | --- | --- | --- | --- | --- |
| HG00096 | XY | GBR | EUR | 33.3 | https://anvilproject.s3.amazonaws.com/file/71d42a36eb86dbf3b0bcca7fe02eb864.md5 | https://anvilproject.s3.amazonaws.com/file/62e0f69e223ab4abf17f92fe5b326826.md5 |
| HG00101 | XY | GBR | EUR | 33.3 | https://anvilproject.s3.amazonaws.com/file/554a4b84ab31a1f25df97085c606374b.md5 | https://anvilproject.s3.amazonaws.com/file/450f6a65ea638897c8a43a8bdbeb749f.md5 |
| HG00103 | XY | GBR | EUR | 32.0 | https://anvilproject.s3.amazonaws.com/file/89ceb594dbf3870c2c7fe09b92d8cd8b.md5 | https://anvilproject.s3.amazonaws.com/file/5c0df0305a89b9878cfd6555e405077a.md5 |
| HG00105 | XY | GBR | EUR | 28.9 | https://anvilproject.s3.amazonaws.com/file/57aebc3edcc8fe2efb660e560bb577a3.md5 | https://anvilproject.s3.amazonaws.com/file/ad04f033fd0086d671023d66395a401c.md5 |
| HG00107 | XY | GBR | EUR | 32.4 | https://anvilproject.s3.amazonaws.com/file/d27907a6735262bad9638fe354bddf52.md5 | https://anvilproject.s3.amazonaws.com/file/a7868cd6279060fccdd85ee0ed5c5c87.md5 |
| HG00108 | XY | GBR | EUR | 32.1 | https://anvilproject.s3.amazonaws.com/file/703b6468c5623fec5c304a50a15f88ca.md5 | https://anvilproject.s3.amazonaws.com/file/a62235b72f5a2c053783912011e5c55f.md5 |
| HG00109 | XY | GBR | EUR | 35.2 | https://anvilproject.s3.amazonaws.com/file/c7624c5d265ce542eb2e2d4a474a55c6.md5 | https://anvilproject.s3.amazonaws.com/file/1178c0e45a101f69341229bc03052bc4.md5 |
| HG00112 | XY | GBR | EUR | 32.1 | https://anvilproject.s3.amazonaws.com/file/a679b75940cffa3a2ade989735aaa843.md5 | https://anvilproject.s3.amazonaws.com/file/afaee5dab93c8420991e9c6ddbb592c7.md5 |
| HG00097 | XX | GBR | EUR | 33.1 | https://anvilproject.s3.amazonaws.com/file/1d4dd66d783bdaaa99ea287602bbe6eb.md5 | https://anvilproject.s3.amazonaws.com/file/1fba300dd466c0c8deedce6e32ae77d7.md5 |
| HG00099 | XX | GBR | EUR | 37.6 | https://anvilproject.s3.amazonaws.com/file/6dbca2a093606ae3682bf388adc1c960.md5 | https://anvilproject.s3.amazonaws.com/file/ecee7b475ce9d887e70d13702bbec1d3.md5 |

## Reference genome

Source: same AnVIL dataset (`ANVIL_T2T_CHRY`), downloaded with `download_reference.sh`; MD5 checked against the manifest.
Masking checked with `check_par_masking.sh` (counts N bases per region).

| FASTA | Used for | PAR1 on chrY masked | PAR2 on chrY masked | Whole chrY masked | PARs on chrX masked | chrY PAR1 coordinates | chrY PAR2 coordinates |
| --- | --- | --- | --- | --- | --- | --- | --- |
| chm13v2.0.fasta | decoding the remote AnVIL CRAMs (all samples) | no | no | no | no | 1-2458320 | 62122810-62460029 |
| chm13v2.0.XX.fasta | XX (female) CRAMs | yes | yes | yes | no | 1-2458320 | 62122810-62460029 |
| chm13v2.0.XY.fasta | XY (male) CRAMs | yes | yes | no (only PARs) | no | 1-2458320 | 62122810-62460029 |


Which reference the CRAMs were aligned to (chrY `M5` in CRAM header vs `.dict`):
- HG00096 (XY): chrY M5 `dd7264df17e7e4a4dac5b0f1f19dcfe0` -> chm13v2.0.XY.fasta
- HG00097 (XX): chrY M5 `40d26ed39899fc0198762197d8c0e682` -> chm13v2.0.XX.fasta
- chrX and autosomes have the same M5 in all three FASTAs.
- The header `UR:` field says `chm13v2.0.fasta` (unmasked) for both.

So: males were **aligned** to the XY reference (chrY PARs masked), females to the XX reference (whole chrY masked),
but the CRAMs were **compressed** with the unmasked `chm13v2.0.fasta` (as `UR:` says). Found when decoding chrY of HG00096
with the XY FASTA failed: `MD5 checksum reference mismatch at chrY:2244155-2539922` (slice crossing the PAR1 end).

Consequences:
- Reading the remote AnVIL CRAMs: use `chm13v2.0.fasta` (unmasked). chrX and autosomes are identical in all three FASTAs,
  so the XY FASTA only fails on slices touching the chrY PARs.
- Writing a CRAM with the unmasked FASTA is refused by htslib (`SQ header M5 tag discrepancy for reference 'chrY'`),
  because the header still carries the XY M5. So subsets are re-encoded with the FASTA matching the header:
  `samtools view -u -T chm13v2.0.fasta <remote> <regions> | samtools view -C -T chm13v2.0.XY.fasta -o <out>.cram --write-index -`
  (XX FASTA for females).
- Everything on the local subsets (mosdepth, IGV, ycov) uses the XY / XX FASTA.
