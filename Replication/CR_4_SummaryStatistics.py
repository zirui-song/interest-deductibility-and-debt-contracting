import pandas as pd
import numpy as np
import os
from tabulate import tabulate

# Ensure output directory exists
processed_dir = os.path.join('..', '..', '3. Data', 'Processed')
os.makedirs(processed_dir, exist_ok=True)
overleaf_dir = "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Terms"
os.makedirs(os.path.join(overleaf_dir, 'Tables'), exist_ok=True)

# Read in the processed data with all variables already generated and filtered
tranche_level_ds_compa = pd.read_csv(os.path.join(processed_dir, 'tranche_level_ds_compa_filtered.csv'))

## Summary Statistics of Firms in the Final Sample

variable_labels = {
    'excess_interest_scaled': 'Excess Interest Expense (Scaled)',
    'deal_amount_converted': 'Loan Amount ($Million)',
    'leveraged': 'Leveraged',
    'margin_bps': 'Interest Spread (Basis Points)',
    'maturity': 'Maturity (Years)',
    'number_of_lead_arrangers': 'Number of Lead Arrangers',
    'secured_dummy': 'Secured',
    'sponsor_dummy': 'Sponsored',
    'tranche_o_a_dummy': 'Origination',
    'tranche_type_dummy': 'Term Loan',
    'total_asset': 'Assets ($Billion)',
    'cash_by_at': 'Cash / Assets',
    'debt_by_at': 'Debt / Assets',
    'dividend_payer': 'Dividend Payer',
    'ppent_by_at': 'PP&E / Assets',
    'ret_vol': 'Return Volatility',
    'market_to_book': 'Market to Book Ratio',
}

# Calculate summary statistics for the variables in variable_labels
summary_stats_all = tranche_level_ds_compa[variable_labels.keys()].describe().transpose()

# Rename the index using the variable labels
summary_stats_all.rename(index=variable_labels, inplace=True)

# Convert to LaTeX table with specified number format and labels
summary_stats_all.columns = ['Count', 'Mean', 'Std. Dev.', 'Min', 'P25', 'Median', 'P75', 'Max']
# drop min and max columns
summary_stats_all = summary_stats_all.drop(columns=['Min', 'Max'])
latex_table = tabulate(summary_stats_all, headers="keys", tablefmt="latex", floatfmt=(".0f", ".0f", ".2f", ".2f", ".2f", ".2f", ".2f"))

# Modify \hline to \hline\hline right after \begin{tabular}{lrrrrrr}
latex_table = latex_table.replace("\\begin{tabular}{lrrrrrr}\n\\hline", "\\begin{tabular}{lrrrrrr}\n\\hline\\hline")

# Modify \hline to \hline\hline right before \end{tabular}
latex_table = latex_table.replace("\\hline\n\\end{tabular}", "\\hline\\hline\n\\end{tabular}")

# Print or save the LaTeX table
print(latex_table)
with open(os.path.join(overleaf_dir, 'Tables/summary_stats_all.tex'), 'w') as f:
    f.write(latex_table)


# Create a correlation matrix for the variables in variable_labels
correlation_matrix = tranche_level_ds_compa[variable_labels.keys()].corr()

# Rename the index and columns using the shorter labels
correlation_matrix = correlation_matrix.rename(index=variable_labels, columns=variable_labels)

# Format all values to have 2 decimal places
formatted_matrix = correlation_matrix.applymap(lambda x: f"{x:.2f}")

# Create a mask for the upper triangle
mask = np.zeros_like(correlation_matrix, dtype=bool)
mask[np.triu_indices_from(mask, k=1)] = True

# Replace upper triangle values with empty strings
for i in range(len(formatted_matrix)):
    for j in range(i+1, len(formatted_matrix)):
        formatted_matrix.iloc[i, j] = ""

# Generate numbered labels for columns and rows
numbered_labels = {}
for i, label in enumerate(correlation_matrix.columns):
    numbered_labels[label] = f"({i+1}) {label}"

# Update the index and columns with the numbered labels
formatted_matrix.columns = [numbered_labels[col] for col in formatted_matrix.columns]
formatted_matrix.index = [numbered_labels[idx] for idx in formatted_matrix.index]

# Format to LaTeX table
latex_correlation = tabulate(formatted_matrix, headers="keys", tablefmt="latex")

# Modify \hline to \hline\hline right after \begin{tabular}
latex_correlation = latex_correlation.replace("\\begin{tabular}{l" + "r" * len(correlation_matrix.columns) + "}\\hline", 
                           "\\begin{tabular}{l" + "r" * len(correlation_matrix.columns) + "}\\hline\\hline")

# Modify \hline to \hline\hline right before \end{tabular}
latex_correlation = latex_correlation.replace("\\hline\n\\end{tabular}", "\\hline\\hline\n\\end{tabular}")

# Print or save the LaTeX table
with open(os.path.join(overleaf_dir, 'Tables/correlation_matrix.tex'), 'w') as f:
    f.write(latex_correlation)

# For firms affected by the 30% rule or loss rule during 2014-2017 
pre_tcja_avg = tranche_level_ds_compa[
    (tranche_level_ds_compa['year'] <= 2017) & 
    ((tranche_level_ds_compa['excess_interest_30'] == 1) | 
     (tranche_level_ds_compa['excess_interest_loss'] == 1))
]['margin_bps'].mean()

# Print the average spread in basis points
print(f"Pre-TCJA average interest spread for treated firms: {pre_tcja_avg:.2f} bps")

# Can also break down by treatment type
pre_tcja_30_avg = tranche_level_ds_compa[
    (tranche_level_ds_compa['year'] <= 2017) & 
    (tranche_level_ds_compa['excess_interest_30'] == 1)
]['margin_bps'].mean()

pre_tcja_loss_avg = tranche_level_ds_compa[
    (tranche_level_ds_compa['year'] <= 2017) & 
    (tranche_level_ds_compa['excess_interest_loss'] == 1)
]['margin_bps'].mean()

print(f"Pre-TCJA average interest spread for 30% rule firms: {pre_tcja_30_avg:.2f} bps")
print(f"Pre-TCJA average interest spread for loss rule firms: {pre_tcja_loss_avg:.2f} bps")

# Filter the dataframe for the required conditions

# generate ffrate for each year for tranche_level_ds_compa in a new column
tranche_level_ds_compa['ffrate'] = tranche_level_ds_compa['year'].map({
    2014: 0.54,
    2015: 0.55,
    2016: 0.49,
    2017: 1.1962,
    2018: 2.189575,
    2019: 2.352531051,
    2020: 0.404468127,
    2021: 0.098618142,
    2022: 1.789030825,
    2023: 5.228819341
})
tranche_level_ds_compa['ffrate'] = tranche_level_ds_compa['ffrate'] * 100

tranche_level_ds_compa['total_bps'] = tranche_level_ds_compa['margin_bps'] + tranche_level_ds_compa['ffrate']

filtered_df = tranche_level_ds_compa[(tranche_level_ds_compa['year'] <= 2017) & (tranche_level_ds_compa['excess_interest_loss'] == 1)]

# Calculate the average margin_bps
average_margin_bps = filtered_df['margin_bps'].mean()
average_total_bps = filtered_df['total_bps'].mean()

print(f"Average margin_bps for year <= 2017 and excess_interest_loss == 1: {average_margin_bps}")
print(f"Average total_rate for year <= 2017 and excess_interest_loss == 1: {average_total_bps}")

print("Summary statistics completed")
