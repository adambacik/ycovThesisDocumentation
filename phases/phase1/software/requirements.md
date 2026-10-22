# ycov – Requirements

**Priority:** Must = required for the thesis · Should = planned, can be cut if time runs out · Could = only if time allows · Future = deferred to a later version, described in the thesis as future work
**Source:** UC = use case · TR = gap found in existing_tools_review · LR = literature_review · TF = tutor feedback (Oct 2026)

**Reference builds:** T2T-CHM13v2.0 is the primary build. GRCh38 is the second build, added if time allows. All coordinates in the documents refer to T2T-CHM13v2.0 unless stated otherwise.

## Actors

| Actor | Type | Description |
| --- | --- | --- |
| User (researcher) | Primary | Geneticist, bioinformatician or student with sequencing data from a group of male samples, who wants to know whether each sample's Y chromosome is complete. Knows basic genomics, not necessarily a programmer. |
| mosdepth | Secondary, system | External program that ycov calls to compute read depth from BAM/CRAM files. |
| samtools | Secondary, system | External program used for index checks and as a fallback for depth computation. |

## Use cases

Numbering matches software_design.docx.

| ID | Name | Description (user's goal) | Status |
| --- | --- | --- | --- |
| UC01 | Prepare project | User runs `ycov prepare` on BAM/CRAM files (with indexes) or on precomputed coverage files. The system validates the inputs, computes, normalises and annotates coverage, computes summaries and flags, and saves everything into a project folder. Includes UC12. | in scope |
| UC02 | Review cohort summary | User reviews per-sample, per-class statistics as a table and boxplots, and the sample-level X and Y ratios. | in scope |
| UC03 | Save and restore session | User saves the current view (region, selected samples, grouping, toggles) and opens it again later. | Future (TF) |
| UC04 | Filter, group and sort | User hides or selects samples, groups them by a metadata column and sorts them. Ordering by clustering is future work. | in scope |
| UC05 | Open project overview | User runs `ycov view` to see all samples across the whole chrY at once in the browser, organised by sequence class. | in scope |
| UC06 | Attach optional data | User supplies an optional CSV/TSV file with sample ID, population, age, phenotype etc., so samples can later be filtered and grouped. Includes UC12. | in scope |
| UC07 | Distinguish real loss from artefact | User switches the MAPQ filter and the normalisation mode and checks reliability marks to decide whether low coverage means missing DNA, a mapping limitation or a region that is not assessable on chrY (PAR). | in scope |
| UC08 | Review automatic flags | User reviews a list of warnings about suspicious coverage (deletion candidate, known-region loss, possible mLOY, sex check, low confidence, outlier sample) and jumps to a flagged region. | in scope |
| UC09 | Export results | User exports figures (PNG/SVG/PDF), tables (CSV/TSV) and flagged regions (BED). The single-file HTML report is future work. | in scope |
| UC10 | Navigate and inspect | User zooms and pans, or jumps to a coordinate, gene, sequence class or named region, and inspects the region (coverage lines with gene, mappability and sequence-class tracks). | in scope |
| UC11 | Inspect reads | User examines a selected region more closely in an embedded igv.js read view, when zoomed in to ≤ ~30 kb and the BAM/CRAM is available. Extends UC10. | in scope |
| UC12 | Validate input | Included in UC01 and UC06: the system checks input files and reports problems before any processing. | in scope |

## Functional requirements

| ID | Requirement | UC | Priority | Source |
| --- | --- | --- | --- | --- |
| **Input and validation** | | | | |
| FR1 | The system shall accept aligned reads in BAM and CRAM format with their .bai/.crai index files. | UC01 | Must | TR |
| FR2 | The system shall accept a reference FASTA file (with .fai) when the input is CRAM. | UC01 | Must | Spec |
| FR3 | The system shall accept precomputed coverage in bedGraph, bigWig and mosdepth output format instead of BAM/CRAM. If it contains no autosomal coverage, the baseline shall be taken from a `baseline` column in the metadata file. | UC01 | Should | Spec |
| FR4 | The system shall check that every input file exists, is readable and has an index, that sample names are unique and that all inputs use the same build, and shall report each problem with the file name and a suggested fix. | UC12 | Must | – |
| FR5 | The system shall detect the reference build from the chrY length (T2T-CHM13v2.0: 62,460,029 bp; GRCh38: 57,227,415 bp) and stop with an error if the build is not supported. | UC12 | Must | LR (Rhie 2023) |
| FR6 | The system shall support the T2T-CHM13v2.0 reference build. | UC01 | Must | TF, LR (Rhie 2023) |
| FR7 | The system shall support the GRCh38 reference build. | UC01 | Could | TF |
| FR8 | The system shall detect whether the chrY pseudoautosomal regions were masked in the reference used for alignment (from N content of the FASTA, or from near-zero PAR coverage across all samples), and record the result in the manifest. | UC01, UC12 | Must | TF, LR (Rhie 2023) |
| FR9 | The system shall accept both `chrY` and `Y` chromosome naming. | UC12 | Must | – |
| **Windows and annotation** | | | | |
| FR10 | The system shall split chrY into windows (default 1 kb, configurable) and mark windows that are gaps (N) in the reference. | UC01 | Must | – |
| FR11 | The system shall annotate every window with its sequence class: PAR1, PAR2, XTR, XDR, AMPL, palindrome P1–P8, HET (heterochromatin, including centromeric satellites). | UC01 | Must | TR, LR |
| FR12 | The system shall annotate windows with overlapping genes, AZF region (AZFa, AZFb, AZFc) and mean mappability. | UC01 | Should | TR |
| FR13 | The system shall mark each window as reliable or not. Not reliable: AMPL, palindromes, XTR, HET, gap and low-mappability windows (threshold configurable). PAR windows have a separate state *not assessable on chrY* (see FR27). | UC01, UC07 | Must | LR, TF |
| FR14 | The system shall include bundled sequence-class, PAR, gene, AZF-region and mappability annotations for every supported build (for T2T-CHM13v2.0: sequence classes from Rhie et al. 2023, Suppl. Table 21; genes from the T2T consortium annotation; mappability computed for the build). | UC01 | Must | – |
| FR15 | The system shall store coverage at two resolutions, 1 kb and 10 kb. Coarser views (whole chrY) shall be aggregated from the 10 kb data on the fly. | UC01, UC05 | Must | TF |
| FR16 | The system shall save the results into a project folder (manifest, sample table, window annotations, coverage tables, summaries, flags, copies of the annotations used, log). | UC01 | Must | – |
| **Coverage and normalisation** | | | | |
| FR17 | The system shall compute mean read depth per window along chrY. | UC01 | Must | – |
| FR18 | The system shall compute every depth value twice: for all reads and for reads with MAPQ ≥ threshold (default 20). | UC01 | Must | LR |
| FR19 | The system shall compute each sample's autosomal baseline as the median of the mean depths of 10 kb windows on chromosomes 1–22, excluding gap and low-mappability windows, using the same MAPQ filter as the chrY values. | UC01 | Must | LR, TF |
| FR20 | The system shall compute the relative copy number of every window as `depth / (baseline / 2)`, so that 1.0 is the expected value for single-copy male-specific sequence. | UC01 | Must | LR, TF |
| FR21 | The system shall compute a Y-internal normalisation of every window as `depth / median depth of reliable XDR windows` of the same sample. | UC01 | Should | TF |
| FR22 | The system shall compute a cohort-relative value of every window as `relative copy / cohort median relative copy of that window`. Samples failing the sex check (FR38) shall be excluded from the cohort median, and the step shall be skipped for fewer than 5 samples. | UC01 | Should | TF |
| FR23 | The system shall compute each sample's Y ratio as the median relative copy of reliable XDR windows. | UC01, UC02 | Must | LR |
| FR24 | The system shall compute each sample's X ratio as the median depth of non-PAR chrX windows divided by the autosomal baseline (expected ≈ 0.5 for XY, ≈ 1.0 for XX). | UC01, UC02 | Should | TF |
| FR25 | The exact formulas of all normalisation modes shall be documented in the specification and the user documentation. | UC07 | Must | TF |
| **Pseudoautosomal regions** | | | | |
| FR26 | PAR windows shall be excluded from deletion and known-region flags, from the Y ratio and from the per-class statistics of the male-specific region. | UC07, UC08 | Must | TF |
| FR27 | If the chrY PARs were masked in the reference (FR8), PAR windows shall be shown as *not assessable on chrY* in all views instead of as coverage loss. | UC05, UC07 | Must | TF |
| FR28 | The system shall report PAR dosage per sample measured on the chrX PAR (relative copy, expected ≈ 2 in XY males). | UC02 | Could | TF |
| **Sample metadata** | | | | |
| FR29 | The system shall accept a CSV/TSV metadata file with a required `sample_id` column and any number of other columns. | UC06 | Should | – |
| FR30 | The system shall report metadata rows that match no sample and samples that have no metadata. | UC06, UC12 | Should | – |
| **Overview** | | | | |
| FR31 | `ycov view <project>` shall start a local server and open the interface in the default web browser. | UC05 | Must | – |
| FR32 | The system shall display a heatmap with samples as rows and chrY windows as columns, coloured by the current normalisation mode, with a colour legend. | UC05 | Must | TR |
| FR33 | The system shall display a sequence-class bar aligned with the heatmap's x-axis, with a legend. | UC05 | Must | TR |
| FR34 | The system shall display project information: reference build, PAR masking, number of samples and processing parameters. | UC05 | Could | – |
| **Navigation and detail** | | | | |
| FR35 | The user shall be able to zoom and pan by dragging and scrolling; the system shall switch to the 1 kb resolution when zoomed in. | UC10 | Must | – |
| FR36 | The user shall be able to jump to a region by typing coordinates (e.g. `chrY:20000000-26000000`). | UC10 | Must | TR |
| FR37 | The user shall be able to jump to a gene by name, to a sequence class or to a named region (AZFa, AZFb, AZFc). | UC10 | Should | TR |
| FR38 | The system shall show a detail view with one coverage line per selected sample for the selected region. | UC10 | Must | – |
| FR39 | The detail view shall show gene, sequence-class and mappability tracks. | UC10 | Should | TR |
| FR40 | The detail view shall show an embedded igv.js read view for one sample when zoomed in to ≤ ~30 kb and its BAM/CRAM is available. igv.js shall use the local reference FASTA and the locally served files. | UC11 | Should | TF |
| FR41 | Selecting a region or sample in the heatmap shall update the detail view and the summary. | UC10 | Should | – |
| **Samples** | | | | |
| FR42 | The user shall be able to select and hide samples. | UC04 | Must | – |
| FR43 | The user shall be able to group samples by a metadata column. | UC04 | Must | TF |
| FR44 | The user shall be able to sort samples by name, Y ratio, X ratio or a metadata column. | UC04 | Must | TF |
| FR45 | The user shall be able to order samples by hierarchical clustering of their coverage profiles. | UC04 | Future | TF |
| **Summary** | | | | |
| FR46 | The system shall show a table of per-sample, per-class statistics: mean and median coverage, % of windows below threshold, MAPQ-0 fraction. | UC02 | Must | TR |
| FR47 | The system shall show per-class boxplots across samples. | UC02 | Should | – |
| FR48 | The system shall show each sample's Y ratio and X ratio, including an X-ratio vs Y-ratio scatter plot. | UC02 | Could | TF |
| **Flags** | | | | |
| FR49 | The system shall flag a deletion candidate when at least N consecutive reliable windows are below threshold T (defaults: 50 windows, 0.2 relative copy). | UC08 | Must | TR |
| FR50 | The system shall flag a known-region loss when mean relative copy of AZFa, AZFb or AZFc is below threshold (default 0.5). | UC08 | Must | LR (Colaco & Modi 2018) |
| FR51 | The system shall mark a flag as low-confidence when it lies in an ampliconic, palindromic, XTR, HET or low-mappability region. | UC07, UC08 | Must | LR |
| FR52 | The system shall flag possible mosaic loss of Y when a sample's Y ratio is below threshold. | UC08 | Should | LR (Forsberg 2014) |
| FR53 | The system shall flag samples with almost no chrY coverage (very low Y ratio: female, mislabelled sample or 45,X) and samples with unusually high Y ratio (possible extra Y). The flag is a hint only, karyotype is not inferred. | UC08 | Should | TF |
| FR54 | The system shall flag samples whose coverage profile differs strongly from the cohort. | UC08 | Could | – |
| FR55 | The flag list shall be sortable and filterable by sample, type, severity and confidence, and clicking a flag shall jump to its region. | UC08 | Must | – |
| FR56 | All flagging thresholds shall be configurable, with documented defaults. | UC08 | Must | – |
| **Real loss vs artefact** | | | | |
| FR57 | The user shall be able to switch every view between all reads and MAPQ-filtered reads. | UC07 | Must | LR |
| FR58 | The user shall be able to switch the normalisation mode: raw depth, relative copy (autosomal baseline), Y-internal (XDR), cohort-relative. | UC07 | Must | TR, TF |
| FR59 | The system shall visually mark low-reliability windows in the heatmap and the detail view, with a separate mark for PAR windows that are not assessable on chrY. | UC07 | Must | LR, TF |
| FR60 | The detail view shall show the MAPQ-0 fraction per window. | UC07 | Should | LR |
| **Export** | | | | |
| FR61 | The user shall be able to export the current figure as PNG, SVG or PDF. | UC09 | Must | TR |
| FR62 | The user shall be able to export the summary table and the flag list as CSV/TSV. | UC09 | Must | TR |
| FR63 | The user shall be able to export flagged regions as a BED file. | UC09 | Should | TR |
| FR64 | The user shall be able to export a single-file HTML report of the cohort. | UC09 | Future | TF |
| **Session** | | | | |
| FR65 | The user shall be able to save the current view state (region, selected samples, grouping, toggles) to a file and restore it later. | UC03 | Future | TF |

## Non-functional requirements

| ID | Category | Requirement | Priority |
| --- | --- | --- | --- |
| NFR1 | Privacy | All processing and viewing shall run locally, no input data or results are sent over the network. | Must |
| NFR2 | Privacy | The web server shall listen only on `localhost` by default. | Must |
| NFR3 | Performance | The overview of a 100-sample project shall load in ≤ 3 s on a standard laptop (8 GB RAM). | Must |
| NFR4 | Performance | The view shall update in ≤ 1 s after zooming or panning. | Should |
| NFR5 | Performance | `ycov prepare` shall process one 30× sample (chrY, chrX and autosomal baseline) in ≤ 10 min and shall be able to process samples in parallel. | Should |
| NFR6 | Scalability | The viewer shall remain usable with at least 500 samples. | Should |
| NFR7 | Resource use | The project folder shall take ≤ 100 MB per 100 samples; the viewer shall use ≤ 2 GB RAM. | Should |
| NFR8 | Installability | The tool shall install with `pip install ycov` on Linux, macOS and Windows (WSL), without Node.js. | Must |
| NFR9 | Compatibility | The interface shall work in current versions of Chrome, Firefox and Edge. | Must |
| NFR10 | Compatibility | Inputs and outputs shall follow the standard format specifications (SAM/BAM/CRAM, BED 0-based half-open, bigWig). Exported BED shall load in IGV and UCSC. | Must |
| NFR11 | Usability | A new user shall find a known AZFc deletion in the example project within 5 minutes using only the tutorial. | Should |
| NFR12 | Usability | Every sequence class shall have a consistent colour and a legend, the palette shall be colour-blind safe. | Should |
| NFR13 | Usability, reliability | Error messages shall state what went wrong, in which file and how to fix it, without raw stack traces. | Must |
| NFR14 | Reproducibility | Every project and export shall record the ycov version, reference build, PAR masking, normalisation mode, parameters and annotation sources. | Must |
| NFR15 | Reproducibility | Running `prepare` twice with the same inputs and parameters shall give identical results. | Must |
| NFR16 | Correctness | Normalisation, PAR handling and flagging shall be covered by automated tests on simulated data with a known truth. | Must |
| NFR17 | Maintainability | Processing, server and interface shall be separate modules; a new reference build shall be addable through configuration and annotation files only. | Must |
| NFR18 | Maintainability | Tests shall run automatically on every push (CI), test coverage of the core module shall be ≥ 70 %. | Should |
| NFR19 | Documentation | A README, installation guide, tutorial on example data, input-format reference, normalisation reference and FAQ shall be provided. | Must |
| NFR20 | Licensing | The source code shall be public under an open licence (e.g. MIT). | Should |
| NFR21 | Offline use | The interface shall work without an internet connection: igv.js and all other libraries are bundled, no external CDN or hosted genomes are used. | Should |
| NFR22 | Intended use | The tool and its documentation shall state that it is for research use, not clinical diagnosis. Flags are hints for inspection. | Must |
| NFR23 | Code | The frontend shall be written in TypeScript. | Must |
| NFR24 | Code | The backend shall be written in Python. | Must |

## Future work

Deferred after tutor feedback, to be described in the thesis as future directions:

- Save and restore session (UC03, FR65).
- Single-file HTML report (FR64).
- Ordering samples by hierarchical clustering (FR45).
- Stored coarser resolutions (100 kb, 1 Mb), if on-the-fly aggregation is too slow.
- Sex chromosome aneuploidies (47,XXY, 47,XYY, 45,X and mosaics): karyotype estimation from the X and Y ratios (FR24) and PAR dosage (FR28), depending on the availability of such samples.
- GC-content bias correction of window depth.
