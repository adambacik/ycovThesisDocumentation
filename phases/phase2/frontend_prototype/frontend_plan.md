# Frontend plan – Phase 2, Week 6, step 4: prototype viewer page

Created: 20 Nov 2026
Repository: `code/ycov/web/`
Main source of the look: [`ui_mockup.html`](ui_mockup.html) (same file as `phase1/software/ui_mockup.html`)
Specification: `phase1/software/requirements.md`, `software_specification.docx`, `software_design.docx`

---

## 1. Goal and scope

One page (`/`, no router) that looks like the mockup and is split into the same
**6 containers**. All 6 are built and placed now. Only the functions needed for
"coverage of many samples along chrY with sequence classes" (milestone M2) work;
every other control is **rendered but disabled**, so the layout is final and
Phase 3 only connects the controls.

| # | Container (mockup lines) | Content in this step | Works | Disabled / empty |
|---|---|---|---|---|
| 1 | Top bar (`ui_mockup.html:217-250`) | `ycov` logo, Project = folder name, Reference, Reads switch, Normalisation select, Export dropdown | logo, project, reference | Reads switch, Normalisation select, Export dropdown |
| 2 | Navigation bar (`:252-263`) | Region input + Go, Class select, zoom −/+, move ←/→, Reset, "x Mb in view" | "x Mb in view" text, region input shows the current view (read-only) | input, Go, Class select, zoom, move, Reset |
| 3 | Chromosome overview (`:265-268`) | whole chrY: Mb axis, region lanes (PAR1/2, AZFa/b/c), coloured sequence-class bar, **red viewport slider** | slider: drag to move, drag edges to resize, click to centre | – |
| 4 | Sample sidebar (`:270-290`) | list of all samples | list | search / sort / group / filters left out for now |
| 5 | Sample tracks (`:292-303`) | sticky header "Region in view" (axis + class band of the view), one row per sample with a Plotly.js coverage graph | x-range follows the slider, grey shapes over gap/PAR (FR59 simplified) | – |
| 6 | Cohort bar (`:305-311`) | empty pane | – | buttons come in Phase 3 |

Left out on purpose in this step: PAR-masking info in the top bar, "Mark low-reliability"
checkbox, heatmap strip and ideogram per row, Reads/Coverage/Flags buttons per row,
gene ticks, cohort window, legend, tooltip element, toast.

### Mapping to `phase2_plan.md` Week 6

| Week 6 item | Where in this plan |
|---|---|
| 3. Vite + React + TS + plotly.js scaffold, plain fetch | already done; finished in Steps 1-5 (Tailwind, shadcn/ui, structure, state) |
| 4a. heatmap samples × windows | **not on this page** – the agreed layout shows coverage lines per sample. Moves to Phase 3 as a per-row heatmap strip (mockup `drawTrack`) or stays as a separate view – decide with tutor |
| 4b. sequence-class bar, colour-blind safe | Steps 9 and 11 (overview + track header), Okabe-Ito palette from the mockup |
| 4c. detail view, one line per sample | Step 12; region is picked with the overview slider, the region dropdown (Class select) is rendered disabled |
| 4d. raw / relative copy toggle | Normalisation select rendered disabled, value `rel_copy` |
| 5. grey shapes over gap and PAR | Step 12 |

Changes against `phase2_plan.md` "Left for Phase 3": **shadcn/ui and Tailwind move
into Phase 2** (wanted now, so the shared components exist before the page grows).
TanStack Query and generated API types stay in Phase 3, data is still loaded with
the existing plain-fetch client.

---

## 2. Technical decisions

| Topic | Decision | Reason |
|---|---|---|
| Styling | **Tailwind CSS v4** with `@tailwindcss/vite`, CSS-first config (`@theme` in one CSS file, no `tailwind.config.js`) | design doc; v4 needs no JS config, tokens live in CSS |
| Components | **shadcn/ui** (copied into `src/components/ui/`, Radix primitives, `class-variance-authority`) | design doc; accessible dropdowns/selects, we own and restyle the code |
| Icons | `lucide-react` (shadcn default) | chevrons, arrows, minus/plus |
| Design tokens | one file `src/styles/globals.css`: CSS custom properties on `:root`, exposed to Tailwind with `@theme inline` | single source of colours, fonts, sizes; readable from Plotly via `getComputedStyle` |
| Token colour format | **hex / rgb only**, never `oklch` (shadcn init writes `oklch` – replace it) | Plotly.js cannot parse `oklch()` |
| Server data | loaded once at start (project, samples, windows, coverage of the whole chrY at 10 kb) and provided read-only through a React context | data never changes while the page is open; the slider only changes the x-range, so no refetch while dragging |
| UI state | **zustand** store for the view range (`state/viewStore.ts`) | design doc; components subscribe to one field, a slider drag does not re-render the whole tree |
| Plotly | **own thin wrapper** `PlotlyChart` over `plotly.js-dist-min` (`Plotly.react` / `Plotly.purge`), remove `react-plotly.js` | design doc ("mounted manually"); full control over updates and cleanup, no extra class-component wrapper |
| Overview + track header | **SVG rendered by React** (percent coordinates), not canvas and not Plotly | ~30 intervals, crisp, styleable with Tailwind token classes, no resize code for bars |
| Coordinates | 0-based half-open `[start, end)` everywhere in code (like BED and the API); 1-based only in text shown to the user | same convention as the backend |
| Lint / format | ESLint (typescript-eslint, react-hooks) + Prettier with `prettier-plugin-tailwindcss` | consistent style and sorted class lists |
| Tests | Vitest for pure functions in `src/lib/` | design doc; Playwright stays in Phase 3 |

Data size check: whole chrY at 10 kb = 6 246 bins per sample; 21 samples ≈ 130 k
numbers (≈ 1 MB JSON), 100 samples ≈ 5 MB – fine for one request on localhost (NFR3).

---

## 3. Target layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ 1 TopBar   ycov  Project demo  Reference T2T-CHM13v2.0  Reads[All|MAPQ≥20]    │
│            Normalisation[Relative copy ▾]                          [Export ▾] │
├──────────────────────────────────────────────────────────────────────────────┤
│ 2 NavBar   Region [chrY:2,458,321-27,020,249] [Go]  Class[Jump to… ▾]         │
│            [−|+] [←|→] [Reset]                                24.56 Mb in view │
├──────────────────────────────────────────────────────────────────────────────┤
│ 3 ChromosomeOverview   chrY overview                                         │
│   ▀▀PAR1▀  ▀▀AZFa▀▀  ▀▀▀▀AZFb▀▀▀▀▀▀              (region lanes)               │
│                           ▀▀▀AZFc▀▀▀                                          │
│   ████▓▓▓▓████▒▒▒█┏━━━━━━━━━━━┓████████████████████████████████████████       │
│                   ┗━━━━━━━━━━━┛ ← red viewport slider                         │
│   0     5 Mb    10 Mb    15 Mb  ...                              60 Mb        │
├──────────────┬───────────────────────────────────────────────────────────────┤
│ 4 Sample     │ 5 TrackPanel                                                  │
│   Sidebar    │ ┌ Sample ───────┬ Region in view ─────────────── window 10 kb ┐│
│ Samples (11) │ │               │ 5 Mb      10 Mb      15 Mb      20 Mb       ││ sticky
│ S01   30.1×  │ │               │ ███XDR████▓AMPL▓███XDR███▒P5▒███            ││
│ S02   29.8×  │ ├───────────────┼──────────────────────────────────────────────┤│
│ S03   30.4×  │ │ S01  30.1×    │ 2 ┤   coverage line (Plotly)                ││
│ …            │ │               │ 1 ┤~~~~~~~~~~~~~░░~~~~~~~~~~~~~~~~          ││
│              │ │               │ 0 ┤             ░░ (grey = gap / PAR)       ││
│              │ ├───────────────┼──────────────────────────────────────────────┤│
│              │ │ S02  29.8×    │ …                                           ││
│ (scrolls)    │ └───────────────┴──────────────────────────────────────────────┘│
│              │                         (scrolls vertically)                  │
├──────────────┴───────────────────────────────────────────────────────────────┤
│ 6 CohortBar   (empty for now)                                                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

CSS grid as in the mockup (`.app`, `ui_mockup.html:40`):
2 columns `sidebar-width | minmax(0,1fr)`, 5 rows `auto auto auto minmax(0,1fr) auto`,
gap 6 px, padding 6 px 16 px, whole window height (`h-dvh`). Containers 1, 2, 3, 6
span both columns. Only the sidebar list and the track panel scroll.
Below 980 px everything stacks in one column (mockup `@media (max-width:980px)`).

---

## 4. Folder structure

The design doc puts UI components in `web/src/components/` (there is no `web/components/`
folder; everything lives under `src/`). Folders are grouped by container; parts used by
more than one container go to `genome/` or `common/`.

```
web/
├── components.json              shadcn/ui config (aliases, css file, style)
├── eslint.config.js
├── .prettierrc.json
├── index.html
├── package.json
├── tsconfig.json                + "paths": { "@/*": ["./src/*"] }
├── vite.config.ts               + tailwindcss(), "@" alias, vitest config
└── src/
    ├── main.tsx                 mounts <App/>, imports styles/globals.css
    ├── App.tsx                  loads data, loading/error gate, providers, <AppLayout/>
    │
    ├── styles/
    │   └── globals.css          THE shared CSS file: Tailwind import, design tokens, base layer
    │
    ├── api/                     (exists) plain fetch client + hand-written types
    │   ├── client.ts
    │   └── types.ts             + ProjectInfo.name
    │
    ├── state/
    │   ├── projectData.tsx      ProjectDataProvider + useProjectData() (read-only server data)
    │   └── viewStore.ts         zustand: bounds, view, initialise(), setView()
    │
    ├── hooks/
    │   ├── useProjectLoader.ts  fetches everything once (AbortController), returns Load union
    │   ├── useElementWidth.ts   ResizeObserver → width in px (axis tick density, label fit)
    │   └── useInView.ts         IntersectionObserver → mount Plotly only for visible rows
    │
    ├── lib/                     pure TypeScript, no React, unit-tested
    │   ├── utils.ts             cn() (generated by shadcn)
    │   ├── constants.ts         COVERAGE_RESOLUTION, MIN_VIEW_SPAN, REL_COPY_RANGE, PLOT_MARGIN
    │   ├── genome.ts            GenomeRange type, toPercent, clipToRange, assignLanes, initialView
    │   ├── viewRange.ts         clampView, moveView, resizeViewStart/End, centreViewOn
    │   ├── ticks.ts             niceStep, axisTicks, formatTick
    │   ├── format.ts            formatBp, formatPosition, formatRegionLabel, formatDepth
    │   ├── sequenceClasses.ts   data class name → group, label, Tailwind token classes
    │   ├── theme.ts             readToken(): CSS token → colour string for Plotly
    │   ├── plotly.ts            Plotly import, base layout and config shared by all plots
    │   └── *.test.ts            Vitest tests next to the file they test
    │
    ├── types/
    │   └── plotly-dist-min.d.ts maps "plotly.js-dist-min" to the @types/plotly.js types
    │
    └── components/
        ├── ui/                  shadcn/ui, generated then restyled (kebab-case file names)
        │   ├── button.tsx
        │   ├── button-group.tsx
        │   ├── input.tsx
        │   ├── label.tsx
        │   ├── select.tsx
        │   ├── toggle.tsx
        │   ├── toggle-group.tsx
        │   └── dropdown-menu.tsx
        │
        ├── common/              own shared, domain-free components
        │   ├── Pane.tsx         white bordered container used by all 6 areas
        │   ├── LabeledValue.tsx "Project demo" – muted key + value
        │   ├── StatusMessage.tsx loading / error message
        │   └── PlotlyChart.tsx  thin Plotly wrapper (react, resize, purge)
        │
        ├── genome/              shared genome drawing, used by overview and track header
        │   ├── GenomeAxis.tsx
        │   ├── SequenceClassBar.tsx
        │   └── RegionLanes.tsx
        │
        ├── layout/
        │   └── AppLayout.tsx    the 6-area grid
        │
        ├── top-bar/
        │   ├── TopBar.tsx
        │   ├── ProjectSummary.tsx
        │   ├── ReadsToggle.tsx
        │   ├── NormalisationSelect.tsx
        │   └── ExportMenu.tsx
        │
        ├── nav-bar/
        │   ├── NavBar.tsx
        │   ├── RegionInput.tsx
        │   ├── ClassSelect.tsx
        │   ├── ViewControls.tsx zoom −/+, move ←/→, Reset
        │   └── ViewSpan.tsx     "24.56 Mb in view"
        │
        ├── overview/
        │   ├── ChromosomeOverview.tsx
        │   └── ViewportSlider.tsx
        │
        ├── sample-sidebar/
        │   ├── SampleSidebar.tsx
        │   └── SampleListItem.tsx
        │
        ├── tracks/
        │   ├── TrackPanel.tsx
        │   ├── TrackHeader.tsx
        │   ├── SampleTrackRow.tsx
        │   ├── SampleLabel.tsx
        │   └── CoveragePlot.tsx
        │
        └── cohort-bar/
            └── CohortBar.tsx
```

`App.css` is deleted; `.gitkeep` files in `components/` and `state/` are removed once
the folders have files.

---

## 5. Design system – `src/styles/globals.css`

### 5.1 Naming rules

- **Semantic names, not colour names.** `--muted-foreground`, not `--grey-600`.
  The mockup variable names are mapped to shadcn's naming so generated components
  work without renaming (table 5.3).
- Two families of tokens:
  1. **UI tokens** – shadcn convention: `--background`, `--foreground`, `--card`,
     `--muted`, `--border`, `--input`, `--ring`, `--secondary`, `--accent`, `--destructive`, …
     plus a few our own (`--secondary-hover`, `--accent-border`, `--tooltip`).
  2. **Domain tokens** – prefix by meaning: `--seq-*` (sequence classes),
     `--region*` (AZF/PAR lanes), `--viewport*` (red slider), `--coverage-*` (plot),
     `--masked` (gap/PAR shapes).
- Every colour token is defined once on `:root` and mapped once in `@theme inline`
  as `--color-<name>`, which creates `bg-<name>`, `text-<name>`, `border-<name>`,
  `fill-<name>`, `stroke-<name>`.
- Sizes are tokens too: font sizes (`--text-*`), control height, sidebar width,
  track label width, track row height, radius, shadows.
- **No hex values in `.tsx` files.** Components use token classes; Plotly reads the
  same tokens through `lib/theme.ts`.

### 5.2 The file

```css
/* Shared design tokens and base styles of the ycov viewer.
   Values come from ui_mockup.html; names follow shadcn/ui.
   Colours stay hex/rgb: Plotly.js reads them via getComputedStyle and cannot parse oklch. */

@import "tailwindcss";
@import "tw-animate-css"; /* used by shadcn dropdown / select animations */

/* ---------- 1. Colour tokens (runtime CSS variables) ---------- */
:root {
  color-scheme: light;

  /* surfaces and text */
  --background: #e8eaec;           /* app canvas behind the panes        (mockup --bg) */
  --foreground: #1d2125;           /* main text                          (--ink) */
  --card: #ffffff;                 /* pane background                    (--panel) */
  --card-foreground: #1d2125;
  --popover: #ffffff;              /* dropdown / select menus */
  --popover-foreground: #1d2125;
  --muted: #f4f5f6;                /* sticky header, row hover           (--panel-2) */
  --muted-foreground: #5f676e;     /* keys, secondary text, axis labels  (--muted) */

  /* lines and focus */
  --border: #cdd1d5;               /* pane and row separators            (--line) */
  --input: #aeb4ba;                /* control borders                    (--line-2) */
  --ring: #2f6fb3;                 /* focus outline                      (--focus) */

  /* controls */
  --primary: #2f6fb3;              /* rare emphasis, checked states */
  --primary-foreground: #ffffff;
  --secondary: #f4f5f7;            /* default button                     (--btn) */
  --secondary-hover: #e9ecef;      /*                                    (--btn-hover) */
  --secondary-foreground: #1d2125;
  --accent: #d9e3ee;               /* pressed button, menu item hover    (--btn-on) */
  --accent-border: #8099b3;        /*                                    (--btn-on-line) */
  --accent-foreground: #1d2125;
  --destructive: #c8501e;          /* invalid input, errors              (--loss) */
  --tooltip: #ffffe8;              /* Plotly hover label                 (.tip) */

  /* sequence classes – Okabe-Ito, colour-blind safe (NFR12) */
  --seq-par: #cc79a7;
  --seq-xtr: #e69f00;
  --seq-xdr: #009e73;
  --seq-ampl: #56b4e9;
  --seq-pal: #7a5195;              /* palindromes P1-P8, not in the bundled BED yet */
  --seq-het: #8a8f8c;              /* HET, CEN, SAT, DYZ* */
  --seq-other: #c4c9cd;            /* OTHER and unknown names */

  /* named regions (AZFa/b/c, PAR1/2) */
  --region: #5f676e;
  --region-foreground: #ffffff;

  /* region in view (red slider) */
  --viewport: #d7263d;             /*                                    (--vp) */
  --viewport-fill: rgb(215 38 61 / 0.12);

  /* coverage plot */
  --coverage-line: #1d2125;
  --coverage-fill: rgb(29 33 37 / 0.13);
  --coverage-reference: #aeb4ba;   /* dotted line at 1 copy */
  --masked: rgb(95 103 110 / 0.16);/* gap and PAR shapes (FR59, simplified) */

  /* heatmap scale, reserved for Phase 3 (--loss / --normal / --gain) */
  --coverage-loss: #c8501e;
  --coverage-normal: #e2e6e1;
  --coverage-gain: #2f5f9e;
}

/* ---------- 2. Tokens → Tailwind utilities ---------- */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-hover: var(--secondary-hover);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-accent: var(--accent);
  --color-accent-border: var(--accent-border);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-tooltip: var(--tooltip);

  --color-seq-par: var(--seq-par);
  --color-seq-xtr: var(--seq-xtr);
  --color-seq-xdr: var(--seq-xdr);
  --color-seq-ampl: var(--seq-ampl);
  --color-seq-pal: var(--seq-pal);
  --color-seq-het: var(--seq-het);
  --color-seq-other: var(--seq-other);

  --color-region: var(--region);
  --color-region-foreground: var(--region-foreground);
  --color-viewport: var(--viewport);
  --color-viewport-fill: var(--viewport-fill);
  --color-masked: var(--masked);
}

/* ---------- 3. Fonts, sizes, layout (static theme values) ---------- */
@theme {
  /* system fonts only: works offline, nothing downloaded (NFR1, NFR21) */
  --font-sans: "Segoe UI", system-ui, -apple-system, Roboto, Arial, sans-serif;
  --font-mono: Consolas, Menlo, "DejaVu Sans Mono", monospace;

  /* font sizes: Tailwind's default scale removed, only these exist */
  --text-*: initial;
  --text-caption: 0.6875rem;          /* 11 px  axis ticks, lane labels */
  --text-caption--line-height: 1.3;
  --text-small: 0.75rem;              /* 12 px  secondary info, small buttons, coordinates */
  --text-small--line-height: 1.35;
  --text-body: 0.8125rem;             /* 13 px  default UI text, controls */
  --text-body--line-height: 1.4;
  --text-title: 0.875rem;             /* 14 px  dialog titles (Phase 3) */
  --text-title--line-height: 1.4;
  --text-brand: 0.9375rem;            /* 15 px  "ycov" logo */
  --text-brand--line-height: 1.2;

  /* named sizes → h-control, w-sidebar, h-track-row, … */
  --spacing-control: 1.625rem;        /* 26 px  height of buttons, inputs, selects */
  --spacing-sidebar: 15rem;           /* 240 px sample sidebar column */
  --spacing-track-label: 13.125rem;   /* 210 px sample label column in the track panel */
  --spacing-track-row: 7.5rem;        /* 120 px one sample row (Plotly fills it) */

  --radius-sm: 2px;                   /* controls and panes (mockup radius) */
  --radius-md: 2px;
  --radius-lg: 3px;

  --shadow-menu: 0 3px 8px rgb(0 0 0 / 0.15);
  --inset-shadow-pressed: inset 0 1px 2px rgb(0 0 0 / 0.12);

  --breakpoint-desktop: 61.25rem;     /* 980 px: two-column layout from here (desktop:) */
}

/* ---------- 4. Base layer ---------- */
@layer base {
  html,
  body,
  #root {
    height: 100%;
  }
  body {
    @apply bg-background font-sans text-body text-foreground antialiased;
  }
  *,
  ::before,
  ::after {
    border-color: var(--border);
  }
  :focus-visible {
    outline: 2px solid var(--ring);
    outline-offset: 1px;
  }
}
```

### 5.3 Mockup → token mapping

| Mockup variable | Token | Tailwind classes |
|---|---|---|
| `--bg` | `--background` | `bg-background` |
| `--panel` | `--card` | `bg-card` |
| `--panel-2` | `--muted` | `bg-muted` |
| `--line` / `--line-2` | `--border` / `--input` | `border-border` / `border-input` |
| `--ink` / `--muted` | `--foreground` / `--muted-foreground` | `text-foreground` / `text-muted-foreground` |
| `--focus` | `--ring` | global `:focus-visible` |
| `--btn`, `--btn-hover`, `--btn-on`, `--btn-on-line` | `--secondary`, `--secondary-hover`, `--accent`, `--accent-border` | button variants |
| `--loss` | `--destructive`, `--coverage-loss` | `border-destructive` |
| `--c-par … --c-het` | `--seq-par … --seq-het` | `fill-seq-xdr`, `bg-seq-xdr` |
| `--vp`, `--vp-fill` | `--viewport`, `--viewport-fill` | `border-viewport bg-viewport-fill` |
| `--f-ui`, `--f-mono` | `--font-sans`, `--font-mono` | `font-sans`, `font-mono` |
| 11 / 12 / 13 / 14 / 15 px | `--text-caption/small/body/title/brand` | `text-caption` … `text-brand` |
| `--labw` | `--spacing-track-label` | `w-track-label` |

### 5.4 Sequence classes (`lib/sequenceClasses.ts`)

The bundled `sequence_classes.bed` uses these names; they are grouped into the
mockup's 7 colours:

| Names in the data | Group | Label | Token |
|---|---|---|---|
| `PAR1`, `PAR2` | `par` | Pseudoautosomal | `seq-par` |
| `XTR1`, `XTR2` | `xtr` | X-transposed | `seq-xtr` |
| `X-DEG` | `xdr` | X-degenerate | `seq-xdr` |
| `AMPL` | `ampl` | Ampliconic | `seq-ampl` |
| `P1`-`P8` (future) | `pal` | Palindrome | `seq-pal` |
| `HET`, `CEN`, `SAT`, `DYZ17`, `DYZ19` | `het` | Heterochromatin / satellite | `seq-het` |
| `OTHER`, anything unknown | `other` | Other | `seq-other` |

Tailwind only generates classes it finds as **complete strings in the source**, so the
map stores full class names, never builds them (`` `fill-seq-${g}` `` would not work):

```ts
export type SequenceClassGroup = "par" | "xtr" | "xdr" | "ampl" | "pal" | "het" | "other";

interface GroupStyle {
  label: string;
  fillClass: string; // SVG
  bgClass: string;   // HTML (legend in Phase 3)
}

export const SEQUENCE_CLASS_GROUPS: Record<SequenceClassGroup, GroupStyle> = {
  par: { label: "Pseudoautosomal", fillClass: "fill-seq-par", bgClass: "bg-seq-par" },
  xtr: { label: "X-transposed", fillClass: "fill-seq-xtr", bgClass: "bg-seq-xtr" },
  // …
};

const GROUP_OF_NAME: Record<string, SequenceClassGroup> = {
  PAR1: "par", PAR2: "par", XTR1: "xtr", XTR2: "xtr", "X-DEG": "xdr", AMPL: "ampl",
  HET: "het", CEN: "het", SAT: "het", DYZ17: "het", DYZ19: "het", OTHER: "other",
};

/** Group of a class name from /api/windows; P1-P8 → "pal", unknown → "other". */
export function sequenceClassGroup(name: string): SequenceClassGroup { … }
```

---

## 6. Shared UI components (shadcn/ui)

Generated once with the shadcn CLI into `src/components/ui/`, then **restyled to the
mockup** (they are our code from then on). After each `shadcn add`: replace Tailwind
default text classes (`text-sm`, `text-xs`) with ours (`text-body`, `text-small`) –
the default scale is removed, so a leftover class simply has no effect and is easy to
spot – and set heights to `h-control`.

| Component | Used by | Mockup look |
|---|---|---|
| `Button` | Go, zoom, move, Reset, Export trigger | grey, 1 px `border-input`, radius 2 px |
| `ButtonGroup` | −/+ and ←/→ pairs | joined buttons (`.seg`) |
| `Toggle`, `ToggleGroup` | Reads `All | MAPQ ≥ 20` | segmented, pressed = `bg-accent` + inset shadow |
| `Input` | Region | white, mono font, `border-input` |
| `Label` | "Normalisation", "Class", "Region" | muted key text |
| `Select` | Normalisation, Class | native-select look, white |
| `DropdownMenu` | Export | white menu, `shadow-menu`, items hover `bg-accent` |

Button – one definition of all button looks for the whole app:

```tsx
const buttonVariants = cva(
  "inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-sm border " +
    "font-sans text-body text-foreground transition-colors select-none " +
    "disabled:pointer-events-none disabled:opacity-50 [&_svg]:size-3.5 [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default:
          "border-input bg-secondary hover:bg-secondary-hover " +
          "aria-pressed:border-accent-border aria-pressed:bg-accent aria-pressed:inset-shadow-pressed",
        ghost: "border-transparent bg-transparent hover:bg-accent",
      },
      size: {
        default: "h-control px-2.5",
        sm: "h-5 px-1.5 text-small",
        icon: "size-control font-semibold",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  },
);
```

Rules:
- Every clickable element is a `Button` (or a shadcn primitive built on it); no bare
  `<button className=…>` in feature components.
- New looks become a new `variant`/`size`, not ad-hoc classes at the call site.
  `className` at the call site is only for layout (`ml-auto`, `w-65`).
- Disabled controls get `disabled` **and** a `title` on a wrapper `<span>` saying
  "Available in a later version" (disabled buttons do not fire pointer events, so the
  title must sit on the wrapper).

---

## 7. State and data flow

```
App
 └─ useProjectLoader()                       hooks/useProjectLoader.ts
      Promise.all([getProject, getSamples, getWindows,
                   getCoverage({ resolution: COVERAGE_RESOLUTION })])   // 10 kb, whole chrY
      on success: useViewStore.getState().initialise(bounds, initialView(annotations))
                  then setLoad({ status: "ready", data })
      ├─ loading → <StatusMessage>Loading project…</StatusMessage>
      ├─ error   → <StatusMessage tone="error">Could not load the project: …</StatusMessage>
      └─ ready   → <ProjectDataProvider value={data}>    read-only, never changes
                     <AppLayout/>                        6 containers
                       read data:  useProjectData()
                       read view:  useViewStore((s) => s.view)
                       change view: useViewStore((s) => s.setView)   (ViewportSlider only, for now)
```

**Server data** – `state/projectData.tsx`:

```tsx
export interface ProjectData {
  project: ProjectInfo;
  samples: SampleInfo[];
  annotations: WindowAnnotations;
  coverage: Coverage;
  /** sample id → its row of coverage.values, built once */
  coverageRows: ReadonlyMap<string, (number | null)[]>;
}

const ProjectDataContext = createContext<ProjectData | null>(null);

export function ProjectDataProvider({ value, children }: { value: ProjectData; children: ReactNode }) {
  return <ProjectDataContext value={value}>{children}</ProjectDataContext>; // React 19 syntax
}

/** The loaded project; only valid below ProjectDataProvider. */
export function useProjectData(): ProjectData {
  const data = useContext(ProjectDataContext);
  if (data === null) throw new Error("useProjectData() used outside <ProjectDataProvider>");
  return data;
}
```

**UI state** – `state/viewStore.ts`:

```ts
interface ViewState {
  /** whole chromosome [0, length) */
  bounds: GenomeRange;
  /** region in view, always inside bounds and at least MIN_VIEW_SPAN long */
  view: GenomeRange;
  initialise: (bounds: GenomeRange, view: GenomeRange) => void;
  /** clamps into bounds; the only way to change the view */
  setView: (view: GenomeRange) => void;
}

export const useViewStore = create<ViewState>()((set, get) => ({
  bounds: { start: 0, end: 1 },
  view: { start: 0, end: 1 },
  initialise: (bounds, view) => set({ bounds, view: clampView(view, bounds, MIN_VIEW_SPAN) }),
  setView: (view) => set({ view: clampView(view, get().bounds, MIN_VIEW_SPAN) }),
}));
```

The store is initialised **before** the ready state is rendered, so no component ever
sees the placeholder range. Components select one field
(`useViewStore((s) => s.view)`), never the whole store.

**Constants** – `lib/constants.ts`:

| Name | Value | Meaning |
|---|---|---|
| `COVERAGE_RESOLUTION` | `10_000` | bin size of the one coverage request (FR15 second resolution) |
| `MIN_VIEW_SPAN` | `100_000` | smallest view = 10 bins; finer zoom needs 1 kb data (Phase 3) |
| `REL_COPY_RANGE` | `[0, 2.2]` | fixed y-range of all plots, so samples are comparable (mockup `ymax`) |
| `PLOT_MARGIN` | `{ left: 40, right: 12, top: 6, bottom: 6 }` | Plotly margins; the track header uses the same left/right padding so its axis lines up with the plots |

`initialView(annotations)`: from the end of PAR1 to the end of AZFc (mockup default
`2.5-27 Mb`, the male-specific euchromatin), taken from `annotations.regions`;
whole chromosome if those regions are missing.

---

## 8. Container specifications

### 8.1 `layout/AppLayout.tsx`

```tsx
<div className="grid h-full grid-cols-1 gap-1.5 px-4 py-1.5
                desktop:grid-cols-[var(--spacing-sidebar)_minmax(0,1fr)]
                desktop:grid-rows-[auto_auto_auto_minmax(0,1fr)_auto]">
  <TopBar />              {/* col-span-full */}
  <NavBar />              {/* col-span-full */}
  <ChromosomeOverview />  {/* col-span-full */}
  <SampleSidebar />
  <TrackPanel />
  <CohortBar />           {/* col-span-full */}
</div>
```

Every container is a `Pane` with a landmark element and `aria-label`, as in the mockup:
`header` (top bar), `nav`, `section` (overview), `aside` (samples), `main` (tracks),
`footer` (cohort).

`common/Pane.tsx`: `as` prop for the element, base classes
`min-w-0 rounded-sm border border-border bg-card`, `className` merged with `cn()`.

### 8.2 Container 1 – `top-bar/`

| Component | Content | State |
|---|---|---|
| `TopBar` | flex row, `gap-4.5 px-2.5 py-1.5 whitespace-nowrap`, wraps below 1100 px | – |
| logo | `<span className="text-brand font-bold">ycov</span>`, `title="ycov v{project.ycov_version}"` | works |
| `ProjectSummary` | `LabeledValue` "Project" `project.name`, "Reference" `project.reference` | works |
| `ReadsToggle` | key "Reads" + `ToggleGroup type="single"` items `all` "All", `mapq` "MAPQ ≥ 20" | disabled, value `all` |
| `NormalisationSelect` | `Label` "Normalisation" + `Select` with "Relative copy (autosomal baseline)", "Y-internal (sample XDR median)", "Cohort median", "Raw depth" | disabled, value `rel_copy` |
| `ExportMenu` | `ml-auto`; `DropdownMenu`, trigger `Button` "Export" + `ChevronDown`; items Figure PNG/SVG/PDF, separator, Summary CSV/TSV, Flag list CSV, Flagged regions BED | trigger disabled |

Disabled components already take their final props (`value`, `onValueChange`,
`disabled`), so Phase 3 only passes a handler and removes `disabled`.

`project.name` needs a small backend change (Step 0): `/api/project` has no folder name yet.

### 8.3 Container 2 – `nav-bar/`

| Component | Content | State |
|---|---|---|
| `NavBar` | flex row, wrap, `gap-x-3.5 gap-y-1.5 px-2.5 py-1.5` | – |
| `RegionInput` | `<form>`: `Label` "Region", `Input` (mono, `w-65`, placeholder `chrY:start-end, gene or AZFc`), `Button` "Go" | input `disabled readOnly` with value `formatRegionLabel(view)` → shows the slider's region live; Go disabled |
| `ClassSelect` | `Label` "Class" + `Select` "Jump to…", groups per class and "Named regions" from `annotations` | disabled |
| `ViewControls` | `ButtonGroup` [−][+] (`Minus`, `Plus`), `ButtonGroup` [←][→], `Button` "Reset" | all disabled |
| `ViewSpan` | `ml-auto font-mono text-small text-muted-foreground`: `formatBp(view.end - view.start)` + " in view" | works |

### 8.4 Container 3 – `overview/` + `genome/`

`ChromosomeOverview` (`px-2.5 pt-1.5 pb-1.5`): heading "chrY overview", then a
`relative select-none touch-none` box (the "ruler") containing one SVG and the slider:

```
y  0-21   RegionLanes        lanes of 9 px (assignLanes → 2 lanes: AZFc overlaps AZFb)
y 24-42   SequenceClassBar   18 px, domain = bounds
y 44-70   GenomeAxis         line, minor tick every 1 Mb, label every 5 Mb (10 Mb if narrow)
overlay   ViewportSlider     absolute, over the class bar (top 21 px, height 24 px)
```

**Shared genome components** (`genome/`, all take `domain: GenomeRange`):

- `SequenceClassBar({ domain, intervals, height, showLabels })` – one `<rect>` per class
  interval clipped to the domain, `x`/`width` in **percent** of the domain
  (`toPercent`), class from `SEQUENCE_CLASS_GROUPS[...].fillClass`, `<title>` with name and
  1-based coordinates (native tooltip). With `showLabels`, a label is drawn centred when
  it fits (`useElementWidth` → px width of the interval vs. ~6.5 px per character),
  white or dark text by background.
- `RegionLanes({ domain, regions })` – `assignLanes(regions)` (greedy: first lane whose
  last end ≤ start), `fill-region` bars, label in `fill-region-foreground text-caption
  font-semibold` inside the bar or to the left when the bar is too short.
- `GenomeAxis({ domain })` – measures its width (`useElementWidth`), `axisTicks(domain,
  width / 95)` (mockup density), labels in `font-mono text-caption fill-muted-foreground`,
  first/last label clamped inside the edges.

**`ViewportSlider`** – the red box: `absolute rounded-[1px] border-[2.5px] border-viewport
bg-viewport-fill min-w-1.5 cursor-grab` with two 8 px handles (`cursor-ew-resize`)
sticking 5 px out on each side; `left`/`width` as inline percent styles from the view
(only computed geometry is inline, all colours are classes).

Drag technique (pointer events, works for mouse, pen and touch):

1. `pointerdown` on the ruler: decide the mode from the target – `resize-start`,
   `resize-end`, `move`; a press outside the box first centres the view on that
   position (`centreViewOn`) and then continues as `move`.
2. Store `{ mode, originX, originView, bpPerPx = boundsLength / rulerWidth }` in a `ref`
   (not state – no re-render per pointer event), `setPointerCapture(pointerId)`,
   `preventDefault()`.
3. `pointermove`: `deltaBp = (clientX - originX) * bpPerPx` →
   `moveView` / `resizeViewStart` / `resizeViewEnd` (pure functions, `lib/viewRange.ts`)
   → keep the result in a ref and call `setView` **at most once per animation frame**
   (`requestAnimationFrame`), so N Plotly plots relayout ≤ 60×/s.
4. `pointerup` / `pointercancel`: clear the ref, cancel a pending frame.
5. Always computed from `originView` + total delta (never incrementally), so the box
   does not drift; clamping to bounds and `MIN_VIEW_SPAN` happens in the pure functions.
6. Keyboard (small extra): the box is focusable (`tabIndex={0}`, `role="slider"`,
   `aria-label="Region in view"`, `aria-valuetext` = region label); ←/→ move by 10 % of
   the span, Shift+←/→ by 50 %.

### 8.5 Container 4 – `sample-sidebar/`

- `SampleSidebar` (`aside`, `flex min-h-0 flex-col overflow-hidden`): header row
  "**Samples** (n)" (`px-2.5 pt-1.5 pb-1`), then `<ul>` with `min-h-0 flex-1 overflow-auto
  border-t border-border`. Below 980 px `max-h-115` (mockup 460 px).
- `SampleListItem`: grid `minmax(0,1fr) auto`, `px-2.5 py-0.5 hover:bg-muted`;
  `sample_id` in `font-mono` (truncate), right side baseline `formatDepth(baseline)`
  ("30.1×", `font-mono text-small text-muted-foreground`, `title="Autosomal baseline depth
  (median chr19-22)"`).
- Order = manifest order from `/api/samples` (same order as the track rows).
- Search, sort, group, filters, checkboxes: Phase 3 (FR42-FR44). The header row
  already leaves space for the All / None / Invert buttons.

### 8.6 Container 5 – `tracks/`

`TrackPanel` (`main`, `flex min-h-0 flex-col overflow-hidden`) → scroll container
`relative min-h-0 flex-1 overflow-auto` → inner `min-w-190` (mockup `.tin`, 760 px):

- `TrackHeader` – `sticky top-0 z-10 bg-muted border-b border-input`, grid
  `grid-cols-[var(--spacing-track-label)_minmax(0,1fr)]` (the **same grid as the rows**):
  - cell 1: "Sample" (`px-2 py-1 font-semibold`)
  - cell 2: caption row "Region in view" + right `window {formatBp(coverage.resolution)}`
    (mono, muted), then a box with
    `style={{ paddingLeft: PLOT_MARGIN.left, paddingRight: PLOT_MARGIN.right }}` holding
    `GenomeAxis domain={view}` and `SequenceClassBar domain={view} showLabels height={15}`.
    Because the padding equals the Plotly margins and both live in the same column,
    the header axis lines up pixel-exactly with every plot below it.
- `SampleTrackRow` (one per sample, `key={sample_id}`): same grid, `h-track-row
  border-b border-border`:
  - `SampleLabel`: `sample_id` (`font-mono font-semibold`), muted "baseline 30.1×" and
    the input format (`text-small text-muted-foreground`).
  - plot cell: `useInView(ref, { rootMargin: "200px 0px" })`; `CoveragePlot` is mounted
    the first time the row comes near the viewport and stays mounted (cheap with tens of
    samples; virtualisation for 500 samples, NFR6, is Phase 3).
- No rows → "No samples in this project."

**`CoveragePlot({ sampleId, values })`** – builds Plotly input, renders `PlotlyChart`:

| Part | Setting |
|---|---|
| trace | `type: "scatter"` (SVG – WebGL contexts are limited to ~16 per page, one per row would run out), `x: coverage.starts`, `y: values`, `mode: "lines"`, `line: { shape: "hv", width: 1.2, color: --coverage-line }` (steps = bins), `fill: "tozeroy"`, `fillcolor: --coverage-fill`, `connectgaps: false` (null = gap/PAR stays empty) |
| hover | `hovertemplate: "chrY:%{x:,}<br>%{y:.2f} copy<extra>" + sampleId + "</extra>"`, `hoverlabel` bg `--tooltip`, mono font |
| x-axis | `range: [view.start, view.end]`, `showticklabels: false` (the header has the axis), `showgrid: false`, `zeroline: false`, `fixedrange: true` |
| y-axis | `range: REL_COPY_RANGE`, `tickvals: [0, 1, 2]`, mono 11 px muted ticks, `gridcolor: --border`, `fixedrange: true` |
| shapes | built once from `annotations.masked`: `type: "rect"`, `xref: "x"`, `yref: "paper"`, `y0: 0`, `y1: 1`, `fillcolor: --masked`, `line.width: 0`, `layer: "below"`; plus a dotted line at y = 1 (`--coverage-reference`) |
| layout | `margin: PLOT_MARGIN`, `autosize: true` (height from the CSS row height), transparent `paper_bgcolor` / `plot_bgcolor`, `showlegend: false`, `dragmode: false`, `hovermode: "x"` |
| config | `displayModeBar: false`, `responsive: true`, `scrollZoom: false`, `doubleClick: false` |

Memoisation: `data` and `shapes` with `useMemo` on the (never changing) inputs; `layout`
with `useMemo([view, shapes])`. On a slider drag only the layout object changes and
`Plotly.react` does a cheap relayout without redrawing the trace data.

**`common/PlotlyChart.tsx`** – the only place that touches the Plotly API:

```tsx
/** Mounts one Plotly figure into a div; updates with Plotly.react, cleans up on unmount. */
export function PlotlyChart({ data, layout, config, className }: PlotlyChartProps) {
  const ref = useRef<HTMLDivElement>(null);

  // draw and update: Plotly.react diffs against the previous figure
  useEffect(() => {
    const el = ref.current;
    if (el !== null) void Plotly.react(el, data, layout, config);
  }, [data, layout, config]);

  // follow container size changes (window, sidebar), free memory on unmount
  useEffect(() => {
    const el = ref.current;
    if (el === null) return;
    const observer = new ResizeObserver(() => void Plotly.Plots.resize(el));
    observer.observe(el);
    return () => {
      observer.disconnect();
      Plotly.purge(el);
    };
  }, []);

  return <div ref={ref} className={className} />;
}
```

`lib/theme.ts` – Plotly needs colour strings, read from the same CSS tokens:

```ts
/** Value of a CSS custom property on :root, e.g. readToken("--seq-xdr") → "#009e73". */
export function readToken(name: `--${string}`): string {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}
```

`lib/plotly.ts` exports `Plotly` (from `plotly.js-dist-min`), `BASE_CONFIG` and
`baseLayout()` (fonts from `--font-mono`, colours via `readToken`), so all plots share
one look; `types/plotly-dist-min.d.ts`:

```ts
declare module "plotly.js-dist-min" {
  import Plotly from "plotly.js";
  export default Plotly;
}
```

### 8.7 Container 6 – `cohort-bar/CohortBar.tsx`

`<Pane as="footer" aria-label="Cohort" className="col-span-full min-h-9 px-2.5 py-1" />` –
empty, keeps its height so the layout matches the mockup. Phase 3 adds the "Cohort:"
buttons (Flags, Summary, Boxplots, X/Y ratio, Legend).

---

## 9. Coding style

### Files and names
- Components: PascalCase, **one component per file**, file name = component name
  (`ViewportSlider.tsx`). Exception: shadcn files in `components/ui/` keep their
  generated kebab-case names (`dropdown-menu.tsx`).
- Folders: kebab-case, grouped by container (`top-bar/`, `nav-bar/`, …), shared parts in
  `common/` (domain-free) and `genome/` (genome drawing).
- Hooks: `useXxx.ts` in `hooks/`; pure helpers: camelCase files in `lib/`; tests next to
  them as `xxx.test.ts`.
- Props types: `interface <Component>Props`, declared above the component.
- Constants: `UPPER_SNAKE_CASE` in `lib/constants.ts` (or at the top of the only file
  using them).
- British spelling in UI text and names, like the backend (`normalisation`, `colour`).

### Components
- Function declarations (`export function TopBar() {…}`), **named exports** only (also
  `App`; update `main.tsx`), no `React.FC`, no default exports.
- A component reads what it needs itself (`useProjectData()`, `useViewStore(selector)`)
  instead of receiving long prop chains; generic components (`ui/`, `common/`, `genome/`)
  take everything through props and know nothing about the store.
- Components render; calculations live in `lib/` (pure, tested).
- No `useEffect` for derived values – compute them during render or with `useMemo`.
  Effects only for the outside world (fetch, Plotly, observers).
- Every component and hook gets a one-line `/** … */` doc comment; requirement IDs in
  comments where a requirement is implemented (`// FR33`), as in the backend.

### TypeScript
- Keep the existing strict `tsconfig` (`strict`, `noUncheckedIndexedAccess`,
  `verbatimModuleSyntax`); no `any`, no `!` non-null assertions – handle `undefined`.
- `import type { … }` for type-only imports (required by `verbatimModuleSyntax`).
- Imports through the `@/` alias, without file extensions (same as the generated shadcn
  files; change the two existing `./api/client.ts` style imports). Order: React,
  third-party, `@/…`, relative – Prettier/ESLint keep it.
- API shapes only in `api/types.ts`; domain types (`GenomeRange`) in `lib/genome.ts`.

### Styling
- Tailwind utilities only; the one CSS file is `styles/globals.css`.
- Colours, fonts and sizes **only through tokens** – no hex/rgb, no `text-[13px]`,
  no `font-['Segoe_UI']` in components. Missing value → add a token.
- Inline `style` only for computed geometry (percent positions, plot-margin padding).
- Conditional classes with `cn()`; component variants with `cva` (only in `ui/`).
- Class names must be complete static strings (Tailwind scans the source).
- Accessibility: landmarks with `aria-label`, real `<button>`/`<label>`, visible focus
  (global `:focus-visible`), disabled controls explained with `title`.

### Tooling
- Prettier: `printWidth: 100`, double quotes, semicolons, `trailingComma: "all"` (matches
  the current code), `prettier-plugin-tailwindcss` with
  `tailwindStylesheet: "./src/styles/globals.css"` and `tailwindFunctions: ["cn", "cva"]`.
- ESLint flat config: `@eslint/js` recommended, `typescript-eslint` recommended,
  `eslint-plugin-react-hooks` (rules-of-hooks, exhaustive-deps), `eslint-plugin-react-refresh`.
- Scripts: `dev`, `build` (`tsc -b && vite build`), `typecheck`, `lint`, `format`,
  `format:check`, `test` (`vitest run`). Before each commit: `lint`, `typecheck`, `test`.

---

## 10. Implementation steps

### Step 0 – Backend: project folder name in `/api/project` [x]
1. `schemas.ProjectInfo`: add `name: str = Field(description="project folder name", examples=["demo_cohort"])`.
2. `queries.project_info(manifest, name)`; `create_app` passes `project_dir.resolve().name`
   (only the folder name, not the full path).
3. Update `tests/test_server.py`; `web/src/api/types.ts`: `name: string`.
4. `feat(server): add project folder name to /api/project`

### Step 1 – Tooling [x]
1. `npm i -D tailwindcss @tailwindcss/vite @types/node vitest prettier prettier-plugin-tailwindcss eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh globals`
2. `npm i zustand`; `npm uninstall react-plotly.js @types/react-plotly.js`
3. `vite.config.ts`: `defineConfig` from `vitest/config`, plugins `[react(), tailwindcss()]`,
   `resolve.alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) }`,
   `test: { environment: "node", include: ["src/**/*.test.ts"] }`; keep proxy, `base`, build settings.
4. `tsconfig.json`: `"paths": { "@/*": ["./src/*"] }` (no `baseUrl` – removed in TypeScript 7,
   `paths` resolve relative to the tsconfig).
5. `npx shadcn@latest init`: Vite, style new-york, CSS file `src/styles/globals.css`,
   CSS variables on, icon library lucide; aliases `@/components`, `@/components/ui`,
   `@/lib`, `@/lib/utils`, `@/hooks`. Installs `class-variance-authority`, `clsx`,
   `tailwind-merge`, `lucide-react`, `tw-animate-css`, creates `components.json` and `lib/utils.ts`.
6. Add `eslint.config.js`, `.prettierrc.json`, `.prettierignore` (`dist`), scripts (section 9).
7. Check peer-dependency warnings of the Tailwind Vite plugin against Vite 8 / React 19.
8. Done when `npm run build`, `lint`, `test` (no tests yet → `--passWithNoTests`) pass.
   `chore(web): add tailwind, shadcn/ui, zustand, eslint, prettier and vitest`

### Step 2 – Design tokens [x]
1. Replace the token block generated by `shadcn init` (oklch) with section 5.2.
2. `main.tsx` imports `@/styles/globals.css`; delete `App.css`.
3. Quick check page: a few `bg-seq-*` boxes and the 5 text sizes, removed afterwards.
   `style(web): define shared design tokens, fonts and sizes`

### Step 3 – Shared UI components [ ]
1. `npx shadcn@latest add button button-group input label select toggle toggle-group dropdown-menu`
2. Restyle to the mockup (section 6): button variants, `h-control`, `rounded-sm`,
   `border-input`, `text-body`/`text-small`, menu `shadow-menu`, item hover `bg-accent`,
   toggle pressed state, joined group borders (`-ml-px`, outer corners only).
3. Remove what we do not use from the generated files (dark-mode classes, unused variants).
   `feat(web): add restyled shadcn/ui button, input, select, toggle and menu components`

### Step 4 – Pure helpers + tests [ ]
1. `lib/format.ts` (move `formatBp` out of `App.tsx`; `formatPosition` → `2,458,321`;
   `formatRegionLabel` → `chrY:2,458,321-27,020,249`, 1-based; `formatDepth` → `30.1×`).
2. `lib/genome.ts`, `lib/viewRange.ts`, `lib/ticks.ts`, `lib/sequenceClasses.ts`,
   `lib/constants.ts`, `lib/theme.ts`, `lib/plotly.ts`, `types/plotly-dist-min.d.ts`.
3. Tests: clamping at both ends and minimum span, move keeps the span, resize keeps the
   other edge, centring near the edges, `assignLanes` on the real regions (AZFc → lane 1),
   `niceStep` 1/2/5 steps, tick labels, 1-based region label, every class name of
   `sequence_classes.bed` maps to a non-`other` group except `OTHER`.
   `feat(web): add genome, view range, tick and format helpers with tests`

### Step 5 – Data and state layer [ ]
1. `hooks/useProjectLoader.ts` (from the current `App.tsx` logic: `Promise.all`,
   `AbortController`, StrictMode-safe) + coverage request at `COVERAGE_RESOLUTION`.
2. `state/projectData.tsx`, `state/viewStore.ts`; initialise the store before "ready".
3. `hooks/useElementWidth.ts`, `hooks/useInView.ts`.
4. `components/common/StatusMessage.tsx`; `App.tsx` reduced to loader + gate + provider.
   `feat(web): load project data once and keep the view range in a zustand store`

### Step 6 – Layout shell [ ]
1. `common/Pane.tsx`, `common/LabeledValue.tsx`, `layout/AppLayout.tsx`.
2. Six container components with placeholder text, correct landmarks and spans.
3. Compare with the mockup side by side at 1440 × 900 and at 900 px width (stacked).
   `feat(web): add the six-pane page layout`

### Step 7 – Top bar [ ]
`TopBar`, `ProjectSummary`, `ReadsToggle`, `NormalisationSelect`, `ExportMenu` (section 8.2).
`feat(web): add top bar with project info and disabled parameter controls`

### Step 8 – Navigation bar [ ]
`NavBar`, `RegionInput`, `ClassSelect`, `ViewControls`, `ViewSpan` (section 8.3).
`feat(web): add navigation bar with disabled region, class and zoom controls`

### Step 9 – Chromosome overview with slider [ ]
1. `genome/SequenceClassBar`, `genome/RegionLanes`, `genome/GenomeAxis`.
2. `overview/ChromosomeOverview`, `overview/ViewportSlider` (drag technique 8.4).
3. Check: class colours match the mockup legend; AZFb/AZFc on separate lanes; dragging
   is smooth, cannot leave the chromosome, cannot shrink below 100 kb; `ViewSpan` and the
   region input update while dragging.
   `feat(web): add chrY overview with sequence classes, regions and viewport slider`

### Step 10 – Sample sidebar [ ]
`SampleSidebar`, `SampleListItem` (section 8.5).
`feat(web): add sample list sidebar`

### Step 11 – Track header [ ]
`TrackPanel` scroll container, sticky `TrackHeader` with axis + class band of the view.
`feat(web): add track panel header with region-in-view axis and class band`

### Step 12 – Coverage rows [ ]
1. `common/PlotlyChart`, `tracks/CoveragePlot`, `tracks/SampleLabel`, `tracks/SampleTrackRow`.
2. Grey masked shapes (gap/PAR), dotted line at 1 copy.
3. Check: axis ticks in the header line up with the plots (drag the slider so a class
   border sits under a tick and compare); hover shows position and value; rows mount
   lazily when scrolling (DevTools → elements).
   `feat(web): add per-sample Plotly coverage plots following the viewport`

### Step 13 – Cohort bar [ ]
Empty `CohortBar` (section 8.7). `feat(web): add empty cohort bar`

### Step 14 – Verification and cleanup [ ]
See section 11. Then update `phase2_plan.md` Week 6 item 3/4 checkboxes and
`requirements.md` notes. `chore(web): …` for leftovers.

---

## 11. Verification and acceptance

Run on both example datasets:

```bash
cd code/ycov
uv run ycov prepare example_data/simulated/S??.regions.bed.gz -o /tmp/ycov_sim
uv run ycov prepare example_data/real/HG?????.regions.bed.gz -o /tmp/ycov_real
cd web && npm run build && cd ..
uv run ycov view /tmp/ycov_sim          # built frontend
# or, for development: uv run ycov view /tmp/ycov_sim --no-browser  +  cd web && npm run dev
```

(The globs skip the `.q20` files, MAPQ input is Phase 3.)

Acceptance criteria:

- [ ] Page shows the 6 containers in the mockup arrangement and proportions; stacked
      below 980 px; no horizontal page scroll.
- [ ] Top bar: logo, project folder name, reference; Reads, Normalisation and Export
      are visible and disabled with an explanatory tooltip.
- [ ] Nav bar: all controls disabled; region text and "x Mb in view" follow the slider.
- [ ] Overview: sequence classes in the mockup colours across the whole chrY, PAR1/2 and
      AZFa/b/c lanes labelled, Mb axis, red slider moves and resizes with mouse and
      touch, click centres, stays inside chrY, minimum 100 kb.
- [ ] Sidebar lists all samples (11 simulated / 10 real) with baselines.
- [ ] Track panel: sticky header with axis and class band of the view; one Plotly
      coverage graph per sample; x-range follows the slider; grey shapes over gaps and
      PARs; header ticks aligned with the plots.
- [ ] Simulated truth is visible by eye: S02 ~0 in AZFc, S07 ~0 in AZFa, S08 ~0 in AZFb,
      S03 ~0.5, S04 (female) ~0, S05 ~2, S11 ~0.5 at the AZFc end, S01 ~1.
- [ ] Slider drag stays smooth with all samples (no visible lag, NFR4); first load
      ≤ 3 s (NFR3) – write the numbers down for the thesis (Week 7 item 2).
- [ ] Works in current Chrome and Firefox (NFR9); no requests to the internet in the
      DevTools network tab (NFR1, NFR21).
- [ ] `npm run lint`, `typecheck`, `format:check`, `test`, `build` pass; backend
      `uv run pytest` still green.
- [ ] No hex colours or raw pixel font sizes in `src/components/**` (`grep -rnE "#[0-9a-fA-F]{3,6}|text-\[" src/components` returns nothing).

---

## 12. Prepared for Phase 3

The structure already has a place for each next feature, so they are additions, not
rewrites:

| Feature | Where it plugs in |
|---|---|
| Zoom/move/Reset, region and gene search (FR35-FR37) | `ViewControls`, `RegionInput`, `ClassSelect` call `setView`; pure parsing in `lib/` |
| Resolution switching while zooming (1 kb, FR15) | `useCoverage(view)` hook replacing the single request; `MIN_VIEW_SPAN` down to ~1 kb |
| MAPQ switch, normalisation modes (FR57, FR58) | `ReadsToggle`, `NormalisationSelect` → new fields in a settings store → coverage query |
| Sample select/hide, sort, group (FR42-FR44) | `SampleSidebar` + a `sampleStore`; `TrackPanel` maps the visible order |
| Heatmap strip per row / heatmap view (FR32) | new `HeatmapStrip` next to `CoveragePlot`, `--coverage-loss/normal/gain` tokens exist |
| Cohort windows, legend, flags (FR46-FR55) | buttons in `CohortBar`, shadcn `Dialog` |
| Exports (FR61-FR63) | items of `ExportMenu`; Plotly `toImage` through `PlotlyChart` |
| TanStack Query, openapi-typescript | replaces `useProjectLoader` / `api/types.ts`, components unchanged |
| 500 samples (NFR6) | virtualise `TrackPanel` rows (TanStack Virtual) on top of `useInView` |
