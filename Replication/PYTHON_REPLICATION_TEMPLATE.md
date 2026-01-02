# Python Replication Code Template

## Project Title

**PROJECT_NAME**: Data Construction and Descriptive Analysis Pipeline  

### Overview

This repository contains the **data cleaning and preparation** pipeline for the project **PROJECT_NAME**. The Python scripts handle:

- Pulling raw data from external sources (e.g., WRDS)
- Cleaning and merging datasets
- Constructing treatment, outcome, and control variables
- Producing summary statistics and figures
- Exporting analysis-ready files for downstream statistical software (e.g., Stata/R)

### Prerequisites

- **Python**: 3.8+
- **Python packages** (typical stack, adjust as needed):
  - `pandas`, `numpy`
  - `wrds` (if using WRDS)
  - `matplotlib`, `seaborn`
  - `tabulate`
  - `openpyxl`
- **External access**:
  - Valid credentials for any external databases (e.g., WRDS)

Install dependencies (example):

```bash
pip install pandas numpy wrds matplotlib seaborn tabulate openpyxl
```

### Directory Structure

Assumed project layout:

```
PROJECT_ROOT/
├── 3. Data/
│   ├── Raw/          # Raw pulls from external sources
│   └── Processed/    # Cleaned / merged analysis files
└── 4. Code/
    └── Replication/
        ├── CR_1_....py
        ├── CR_2_....py
        ├── CR_3_....py
        ├── CR_4_....py
        ├── CR_5_....py
        └── README.md
```

Each Python script uses **paths relative to the script** and then walks up to `PROJECT_ROOT` to avoid hard‑coding machine-specific paths:

```python
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(os.path.dirname(script_dir))

raw_dir = os.path.join(project_root, '3. Data', 'Raw')
processed_dir = os.path.join(project_root, '3. Data', 'Processed')
os.makedirs(raw_dir, exist_ok=True)
os.makedirs(processed_dir, exist_ok=True)
```

### Pipeline Overview (Example Order)

Adapt names and descriptions to your project:

1. **`CR_1_CleanSourceA.py`**  
   - Pulls base accounting / firm fundamentals from a database (e.g., Compustat via WRDS)  
   - Applies minimal cleaning and variable construction:
     - Balance sheet and income statement items
     - Profitability, leverage, interest expense
     - Key indicators (e.g., treatment flags, NOL, foreign income)  
   - Caches raw pulls to `3. Data/Raw` to avoid re-querying  
   - Saves a merged, firm-year panel (e.g., `comp_sourceA_merged.csv`) to `3. Data/Processed`

2. **`CR_2_CleanSourceBMerge.py`**  
   - Cleans transaction-level / contract-level data (e.g., Dealscan)  
   - Merges with firm-year panel from Step 1  
   - Maps industry codes (e.g., SIC → Fama-French industries)  
   - Applies core sample filters:
     - Remove unwanted industries (e.g., finance, utilities)
     - Restrict years
     - Drop missing key variables  
   - Generates contract-level variables (e.g., spreads, maturity, covenants, lender characteristics)  
   - Saves:
     - A "full" dataset (all variables)  
     - A "filtered" dataset for analysis (e.g., `tranche_level_ds_compa_filtered.csv`)

3. **`CR_3_TreatmentDummies.py`**  
   - Reads filtered contract-level data and firm-level panel  
   - Constructs:
     - Treatment indicators (current, lagged, forward windows)
     - Post-period indicator(s)
     - Interaction terms (e.g., `treated_post`, year-by-treatment dummies)  
   - Generates analysis-ready Stata `.dta` files:
     - Main analysis sample (`tranche_level_ds_compa.dta`)
     - Firm-level treatment assignment panel (`ds_gvkey_treatment_assignment.dta`)
     - Any auxiliary panels (e.g., DTA analysis: `dta_analysis.dta`)

4. **`CR_4_SummaryStatistics.py`**  
   - Reads analysis-ready CSV from Step 2 or 3  
   - Defines a dictionary mapping **variable names → human-readable labels** for tables  
   - Drops observations missing any core variables for the summary table  
   - Computes and exports LaTeX tables:
     - Summary statistics (N, mean, SD, quartiles)  
     - Optionally: correlation matrix with numbered rows/columns suitable for an appendix

5. **`CR_5_SummaryFigures.py`**  
   - Generates key descriptive figures:
     - Time series of treated vs. untreated counts
     - Histograms of key ratios (with thresholds highlighted)
     - Correlation heatmaps or other diagnostic plots  
   - Saves high-resolution PNG/PDF files to the Overleaf `Figures/` directory (or similar)

6. *(Optional)* **`AN_*_PostProcessing.py`**  
   - Reads regression output (e.g., `esttab` CSV exports)  
   - Produces dynamic plots (event-study coefficients, etc.)  
   - Writes figures and text summaries for inclusion in the paper.

### Common Coding Practices

- **Path handling**  
  - Always derive `project_root` from `__file__` (no hard-coded user paths).
  - Centralize `raw_dir`, `processed_dir`, `tabdir`, `figdir` at the top of each script.

- **Idempotent I/O**  
  - Before querying external sources, check if a cached CSV exists:
    - If yes, load from disk.
    - If no, pull from source and save to `Raw/`.
- **Panel logic**  
  - Use `groupby` with `shift` for constructing lag/lead variables and rolling windows.
  - Carefully handle missing data (`isna()` masks) and type casting (`Int64` for indicator variables).

- **Diagnostics & logging**  
  - Print concise progress messages and sample size summaries at key filtering steps.
  - Optionally, print head of main data frames after major transformations.

- **Numeric stability**  
  - Replace infinite values with `NaN` before saving:
    ```python
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    ```
  - When constructing ratios, guard against division by zero and clip tails when appropriate.

- **Exporting to Stata**  
  - Ensure problematic columns (e.g., Python datetime) are converted to string or numeric before `.to_stata`.
  - Use a consistent Stata version (e.g., `version=117`) for compatibility.

### Running the Pipeline

Typical order (adapt to your project):

```bash
python3 CR_1_CleanSourceA.py
python3 CR_2_CleanSourceBMerge.py
python3 CR_3_TreatmentDummies.py
python3 CR_4_SummaryStatistics.py
python3 CR_5_SummaryFigures.py
```

You may also maintain a tiny **master script** (`run_all.py`) that calls each step in sequence and reports completion.

