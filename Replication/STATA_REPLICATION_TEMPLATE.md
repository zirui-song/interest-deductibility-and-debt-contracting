# Stata Replication Code Template

## Project Title

**PROJECT_NAME**: Stata Analysis and Replication Scripts  

### Overview

The Stata `.do` files in this folder implement the **statistical analysis** for **PROJECT_NAME** using prepared datasets from the Python phase. The scripts are organized to:

- Define global paths and shared settings
- Clean and label analysis datasets
- Estimate main and auxiliary regressions
- Produce publication-ready LaTeX tables and figures
- Run validation, mechanism, falsification, robustness, and appendix analyses

### Directory & Path Conventions

At the top of each `.do` file, define global paths in a standardized way:

```stata
/***********
	Globals for Paths
***********/

*** Change repodir and overleafdir for different users
global repodir    "/ABSOLUTE/PATH/TO/PROJECT_ROOT"
global overleafdir "/ABSOLUTE/PATH/TO/OVERLEAF_PROJECT"

global datadir  "$repodir/3. Data"
global rawdir   "$datadir/Raw"
global cleandir "$datadir/Processed"

global tabdir   "$overleafdir/Tables"
global figdir   "$overleafdir/Figures"

global codedir  "$repodir/4. Code/Replication"
```

**Practice**:  
- Keep **all** path changes centralized to `repodir` and `overleafdir`.
- Use `$cleandir`, `$tabdir`, `$figdir`, `$codedir` in all file references.

### Shared Utility Programs

Put reusable Stata programs (cleaning, labeling, treatment-variable construction) in a dedicated file like `AN_StataFunctions.do` and call it from other scripts:

```stata
do "$codedir/AN_StataFunctions.do"
clean_rating
clean_variables
generate_treat_vars
```

Typical structure inside the functions file:

- `clean_rating`: convert ratings strings to numeric scores and `not_rated` flag.
- `clean_variables`: create logs, interaction terms, winsorize variables, label controls.
- `generate_treat_vars`: build continuous/tiered treatment variables and quartiles.

### Script Ordering (Example)

Adjust to your project but preserve the **logical flow**:

1. **`AN_1_CleanFinalSample.do` — Final Sample Construction**  
   - Load main analysis dataset (`tranche_level_ds_compa.dta`).  
   - Source shared functions and apply cleaning:
     - Rating cleaning
     - Variable generation
     - Treatment variable construction  
   - Save a labeled regression-ready dataset (e.g., `tranche_level_ds_compa_wlabel.dta`).

2. **`AN_2_TreatmentValidation.do` — Validation & Exposure Regressions**  
   - Merge in treatment-assignment panel (e.g., `ds_gvkey_treatment_assignment.dta`).  
   - Recreate key treatment indicators and interactions (`treated`, `treated_post`, etc.).  
   - Winsorize controls and deal characteristics.  
   - Run exposure / validation regressions (e.g., `reghdfe` of future excess interest on current exposure).  
   - Export tables via `esttab` and generate diagnostic plots (e.g., `binscatter`, `binsreg`).

3. **`AN_3_SampleCompositionAnalysis.do` — Sample Composition & Outcomes**  
   - Build a firm-year panel from an auxiliary dataset (e.g., DTA panel).  
   - Compute key ratios (e.g., `log_at`, `cash_flows_by_at`, etc.) and interactions with `post`.  
   - Link to loan-level data; compute future outcomes (e.g., next-year EBITDA, ROA).  
   - Run regressions for sample composition / risk tests.  
   - Export LaTeX tables for risk/selection checks.

4. **`AN_4_MainResults.do` — Main DiD Regressions**  
   - Work from `tranche_level_ds_compa_wlabel.dta`.  
   - Define locals:
     - `controls` (firm fundamentals)  
     - `deal_controls` (contract-level covariates)  
     - `controls_post` (post × controls)  
   - Optionally run multicollinearity diagnostics (`reg` + `estat vif`).  
   - Estimate main `reghdfe` specifications:
     - Different FE structures (`year ff_48 sp_rating_num`, `year#ff_48`, etc.)  
     - Alternative outcomes (e.g., log spread)  
     - Subsamples (e.g., rating bands)  
   - Export tables (full and "no-controls" versions) using consistent file naming.  
   - Optional dynamic/event-study regressions with year-specific interactions and export of CSVs for plotting.

5. **`AN_5_MechanismTests.do` — Mechanisms & Heterogeneity**  
   - Construct and merge firm- and industry-level measures (e.g., lender competition, constraints).  
   - Partition the sample (e.g., high vs. low competition, high vs. low constraint).  
   - Run split-sample regressions with consistent specification:
     - `reg` with FE via factor variables (`i.year i.ff_48 ib2.sp_rating_num`) or `reghdfe`.  
   - Use `suest` or equivalent tests to compare coefficients across groups.  
   - Export mechanism tables to `Tables/` with clear names (e.g., `*_cross.tex`).

6. **`AN_6_FalsificationTests.do` — Placebos & Robustness Variants**  
   - Load alternative or extended datasets (e.g., CSV → `import delimited`).  
   - Redefine `post` for pre-period placebo windows.  
   - Rebuild treatment variables via shared functions.  
   - Run falsification regressions for:
     - Binary treatments  
     - Continuous exposure  
     - Quartile dummies  
   - Export falsification tables with distinct filenames.

7. **`AN_7_AppendixTables.do` — Appendix & Robustness Tables**  
   - Produce quartile exposure tables, alternative FE structures, lender FE checks.  
   - Run entropy balancing or weighting if desired.  
   - Additional robustness (e.g., dropping certain subsamples, adding extra controls).  
   - Export all appendix tables with systematic naming (e.g., `margin_ie_excess_quartiles.tex`, `*_lenderfe.tex`, etc.).

### Common Stata Practices

- **Global path pattern**  
  - Always start each `.do` file with the same global definitions.
  - Only adjust `global repodir` and `global overleafdir` when moving machines.

- **Modular functions**  
  - Keep transformation logic (winsorization, interactions, labeling) in a single `AN_StataFunctions.do`.  
  - Call `clean_rating`, `clean_variables`, `generate_treat_vars` immediately after loading a dataset that needs them.

- **Locals for variable groups**  
  - Use `local` macros for groups of controls & treatments:
    ```stata
    local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
    local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"
    local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post dividend_payer_post ret_vol_post cash_etr_post"
    local treat_quartiles "ie_excess_q1 ie_excess_q1_post ie_excess_q2 ie_excess_q2_post ie_excess_q3 ie_excess_q3_post ie_excess_q4 ie_excess_q4_post"
    ```

- **High-dimensional FE regressions**  
  - Use `reghdfe` (or equivalent) consistently:
    ```stata
    reghdfe margin_bps excess_interest_scaled excess_interest_scaled_post `controls' `deal_controls' `controls_post', ///
        absorb(year ff_48 sp_rating_num) vce(cluster gvkey)
    ```
  - Use clear FE blocks: `year`, `ff_48` industries, rating bins, lender FEs as needed.

- **Winsorization & missing data**  
  - Apply `winsor2` for key variables at standardized cutoffs (e.g., 1% and 99%).  
  - For sweep-like indicator variables, set missing to zero where conceptually appropriate.

- **Tables and figures**  
  - Use `esttab` with a **consistent style**:
    ```stata
    esttab m1 m2 m3 using "$tabdir/margin_ie_excess.tex", replace ///
        nodepvars nomti nonum collabels(none) label b(3) se(3) parentheses ///
        star(* 0.10 ** 0.05 *** 0.01) ar2 plain lines fragment noconstant drop(_cons `controls_post')
    ```
  - Export figures with explicit axis labels and units, and save to `$figdir` with descriptive names.

- **Logging & batch mode**  
  - Run `.do` files in batch (`stata -b do FILE.do`) and rely on `.log` files for diagnostics.  
  - Keep logs and `.do` files in sync; if you change a script, re-run and keep the log alongside.

### Running the Stata Scripts

Typical execution order (adapt names as needed):

```bash
stata -b do AN_1_CleanFinalSample.do
stata -b do AN_2_TreatmentValidation.do
stata -b do AN_3_SampleCompositionAnalysis.do
stata -b do AN_4_MainResults.do
stata -b do AN_5_MechanismTests.do
stata -b do AN_6_FalsificationTests.do
stata -b do AN_7_AppendixTables.do
```

Ensure that:

- All `.dta` and `.csv` inputs referenced by later scripts are produced by earlier steps.
- `AN_StataFunctions.do` is kept up to date and is sourced wherever needed.

You can copy these templates into other projects by adjusting:

- Project name and description
- Variable and script names
- External data sources and FE structures  
while retaining the overall organization, path conventions, and coding style.

