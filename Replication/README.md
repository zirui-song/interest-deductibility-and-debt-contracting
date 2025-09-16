# Interest Deductibility and Debt Contracting Analysis Pipeline

This repository contains the complete analysis pipeline for studying the effects of interest deductibility limitations on debt contracting terms. The analysis is divided into two main phases: **Data Cleaning and Preparation** (Python scripts) and **Statistical Analysis** (Stata scripts).

## Overview

This project examines how the Tax Cuts and Jobs Act (TCJA) of 2017, which limited interest deductibility, affected loan contracting terms for firms with excess interest expenses. The analysis uses a difference-in-differences approach comparing firms affected by the 30% rule and loss rule before and after the policy change.

## Prerequisites

### Software Requirements
- **Python 3.8+** with the following packages:
  - pandas, numpy, matplotlib, seaborn
  - tabulate, openpyxl
  - wrds (for WRDS database access)
- **Stata 15+** (SE, MP, or IC versions)
- **WRDS account** for accessing Compustat and CRSP data

### Data Requirements
- Compustat fundamental data (via WRDS)
- CRSP stock data (via WRDS)
- Dealscan loan data
- CIQ ratings data
- PIVOL covenant data
- Various linking tables and extensions

## Pipeline Structure

### Phase 1: Data Cleaning and Preparation (Python Scripts)

Run these scripts in the following order:

#### 1. `CR_1_CleanCompustatCRSP.py`
**Purpose**: Clean and prepare Compustat and CRSP data
- Connects to WRDS database
- Downloads Compustat fundamental data (2005-2024)
- Downloads CRSP stock data (2009-2024)
- Creates financial indicators and variables:
  - Excess interest indicators (30% rule, loss rule)
  - Financial ratios and controls
  - Market-based variables
- Merges Compustat and CRSP data using linking tables
- **Output**: `comp_crspa_merged.csv`

#### 2. `CR_2_CleanDealscanMerge.py`
**Purpose**: Clean Dealscan data and merge with Compustat/CRSP
- Processes CIQ ratings data
- Cleans and processes Dealscan loan data
- Creates relationship and reputation variables
- Merges Dealscan with Compustat/CRSP data
- Applies Fama-French 49 industry classifications
- Generates all analysis variables and ratios
- Applies data filtering (industry exclusions, year restrictions)
- **Outputs**: 
  - `tranche_level_ds_compa_all.csv` (complete dataset)
  - `tranche_level_ds_compa_filtered.csv` (filtered for analysis)

#### 3. `CR_3_TreatmentDummies.py`
**Purpose**: Create treatment indicators and interaction terms
- Generates treatment dummies for various definitions:
  - Current year treatment
  - Previous 3-year and 5-year treatment
  - Next 1-year, 3-year, and 5-year treatment
- Creates year dummies and interaction terms
- Analyzes persistence of treatment groups
- Prepares data for Stata analysis
- **Outputs**:
  - `tranche_level_ds_compa.dta` (main analysis dataset)
  - `ds_gvkey_treatment_assignment.dta` (treatment assignment data)
  - `dta_analysis.dta` (DTA analysis data)

#### 4. `CR_4_SummaryStatistics.py`
**Purpose**: Generate summary statistics and descriptive tables
- Creates descriptive statistics tables
- Generates correlation matrices
- Calculates pre-TCJA averages for treated firms
- Formats tables for LaTeX output
- **Outputs**:
  - `summary_stats_all.tex` (summary statistics table)
  - `correlation_matrix.tex` (correlation matrix table)

#### 5. `CR_5_SummaryFigures.py`
**Purpose**: Generate figures and visualizations
- Creates loan count plots by treatment status
- Generates interest expense histograms
- Creates correlation heatmaps
- Saves all figures to Overleaf directory
- **Outputs**: Various PNG files in `Figures/` directory

### Phase 2: Statistical Analysis (Stata Scripts)

Run these scripts in the following order:

#### 6. `AN_1_CleanFinalSample.do`
**Purpose**: Apply final data cleaning and prepare regression sample
- Applies final data filters
- Creates additional variables for analysis
- Prepares dataset for regression analysis
- **Dependencies**: Requires `tranche_level_ds_compa.dta` from CR_3

#### 7. `AN_2_TreatmentValidation.do`
**Purpose**: Validate treatment assignment and check balance
- Tests treatment group definitions
- Checks balance across treatment and control groups
- Validates treatment assignment logic
- **Dependencies**: Requires output from AN_1

#### 8. `AN_3_SampleCompositionAnalysis.do`
**Purpose**: Analyze sample composition and selection
- Examines changes in sample characteristics over time
- Tests for selection bias
- Analyzes sample composition by treatment status
- **Dependencies**: Requires output from AN_2

#### 9. `AN_4_MainResults.do`
**Purpose**: Estimate main difference-in-differences results
- Runs main regression specifications
- Tests treatment effects on loan terms (spreads, covenants, etc.)
- Estimates heterogeneous effects
- **Dependencies**: Requires output from AN_3

#### 10. `AN_5_MechanismTests.do`
**Purpose**: Test mechanisms and channels
- Examines channels through which treatment affects contracting
- Tests for specific mechanisms (e.g., tax shield effects)
- Analyzes intermediate outcomes
- **Dependencies**: Requires output from AN_4

#### 11. `AN_6_RobustnessChecks.do`
**Purpose**: Perform robustness checks and sensitivity analysis
- Alternative specifications and samples
- Placebo tests and falsification exercises
- Sensitivity to different treatment definitions
- **Dependencies**: Requires output from AN_5

#### 12. `AN_7_AdditionalAnalysis.do`
**Purpose**: Additional analysis and supplementary results
- Extended results and supplementary tables
- Additional figures and visualizations
- Extended discussion of results
- **Dependencies**: Requires output from AN_6

## File Organization

```
Replication/
├── CR_1_CleanCompustatCRSP.py      # Step 1: Clean Compustat/CRSP
├── CR_2_CleanDealscanMerge.py      # Step 2: Clean Dealscan & merge
├── CR_3_TreatmentDummies.py        # Step 3: Create treatment dummies
├── CR_4_SummaryStatistics.py       # Step 4: Summary statistics
├── CR_5_SummaryFigures.py          # Step 5: Generate figures
├── AN_1_CleanFinalSample.do        # Step 6: Final sample cleaning
├── AN_2_TreatmentValidation.do     # Step 7: Treatment validation
├── AN_3_SampleCompositionAnalysis.do # Step 8: Sample composition
├── AN_4_MainResults.do             # Step 9: Main results
├── AN_5_MechanismTests.do          # Step 10: Mechanism tests
├── AN_6_RobustnessChecks.do        # Step 11: Robustness checks
├── AN_7_AdditionalAnalysis.do      # Step 12: Additional analysis
└── README.md                       # This file
```

## Running the Analysis

### Option 1: Run Individual Scripts
Execute each script in the order listed above:

```bash
# Phase 1: Python scripts
python3 CR_1_CleanCompustatCRSP.py
python3 CR_2_CleanDealscanMerge.py
python3 CR_3_TreatmentDummies.py
python3 CR_4_SummaryStatistics.py
python3 CR_5_SummaryFigures.py

# Phase 2: Stata scripts
stata -b do AN_1_CleanFinalSample.do
stata -b do AN_2_TreatmentValidation.do
stata -b do AN_3_SampleCompositionAnalysis.do
stata -b do AN_4_MainResults.do
stata -b do AN_5_MechanismTests.do
stata -b do AN_6_RobustnessChecks.do
stata -b do AN_7_AdditionalAnalysis.do
```

### Option 2: Use the Master Script
Run the complete pipeline with:

```bash
python3 run_all.py
```

## Output Files

### Data Files (in `../../3. Data/Processed/`)
- `comp_crspa_merged.csv` - Merged Compustat/CRSP data
- `tranche_level_ds_compa_all.csv` - Complete merged dataset
- `tranche_level_ds_compa_filtered.csv` - Filtered analysis dataset
- `tranche_level_ds_compa.dta` - Main Stata analysis dataset
- `ds_gvkey_treatment_assignment.dta` - Treatment assignment data
- `dta_analysis.dta` - DTA analysis data

### Tables (in `Overleaf/Tables/`)
- `summary_stats_all.tex` - Summary statistics table
- `correlation_matrix.tex` - Correlation matrix table
- Various regression result tables

### Figures (in `Overleaf/Figures/`)
- Loan count plots
- Interest expense histograms
- Correlation heatmaps
- Various analysis figures

## Key Variables

### Treatment Variables
- `excess_interest_30` - 30% rule treatment indicator
- `excess_interest_loss` - Loss rule treatment indicator
- `treated` - Combined treatment indicator
- `post` - Post-TCJA period indicator

### Outcome Variables
- `margin_bps` - Interest spread in basis points
- `num_fin_cov` - Number of financial covenants
- `perf_pricing_dummy` - Performance pricing indicator
- `sweep_dummy` - Sweep covenant indicator

### Control Variables
- `log_at` - Log of total assets
- `market_to_book` - Market-to-book ratio
- `debt_by_at` - Debt-to-assets ratio
- `cash_by_at` - Cash-to-assets ratio
- `ret_vol` - Return volatility
- Various loan characteristics

## Notes

- **Data Dependencies**: Each script depends on outputs from previous scripts
- **Error Handling**: Check for errors at each step before proceeding
- **Memory Requirements**: Some scripts require significant memory for large datasets
- **WRDS Access**: Ensure WRDS credentials are properly configured
- **Stata Version**: Scripts are tested with Stata 15+ but may work with earlier versions

## Troubleshooting

### Common Issues
1. **WRDS Connection Errors**: Check internet connection and WRDS credentials
2. **Memory Errors**: Close other applications or use a machine with more RAM
3. **Stata Not Found**: Ensure Stata is installed and in your PATH
4. **File Not Found**: Ensure previous scripts have run successfully
5. **Permission Errors**: Check file permissions in output directories

### Getting Help
- Check the log files generated by each script
- Verify that all input data files are present
- Ensure all required Python packages are installed
- Check Stata installation and version compatibility

## Citation

If you use this code in your research, please cite the associated paper and acknowledge this repository.
