import pandas as pd

# Source: Rhie et al. 2023, Supplementary Table 21
# https://doi.org/10.1038/s41586-023-06457-y
EXCEL_PATH = "phases/phase2/41586_2023_6457_MOESM4_ESM.xlsx"
OUTPUT_PATH = "phases/phase2/data/sequence_classes.bed"

# The table has two class columns:
#   'Class'  - broad (PAR, X-DEG, XTR...) - only first 8 rows filled
#   'class'  - detailed (PAR1, PAR2, XTR1, XTR2, AMPL, SAT, CEN, HET...) - all rows filled
excel_df = pd.read_excel(
    EXCEL_PATH,
    sheet_name="ST21 Sequence class annotation",
    header=1,
    usecols=["chromosome", "start", "end", "class"],
)

# Keep only chrY rows (the table also contains HG002-Y and other assemblies)
excel_df = excel_df[excel_df["chromosome"] == "chrY"].copy()

# BED format: tab-separated, no header
excel_df.to_csv(OUTPUT_PATH, sep="\t", index=False, header=False)

print(f"Done. Written {len(excel_df)} rows to {OUTPUT_PATH}")
