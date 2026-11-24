# ycov prepare vs the simulation truth

| | |
|---|---|
| Date (UTC) | 2026-11-11 16:35 |
| ycov version | 0.1.0 |
| ycov commit | 1f50824 + uncommitted changes |
| Command | `scripts/validate_truth.py example_data/simulated --outdir ../../documentation/ycovThesisDocumentation/phases/phase2/results` |
| Input | `example_data/simulated` (11 samples, all-reads coverage, 1 kb windows) |
| Simulation | `scripts/simulate.py` via `scripts/make_test_data.sh`, seed 42 |
| ycov prepare runtime | 1.3 s |
| Truth rows within tolerance | 15 / 15 |

## Method

- rel_copy = depth / (baseline / 2), baseline = median depth of the sample's
  chr19-22 windows with depth > 0 (two copies), so one chrY copy gives 1.
- Only reliable windows (not gap, not PAR) have a rel_copy; the others are left out.
- Measured value = median rel_copy of the selected windows.
- Event rows (a region): all windows lying fully inside the region.
  Tolerance +/-0.05.
- Background rows (whole chrY): X-DEG windows outside the sample's
  events. Tolerance +/-0.1. Other classes carry the depth bias the
  simulator copied from real data (see the class table).
- Baseline: within 5% of the simulated autosome depth.

## Truth check

| sample_id | scenario | region | windows | n_windows | expected | measured | diff | tolerance | passed |
|---|---|---|---|---|---|---|---|---|---|
| S01 | normal_male | chrY | X-DEG | 8666 | 1.000 | 0.946 | -0.054 | 0.100 | True |
| S02 | azfc_del | AZFc | all | 3692 | 0.000 | 0.000 | 0.000 | 0.050 | True |
| S02 | azfc_del | chrY | X-DEG | 8666 | 1.000 | 0.947 | -0.053 | 0.100 | True |
| S03 | mloy_50 | chrY | X-DEG | 8666 | 0.500 | 0.475 | -0.025 | 0.100 | True |
| S04 | female | chrY | X-DEG | 8666 | 0.000 | 0.000 | 0.000 | 0.100 | True |
| S05 | xyy | chrY | X-DEG | 8666 | 2.000 | 1.917 | -0.083 | 0.100 | True |
| S06 | shallow_5x | chrY | X-DEG | 8666 | 1.000 | 0.938 | -0.062 | 0.100 | True |
| S07 | azfa_del | AZFa | all | 790 | 0.000 | 0.000 | 0.000 | 0.050 | True |
| S07 | azfa_del | chrY | X-DEG | 7874 | 1.000 | 0.948 | -0.052 | 0.100 | True |
| S08 | azfb_del | AZFb | all | 7759 | 0.000 | 0.000 | 0.000 | 0.050 | True |
| S08 | azfb_del | chrY | X-DEG | 6438 | 1.000 | 0.957 | -0.043 | 0.100 | True |
| S09 | normal_male_2 | chrY | X-DEG | 8666 | 1.000 | 0.946 | -0.054 | 0.100 | True |
| S10 | normal_male_3 | chrY | X-DEG | 8666 | 1.000 | 0.955 | -0.045 | 0.100 | True |
| S11 | partial_azfc | azfc_partial | all | 529 | 0.500 | 0.458 | -0.042 | 0.050 | True |
| S11 | partial_azfc | chrY | X-DEG | 8666 | 1.000 | 0.956 | -0.044 | 0.100 | True |

## Median rel_copy per sequence class

| sample_id | scenario | AMPL | CEN | DYZ17 | DYZ19 | HET | OTHER | SAT | X-DEG | XTR1 | XTR2 | all |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| S01 | normal_male | 0.921 | 1.000 | 0.989 | 1.100 | 0.643 | 0.948 | 0.963 | 0.946 | 0.936 | 0.958 | 0.843 |
| S02 | azfc_del | 0.757 | 0.939 | 1.011 | 1.164 | 0.641 | 0.938 | 0.967 | 0.947 | 0.935 | 0.944 | 0.805 |
| S03 | mloy_50 | 0.458 | 0.487 | 0.514 | 0.591 | 0.319 | 0.475 | 0.486 | 0.475 | 0.473 | 0.460 | 0.416 |
| S04 | female | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| S05 | xyy | 1.851 | 1.955 | 2.071 | 2.394 | 1.299 | 1.876 | 1.956 | 1.917 | 1.887 | 1.953 | 1.714 |
| S06 | shallow_5x | 0.909 | 0.974 | 1.000 | 1.320 | 0.636 | 0.934 | 0.950 | 0.938 | 0.926 | 0.903 | 0.805 |
| S07 | azfa_del | 0.916 | 0.942 | 1.009 | 1.314 | 0.642 | 0.942 | 0.965 | 0.929 | 0.927 | 0.961 | 0.833 |
| S08 | azfb_del | 0.000 | 0.983 | 1.025 | 0.000 | 0.638 | 0.979 | 0.988 | 0.896 | 0.944 | 0.948 | 0.742 |
| S09 | normal_male_2 | 0.921 | 0.976 | 1.044 | 1.280 | 0.639 | 0.964 | 0.964 | 0.946 | 0.933 | 0.937 | 0.845 |
| S10 | normal_male_3 | 0.928 | 0.940 | 1.022 | 1.198 | 0.648 | 0.947 | 0.970 | 0.955 | 0.942 | 0.942 | 0.849 |
| S11 | partial_azfc | 0.908 | 0.975 | 1.049 | 1.339 | 0.644 | 0.938 | 0.973 | 0.956 | 0.944 | 0.952 | 0.843 |

## Baselines

| sample_id | scenario | simulated_depth | baseline | ratio | passed |
|---|---|---|---|---|---|
| S01 | normal_male | 30.000 | 30.130 | 1.004 | True |
| S02 | azfc_del | 30.000 | 30.080 | 1.003 | True |
| S03 | mloy_50 | 30.000 | 30.000 | 1.000 | True |
| S04 | female | 30.000 | 30.250 | 1.008 | True |
| S05 | xyy | 30.000 | 29.915 | 0.997 | True |
| S06 | shallow_5x | 5.000 | 4.970 | 0.994 | True |
| S07 | azfa_del | 30.000 | 30.140 | 1.005 | True |
| S08 | azfb_del | 30.000 | 30.020 | 1.001 | True |
| S09 | normal_male_2 | 30.000 | 30.175 | 1.006 | True |
| S10 | normal_male_3 | 30.000 | 29.930 | 0.998 | True |
| S11 | partial_azfc | 30.000 | 29.900 | 0.997 | True |
