===============================================================================
 BACHELOR THESIS - STEP-BY-STEP WORK PLAN AND DELIVERABLES
 Visualizing Y Chromosome Coverage Across Individuals
 Created: 27 Sep 2026
===============================================================================

===============================================================================
 SEMESTER 1 (AUTUMN)
===============================================================================

-------------------------------------------------------------------------------
 PHASE 1 - BACKGROUND AND PROJECT DESIGN            (late Sep - end of Oct)
-------------------------------------------------------------------------------

## Learn the minimum biology
 1. Read Genetics of the human Y chromosome and its association with male infertility
 2. Read the Illumina page on sequencing coverage.
    -> Understand: read, depth, coverage, why coverage varies.
 3. Read Sequencing depth and coverage: key considerations in genomic analyses
 4. Read Skaletsky et al. 2003 (Nature, "mosaic of discrete sequence
    classes"): abstract, figures, and the sections on the sequence classes
    and palindromes.
    -> Understand: PAR, X-transposed, X-degenerate, ampliconic,
       palindromes P1-P8, heterochromatin.
 5. Read Rhie et al. 2023 (Nature, "complete sequence of a human Y"):
    abstract, Fig. 1, and the parts on what GRCh38 was missing and on
    short-read mapping.
    -> Understand: GRCh38 vs T2T-CHM13v2.0, why ampliconic regions are hard.
 6. Read Sequencing depth and coverage: key considerations in genomic analyses
 7. Start a terms.docx file and add every new term (read, BAM, CRAM, MAPQ,
    depth, BED, bedGraph, bigWig, reference build, PAR, XDR, XTR, AMPL,
    mLOY, AZF...).
 8. For every paper you read, write 3-5 sentences of notes plus the full
    citation into literature_review.docs

## Review existing tools
 1. Try IGV, the UCSC Genome Browser and samtools on your data. [x]
 2. For each tool, write down what it does well and what is missing for [x]
    "multi-sample Y integrity". That list is your motivation and gives you
    requirements for your own tool. [x]
 3. Take screenshots of each tool for the literature review. [x]

## Specification and design
 1. Write actors, initial functional and non-functional requirements into requirements.md. [x]
 2. Create Use Case diagram into use_case_diagram.plantuml based on requirements.md. [x]
 3. Specify inputs [x], outputs [x], processing pipeline [x] and UI views [x] into software_specification.docx.
 4. Specify architecture overview [x], tech stack [x], main components [x], initial repo structure [x], data design [x], API draft [x] into /visualisation/software_design.docx folder.

## Ask Mariateresa
  1. Review and feedback. [x]
  2. Wether it is okay to use igv.js. [x]
  3. Ask about reference build and normalization. [x]

## Repo
 1. Create GitHub repo. [x]
 2. Initial commit with basic repo structure. [x]
 3. Add README.md. and CI pipleine. [x]
 4. Create pyproject. [x]
 5. Test pipeline. [x]
 6. Set up Ubuntu with all libraries and tools. [x]

## PHASE 1 DELIVERABLES
 [D1] Short literature review (about 3-6 pages): Y chromosome structure and
      sequence classes, sequencing coverage, mapping problems on chrY,
      GRCh38 vs T2T, existing visualization tools and their gaps.
 [D2] Specification: inputs, outputs, processing steps, desired
      visualizations (the finished version of the spec doc).
 [D3] Initial software design: architecture diagram, UI wireframes, API
      draft, repository skeleton on GitHub.
