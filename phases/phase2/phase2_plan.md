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
    Index them. Record disk space and time per sample. [1 / 10]
 5. Run mosdepth by hand on one sample (--by 1000, once with all reads, once
    with --mapq 20). Open the result in IGV next to the sample's CRAM. [x]

## Week 1-2 (24 Oct - 28 Oct): Annotations for T2T-CHM13v2.0
 1. Sequence classes: convert Rhie et al. 2023 Suppl. Table 21 into
    sequence_classes.bed (PAR1, PAR2, XTR, XDR, AMPL, P1-P8, HET) with a
    script in scripts/. Check it in IGV / UCSC hs1. [ ]
 2. regions.bed: PAR1, PAR2, AZFa, AZFb, AZFc on T2T coordinates (lift over
    GRCh38 coordinates with the UCSC hg38->hs1 chain, write down the source). [ ]
 3. Genes: CHM13v2.0 gene annotation (GFF3) filtered to chrY and chrX -> genes.gtf.gz. [ ]
 4. Gaps: N-runs from the FASTA -> gaps.bed. [ ]
 5. Mappability: compute with GenMap (k = read length) for chrY, chrX and the
    baseline autosomes -> bigWig, or use an existing hs1 track if one exists. [ ]
 6. Put everything into src/ycov/annotations/chm13/ with a README listing
    source, version and the command used (NFR14). [ ]
 7. First quick-look plot (scripts/quicklook.py, Python Plotly): raw mosdepth
    depth of 1 sample along chrY with the sequence-class bar under it. [ ]

## Week 2-3 (29 Oct - 3 Nov): Simulated data with a known truth
 1. scripts/simulate.py: synthetic mosdepth-format coverage per sample
    (autosomes ~30x, chrX/chrY ~15x, random noise, 0 in gaps, noisy and low
    in AMPL/XTR) + truth.tsv describing what was simulated. [ ]
 2. Scenarios: normal male, AZFa / AZFb / AZFc deletion, partial AZFc
    (gr/gr-like), mLOY 50 %, female (no Y), XYY, shallow 5x sample, PAR-masked
    reference. [ ]
 3. Read-level simulation from one real CRAM: remove reads in AZFc (deletion)
    and downsample chrY reads 50 % with samtools view -s (mLOY). Useful
    end-to-end and for the Phase 4 case studies. [ ]
 4. A tiny version (few Mb, few samples) into tests/data/ and example_data/. [ ]

## Week 3-4 (4 - 12 Nov): Processing core - input, windows, coverage
Build in pipeline order, write pytest tests for each step on the simulated data.
 1. validate/: file and index checks, format detection (BAM, CRAM, bedGraph,
    bigWig, mosdepth), build detection from chrY length, chrY/Y naming,
    sample name from SM tag, unique names; errors E01-E11 as exceptions with
    the messages from the spec (FR1-FR9, FR4, NFR13). [ ]
 2. windows/: 1 kb grid, gap windows, annotate class, genes, AZF and
    mappability with bioframe, `reliable` column (FR10-FR14). [ ]
 3. coverage/ readers: bedGraph, mosdepth .regions.bed.gz, bigWig (pyBigWig)
    -> one polars schema (sample_id, chrom, start, end, depth), rebinned to the
    window grid (FR3). [ ]
 4. coverage/ mosdepth runner: call mosdepth twice (all reads / MAPQ >= q)
    for chrY+chrX at 1 kb and autosomes at 10 kb; clear error if mosdepth is
    missing (FR17, FR18). [ ]
 5. Metadata CSV/TSV reader with checks (FR29, FR30, E09, W02). [ ]

## Week 5-6 (17 - 25 Nov): Normalisation, summary, flags, project folder
 1. Baseline, relative copy, Y ratio, Y-internal, X ratio, cohort-relative,
    exactly as the formulas in software_specification.docx (FR19-FR25). [ ]
 2. PAR masking detection and PAR handling (FR8, FR26, FR27). [ ]
 3. 10 kb aggregation (FR15). [ ]
 4. Summary per sample x class, without PAR and HET (FR46). [ ]
 5. Flags: deletion candidate, known-region loss, low confidence, mLOY, sex
    check (FR49-FR53); thresholds in a TOML config (FR56). [ ]
 6. project/: write and read manifest.json, samples/windows/coverage/summary
    parquet, flags.json, annotation copies and ycov.log (FR16, NFR14). [ ]
 7. `ycov prepare` Typer command with rich progress output, as in the spec mockup. [ ]
 8. Tests against truth.tsv: every simulated deletion / mLOY / female sample
    is flagged correctly, normal samples are not (NFR16). Run prepare twice and
    compare outputs (NFR15). [ ]
 9. Run on the real 1KGP subset. Write down runtime per sample (NFR5). [ ]
 -> M1: `ycov prepare` produces a valid project for real and simulated data.

## Week 6-7 (26 Nov - 6 Dec): Prototype viewer
 1. server/: FastAPI app with GET /api/project, /api/samples, /api/windows,
    /api/coverage (region, resolution, mode, mapq, samples), /api/summary,
    /api/flags; pydantic models; tests with TestClient; listens on 127.0.0.1
    only (NFR1, NFR2). [ ]
 2. `ycov view`: start uvicorn, serve the built frontend, open the browser,
    errors E12-E14 (FR31). [ ]
 3. web/: Vite + React + TypeScript + Tailwind + shadcn/ui scaffold,
    API types generated with openapi-typescript, TanStack Query. [ ]
 4. Components, in this order:
    a. heatmap samples x windows (whole chrY, 10 kb) with colour legend (FR32), [ ]
    b. sequence-class bar aligned with the heatmap x-axis, colour-blind safe
       palette (FR33, NFR12), [ ]
    c. detail view: one coverage line per selected sample for a fixed region,
       with the class track (FR38) - this is the multi-sample comparison, [ ]
    d. switches for normalisation mode and MAPQ (FR57, FR58), [ ]
    e. sample list with select / hide (FR42), [ ]
    f. read-only summary table and flag list (FR46, FR55 basic). [ ]
 5. Grey/hatched marks for unreliable and PAR windows (FR59). [ ]
 6. Check that the built frontend is shipped inside the Python package, so
    pip install needs no Node.js (NFR8). [ ]
 -> M2: first prototype loads a project and shows coverage of multiple samples
    along chrY with sequence classes.
 Left for Phase 3: resolution switching while zooming, region/gene search,
 igv.js read view, grouping and sorting by metadata, boxplots, exports.

## Week 8 (7 - 13 Dec): Test, release v0.1.0, demo
 1. Run the whole flow on all real + simulated samples, fix bugs. [ ]
 2. First performance numbers: prepare time per sample, overview load time
    (NFR3, NFR5) - they go into the thesis. [ ]
 3. CI: pytest + coverage report, ruff, mypy; frontend type check, lint and
    one Vitest smoke test. [ ]
 4. README: install, `ycov prepare` and `ycov view` on example_data. [ ]
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
    - Flagging rules and default thresholds. [ ]
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
  2. (Week ) Correct source of AZFa/b/c coordinates on T2T. [ ]
  3. (Week ) Mappability: compute it ourselves, which k? [ ]
  4. (Week ) Are the simulated scenarios and default thresholds realistic? [ ]
  5. (Week ) Prototype demo and feedback on the Methods draft. [ ]

## PHASE 2 DELIVERABLES
 [D4] Example datasets: real 1KGP subset on T2T-CHM13v2.0 and simulated
      coverage with a truth table, documented in data_sources.md and
      example_data/README.
 [D5] Bundled T2T-CHM13v2.0 annotations (sequence classes, PAR/AZF regions,
      genes, gaps, mappability) with their sources.
 [D6] First prototype ycov v0.1.0 on GitHub: `ycov prepare` (parsing,
      windows, normalisation, summary, flags, project folder) and `ycov view`
      (heatmap, sequence-class bar, multi-sample coverage lines, mode/MAPQ
      switches), tests and green CI.
 [D7] Preliminary thesis Methods section.
