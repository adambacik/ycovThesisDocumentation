===============================================================================
 BACHELOR THESIS - STEP-BY-STEP WORK PLAN AND DELIVERABLES
 Visualizing Y Chromosome Coverage Across Individuals
 Created: 14 Oct 2026
===============================================================================

===============================================================================
 SEMESTER 1 (AUTUMN)
===============================================================================

-------------------------------------------------------------------------------
 PHASE 2 - DATA PROCESSING AND PROTOTYPE DEVELOPMENT  (19 Oct - 3 Jan)
-------------------------------------------------------------------------------

Goal: `ycov prepare` turns real and simulated data into a project folder, and
`ycov view` shows it as a heatmap + sequence-class bar + per-sample coverage
lines. Everything is built on the final stack (FastAPI + React + Plotly.js),
so Phase 3 only adds interactivity.
Milestones: M1 = `ycov prepare` works end-to-end (29 Nov),
            M2 = first prototype viewer (13 Dec), M3 = v0.1.0 + Methods draft (20 Dec).
Big data files live on the external disk, not in OneDrive.

## Week 1 (19 Oct - 23 Oct): Get real data
 1. Choose 6-10 male and 2 female 1000 Genomes high-coverage samples that are
    aligned to T2T-CHM13v2.0. Write sample IDs, source URLs, depth, population, superpopulation and sex into phases/phase2/data_sources.md. [x]
 2. Download the T2T-CHM13v2.0 FASTA + .fai exactly as used for those
    alignments. [x]
 3. Find out whether the chrY PARs are masked in it (needed for FR8). [x]
 4. Extract only the needed regions per sample (samtools view on the remote
    CRAM): chrY, chrX and a few autosomes (e.g. chr19-22) for the baseline.
    Index them. Record disk space and time per sample. [10 / 10]
 5. Run mosdepth by hand on one sample (--by 1000, once with all reads, once
    with --mapq 20). Open the result in IGV next to the sample's CRAM. [x]

## Week 1-2 (24 Oct - 27 Oct): Annotations for T2T-CHM13v2.0
 1. Sequence classes: convert Rhie et al. 2023 Suppl. Table 21 into
    sequence_classes.bed (PAR1, PAR2, XTR, XDR, AMPL, P1-P8, HET) with a
    script in scripts/. Check it in IGV / UCSC hs1. [x]
 2. regions.bed: PAR1, PAR2, AZFa, AZFb, AZFc on T2T coordinates (PAR1/2 from
    sequence_classes.bed, AZFa/b/c from official T2T Consortium / MARBL Rhie et al. 2023
    annotations chm13v2.0Y_AZF_DYZ_v1.bed) via scripts/make_regions_bed.sh. Check it in IGV. [x]
 3. Genes: CHM13v2.0 gene annotation (GFF3/GTF) filtered to chrY and chrX -> genes.gtf.gz via scripts/make_genes_gtf.sh. [x]
 4. Gaps: N-runs from the FASTA -> gaps.bed via scripts/make_gaps_bed.sh. [x]
 5. Mappability: create mappability.bw (use an existing hs1 track if one exists using ucsc bigwigtobedgraph and bedgraphtobigwig via scripts/make_mappability.sh). [x]
 6. Extract only chrY mappability from mappability.bw using scripts/make_chrY_mappability.sh into mappability_chrY.bw. [x]
 7. Put everything into src/ycov/annotations/chm13/ with a README listing
    source, version and the command used (NFR14). [x]
 8. First quick-look plot (scripts/quicklook.py, Python Plotly): raw mosdepth
    depth of 1 sample along chrY with the sequence-class bar under it. [x]

## Week 2-3 (28 Oct - 6 Nov): Simulated data with a known truth
 1. scripts/simulate.py: synthetic mosdepth-format coverage per sample
    (autosomes ~30x, chrX/chrY ~15x, random noise, 0 in gaps, noisy and low
    in AMPL/XTR) + truth.tsv describing what was simulated.
    Scenarios: normal male, AZFa / AZFb / AZFc deletion, generic partial AZFc
    deletion (half copy), mLOY 50 %, female (no Y), XYY, shallow 5x sample. []
 2. scripts/simulate_reads.sh: read-level simulation from one real CRAM: remove reads in AZFc (deletion)
    and downsample chrY reads 50 % with samtools view -s (mLOY). Useful
    end-to-end and for the Phase 4 case studies. [x]
 3. scripts/make_test_data.sh: writes sliced tiny data into example_data/ and tests/data/. [x]
 4. scripts/measure_class_effects.py: measures per-class effects based on real data for simulate.py. [x]
 4. Run scripts on data and fill ycov repo folders. [ ]
 5. A tiny version (few Mb, few samples) into tests/data/ and example_data/. [ ]
  
## Week 3-4 (2 - 12 Nov): Processing core - input, windows, coverage
First finish the open Week 2-3 items (simulate.py, tests, tiny data).
Build in pipeline order, write pytest tests for each step on the simulated data.
Scope rule: only what is needed to load coverage and show multiple samples
along chrY with sequence classes (tutor's Phase 2 core features). 
 1. Typer skeleton for `ycov prepare`.
 2. coverage/ reader: one reader for 4-column coverage (chrom, start, end,
    depth) - covers mosdepth .regions.bed.gz and bedGraph -> polars schema
    (sample_id, chrom, start, end, depth) on the 1 kb grid (FR3). Input is
    precomputed coverage (mosdepth --by 1000 run by hand or simulate.py
    output). sample_id = file name without extension. Basic checks inside
    the reader: file exists, chrY/Y naming, one clear error message
    (subset of FR1-FR9). [ ]
 3. windows/: 1 kb grid, gap windows, annotate sequence class with bioframe;
    `reliable` = not gap and not PAR - PAR status hard-coded for the bundled
    CHM13 (answered in Week 1) (subset of FR10-FR14, FR26). [ ]

## Week 5-6 (17 - 25 Nov): Normalisation, project folder
 1. Baseline (autosomal median) and relative copy = depth / baseline, as in
    software_specification.docx (subset of FR19-FR25). PAR windows are
    marked, not normalised (FR27). [ ]
 2. project/: write and read manifest.json and windows/coverage parquet;
    annotations referenced from the package, logging to stderr (FR16). [ ]
 3. Finish `ycov prepare` Typer command with plain progress output. [ ]
 4. Tests against truth.tsv: simulated AZFc deletion gives relative copy ~0
    in AZFc, mLOY ~0.5 on chrY, female ~0 on chrY, normal male ~1. [ ]
 5. Run on the real 1KGP subset. Write down runtime per sample (NFR5). [ ]
 -> M1: `ycov prepare` produces a valid project for real and simulated data.

## Week 6-7 (26 Nov - 6 Dec): Prototype viewer
 1. server/: FastAPI app with GET /api/project (samples, classes, regions),
    /api/heatmap (whole chrY; 1 kb windows merged to 10 kb on request with a
    polars group_by, nothing stored), /api/coverage (start, end, samples);
    pydantic models; a few TestClient tests; listens on 127.0.0.1 only
    (NFR1, NFR2). [ ]
 2. `ycov view`: start uvicorn, serve the built frontend, open the browser,
    one clear error if the project is not found (FR31). [ ]
 3. web/: Vite + React + TypeScript + plotly.js scaffold, plain fetch. [ ]
 4. Components, in this order:
    a. heatmap samples x windows (whole chrY, 10 kb) with colour legend (FR32), [ ]
    b. sequence-class bar aligned with the heatmap x-axis, colour-blind safe
       palette (FR33, NFR12), [ ]
    c. detail view: one coverage line per sample for a region picked from a
       dropdown (whole chrY, PAR1, AZFa/b/c), with the class track and
       Plotly's built-in zoom/pan (FR38) - this is the multi-sample comparison, [ ]
    d. optional, if time allows: raw depth / relative copy toggle (FR57). [ ]
 5. Grey shapes over gap and PAR windows (simplified FR59). [ ]
 -> M2: first prototype loads a project and shows coverage of multiple samples
    along chrY with sequence classes.
 Left for Phase 3: resolution switching while zooming, region/gene search,
 igv.js read view, grouping and sorting by metadata, boxplots, exports,
 sample select/hide (FR42), summary table in the viewer, MAPQ switch (FR58),
 frontend shipped inside the Python package (NFR8), shadcn/ui, TanStack Query,
 generated API types.
 Left for Phase 3: metadata TSV reader (FR29, FR30), per-class summary
 (FR46), Y ratio, stored multi-resolution layers (FR15), separate validate/
 module.
 Left for Phase 3/4: BAM/CRAM input + mosdepth runner (FR17, FR18), bigWig
 reader, build detection, SM-tag sample names, full error catalogue E01-E14,
 Y-internal / X ratio / cohort-relative normalisation, PAR masking detection
 (FR8), genes/AZF/mappability per window, flags + TOML thresholds
 (FR49-FR56), determinism test (NFR15), ycov.log and annotation copies in
 the project folder.

## Week 8 (7 - 13 Dec): Test, release v0.1.0, demo
 1. Run the whole flow on all real + simulated samples, fix bugs. [ ]
 2. First performance numbers: prepare time per sample, overview load time
    (NFR3, NFR5) - they go into the thesis. [ ]
 3. CI: pytest + coverage report, ruff (mypy optional). [ ]
 4. README: install, building the frontend (npm run build), `ycov prepare`
    and `ycov view` on example_data. [ ]
 5. Tag v0.1.0 on GitHub. [ ]
 6. Screenshots of the prototype (simulated AZFc deletion, mLOY sample,
    female sample) for the Methods section and the tutor meeting. [ ]
 -> M3

## Preliminary Methods section (in parallel, start in Week 3)
 1. Set up the thesis document (faculty template - fithesis LaTeX or Word, ask
    tutor) and the bibliography with all Phase 1 sources. [ ]
 2. Write each subsection right after the matching part is implemented: [ ]
    - Data: 1KGP samples, reference build, region extraction, simulated scenarios. [ ]
    - Annotations: sources and processing of classes, PAR/AZF, genes, mappability. [ ]
    - Coverage: windows, mosdepth, MAPQ filtering. [ ]
    - Normalisation: all formulas and why (median, XDR, cohort). [ ]
    - Reliability and PAR handling. [ ]
    - Software architecture and tech stack (from software_design.docx). [ ]
    - Testing and reproducibility. [ ]
 3. Send the draft (about 6-10 pages) to Mariateresa by 20 Dec. [ ]

## Week 9 (14 Dec - 20 Dec): Buffer and handover to Phase 3
 1. Work in tutor feedback on the prototype and on Methods. [ ]
 2. Update requirements.md: what is done, what moves to Phase 3. [ ]
 3. Write the Phase 3 backlog as GitHub issues. [ ]

## Ask Mariateresa
  1. (Week ) Which T2T-aligned 1000 Genomes data to use, or does the lab have
     data? Are the PARs masked in that reference? [ ]
  2. (Week ) Are the simulated scenarios and default thresholds realistic? [ ]
  3. (Week ) Prototype demo and feedback on the Methods draft. [ ]

## PHASE 2 DELIVERABLES
 [D4] Example datasets: real 1KGP subset on T2T-CHM13v2.0 and simulated
      coverage with a truth table, documented in data_sources.md and
      example_data/README.
 [D5] Bundled T2T-CHM13v2.0 annotations (sequence classes, PAR/AZF regions,
      genes, gaps, mappability) with their sources.
 [D6] First prototype ycov v0.1.0 on GitHub: `ycov prepare` (parsing,
      windows, relative-copy normalisation, project folder)
      and `ycov view` (heatmap, sequence-class bar, multi-sample coverage
      lines), tests and green CI.
 [D7] Preliminary thesis Methods section.
