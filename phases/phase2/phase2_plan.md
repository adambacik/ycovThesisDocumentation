===============================================================================
 BACHELOR THESIS - STEP-BY-STEP WORK PLAN AND DELIVERABLES
 Visualizing Y Chromosome Coverage Across Individuals
 Created: 14 Oct 2026
===============================================================================

===============================================================================
 SEMESTER 1 (AUTUMN)
===============================================================================

-------------------------------------------------------------------------------
 PHASE 2 - DATA PROCESSING AND PROTOTYPE DEVELOPMENT  (19 Oct - 13 Dec)
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
    deletion (half copy), mLOY 50 %, female (no Y), XYY, shallow 5x sample. [x]
 2. scripts/simulate_reads.sh: read-level simulation from one real CRAM: remove reads in AZFc (deletion)
    and downsample chrY reads 50 % with samtools view -s (mLOY). Useful
    end-to-end and for the Phase 4 case studies. [x]
 3. scripts/make_test_data.sh: writes sliced tiny data into example_data/ and tests/data/. [x]
 4. scripts/measure_class_effects.py: measures per-class effects based on real data for simulate.py. [x]
 4. Run scripts on data and fill ycov repo folders. [x]
 5. A tiny version (few Mb, few samples) into tests/data/ and example_data/. [x]
  
## Week 3 (2 - 7 Nov): Processing core - input, windows, coverage
First finish the open Week 2-3 items (simulate.py, tests, tiny data).
Build in pipeline order, write pytest tests for each step on the simulated data.
Scope rule: only what is needed to load coverage and show multiple samples
along chrY with sequence classes (tutor's Phase 2 core features). 
 1. Typer skeleton for `ycov prepare`. [x]
 2. validate/: validate each file and output dir path. [x]
 3. coverage/ reader: list[Sample] from validate/ -> one long polars table
    (sample_id, chrom, start, end, depth), column names in models.py (FR3).
    One reader for 4-column coverage (mosdepth .regions.bed.gz and bedGraph,
    bedGraph track/browser/# header lines skipped). Input is precomputed
    coverage (mosdepth --by 1000 run by hand or simulate.py output).
    Steps per sample: parse with fixed types (polars parse error ->
    YcovInputError naming the file), Y/19 -> chrY/chr19, keep only chrY and
    chr19-22 (baseline in Week 5-6), check the contents: chrY present,
    chr19-22 present, 1 kb windows (last window per chromosome may be
    shorter), chrY ends at 62 460 029 (CHM13, catches GRCh38 input),
    depth >= 0 (subset of FR1-FR9). Then add sample_id and concat all samples.
    bedGraph only on the 1 kb grid; variable-length intervals give a clear
    error, re-binning them is Phase 3. [x]
 4. windows/: 1 kb grid, gap windows, annotate sequence class (midpoint rule
    as in simulate.py, a polars join, bioframe only if needed, it works on
    pandas);
    `reliable` = not gap and not PAR - PAR status hard-coded for the bundled
    CHM13 (answered in Week 1) (subset of FR10-FR14, FR26). [x]
 5. Write tests for validate/, coverage/ and windows/. [x]

## Week 4-5 (9 - 21 Nov): Normalisation, project folder
 1. Baseline (autosomal median) and relative copy = depth / baseline, as in
    software_specification.docx (subset of FR19-FR25). PAR windows are
    marked, not normalised (FR27). [x]
 2. project/: write and read manifest.json and windows/coverage parquet;
    annotations referenced from the package, logging to stderr (FR16). [x]
 3. Finish `ycov prepare` Typer command with plain progress output. [x]
 4. Tests against truth.tsv: simulated AZFc deletion gives relative copy ~0
    in AZFc, mLOY ~0.5 on chrY, female ~0 on chrY, normal male ~1. [x]
 5. Run on the real 1KGP subset. Write down runtime per sample (NFR5). [x]
 -> M1: `ycov prepare` produces a valid project for real and simulated data.

## Week 6 (17 Nov - 24 Nov): Prototype viewer
 1. server/: FastAPI app with GET /api/project, /api/coverage with parameters,
    /api/windows, /api/samples;
    pydantic models; unit and endpoint tests; listens on 127.0.0.1 only
    (NFR1, NFR2). [x]
 2. `ycov view`: start uvicorn, serve the built frontend, open the browser,
    one clear error if the project is not found (FR31). [x]
 3. web/: Vite + React + TypeScript + plotly.js scaffold, plain fetch. [x]
 4. Frontend prototype with components, packages, dependencies, design tokens, fonts, sizes, in the order of frontend/frontend_prototype.md. [x]
 -> M2: first prototype loads a project and shows coverage of multiple samples along chrY with sequence classes.

## Week 7 (24 Nov - 6 Dec): Test, release v0.1.0, demo
 1. Run the whole flow on all real + simulated samples, fix bugs. [x]
 2. First performance numbers: prepare time per sample, overview load time
    (NFR3, NFR5) - they go into the thesis. [x]
   First load, 100 samples (VM, 4 cores, 6 GB): Chrome 2.5 s (slowest of 13 runs 3.1 s), Firefox 2.2 s (slowest 2.4 s) (NFR3 ≤ 3 s). Pan update ≤ 0.35 s in Chrome (NFR4 ≤ 1 s). ycov prepare about 0.13 s per sample from mosdepth files (NFR5 ≤ 10 min, mosdepth itself not included).
 3. CI: pytest + coverage report, ruff (mypy optional). [x]
 4. README: install, building the frontend (npm run build), `ycov prepare`
    and `ycov view` on example_data. [ ]
 5. Tag v0.1.0 on GitHub. [ ]
 6. Screenshots of the prototype. [ ]
 -> M3

## Week 8 (7 Dec - 13 Dec): Buffer and handover to Phase 3
 1. Update requirements.md and whole project documentation: what is done, what moves to Phase 3. [ ]

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
