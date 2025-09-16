import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
from tabulate import tabulate

# Ensure output directory exists
processed_dir = os.path.join('..', '..', '3. Data', 'Processed')
os.makedirs(processed_dir, exist_ok=True)
overleaf_dir = "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Terms"
os.makedirs(os.path.join(overleaf_dir, 'Tables'), exist_ok=True)
os.makedirs(os.path.join(overleaf_dir, 'Figures'), exist_ok=True)

# Read in the processed data with all variables already generated and filtered
tranche_level_ds_compa = pd.read_csv(os.path.join(processed_dir, 'tranche_level_ds_compa_all.csv'))

variable_labels_groups = {
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

## Figures

excess_interest_30 = tranche_level_ds_compa.groupby('year')['excess_interest_30'].sum()
excess_interest_loss = tranche_level_ds_compa.groupby('year')['excess_interest_loss'].sum()
# Create a DataFrame with the number of loans with No excess interest and No excess loss in each year
no_excess_interest_30_loss = tranche_level_ds_compa.groupby('year')['excess_interest_30'].count() - excess_interest_30 - excess_interest_loss

# plot the number of loans with excess_interest_30 == 1 and excess_loss == 1 and all the rest in each year
plt.figure(figsize=(10, 6))
plt.plot(excess_interest_30.index, excess_interest_30.values, label='Excess Interest (30% Rule)', linestyle='-', marker='o')
plt.plot(excess_interest_loss.index, excess_interest_loss.values, label='Excess Interest (Loss)', linestyle='--', marker='x')
plt.plot(no_excess_interest_30_loss.index, no_excess_interest_30_loss.values, label='No Excess Interest', linestyle='-.', marker='s')
plt.xlabel('Year')
plt.ylabel('Number of Loans')
plt.legend()
plt.grid(True, linestyle='--', linewidth=0.5)
plt.xticks(sorted(tranche_level_ds_compa['year'].unique()))  # Show all years on x-axis
sns.despine(top=True, right=True)
plt.savefig(os.path.join(overleaf_dir, 'Figures/loancounts_by_excess_interest.png'), dpi=300)
plt.show()

# plot the histogram of winsorized interest_expense_by_ebitda for all deals
interest_expense_winsorized = tranche_level_ds_compa['interest_expense_by_ebitda'].clip(tranche_level_ds_compa['interest_expense_by_ebitda'].quantile(0.01), tranche_level_ds_compa['interest_expense_by_ebitda'].quantile(0.99))
plt.figure(figsize=(10, 6))
sns.histplot(interest_expense_winsorized, bins=100, label='All Deals')
plt.axvline(x=0.3, color='r', linestyle='--', label='Threshold (0.3)')
plt.axvline(x=0, color='k', linestyle=':', label='Zero Line')
plt.xlabel('Interest Expense / EBITDA (Winsorized)')
plt.ylabel('Frequency')
plt.legend()
plt.grid(True, linestyle='--', linewidth=0.5)
sns.despine()
plt.savefig(os.path.join(overleaf_dir, 'Figures/ie_ebitda_all_deals.png'), dpi=300)
plt.show()

# Plot for excess_interest_loss == 1
interest_expense_winsorized_loss = tranche_level_ds_compa[tranche_level_ds_compa['excess_interest_loss'] == 1]['interest_expense_by_ebitda_next_1yr'].clip(tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.01), tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.99))
plt.figure(figsize=(10, 6))
sns.histplot(interest_expense_winsorized_loss, bins=100, label='Excess Interest (Loss)')
plt.axvline(x=0.3, color='r', linestyle='--', label='Threshold (0.3)')
plt.axvline(x=0, color='k', linestyle=':', label='Zero Line')
plt.xlabel('Next-Year Interest Expense / EBITDA (Winsorized)')
plt.ylabel('Frequency')
plt.legend()
plt.grid(True, linestyle='--', linewidth=0.5)
sns.despine()
plt.savefig(os.path.join(overleaf_dir, 'Figures/ie_ebitda_excess_interest_loss_deals.png'), dpi=300)
plt.show()

# Plot for excess_interest_30 == 1
# generate excess_interest_30_only = 1 if excess_interest_30 == 1 and excess_interest_loss == 0
interest_expense_winsorized_30 = tranche_level_ds_compa[(tranche_level_ds_compa['excess_interest_30'] == 1) & (tranche_level_ds_compa['excess_interest_loss'] == 0)]['interest_expense_by_ebitda_next_1yr'].clip(tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.01), tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.99))
plt.figure(figsize=(10, 6))
sns.histplot(interest_expense_winsorized_30, bins=100, label='Excess Interest (30% Rule)')
plt.axvline(x=0.3, color='r', linestyle='--', label='Threshold (0.3)')
plt.axvline(x=0, color='k', linestyle=':', label='Zero Line')
plt.xlabel('Next-Year Interest Expense / EBITDA (Winsorized)')
plt.ylabel('Frequency')
plt.legend()
plt.grid(True, linestyle='--', linewidth=0.5)
sns.despine()
plt.savefig(os.path.join(overleaf_dir, 'Figures/ie_ebitda_excess_interest_30_deals.png'), dpi=300)
plt.show()

# Plot for excess_interest_loss == 1
# generate excess_interest_30_only = 1 if excess_interest_30 == 1 and excess_interest_loss == 0
interest_expense_winsorized_30 = tranche_level_ds_compa[(tranche_level_ds_compa['excess_interest_30'] == 0) & (tranche_level_ds_compa['excess_interest_loss'] == 1)]['interest_expense_by_ebitda_next_1yr'].clip(tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.01), tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.99))
plt.figure(figsize=(10, 6))
sns.histplot(interest_expense_winsorized_30, bins=100, label='Excess Interest (Loss Only)')
plt.axvline(x=0.3, color='r', linestyle='--', label='Threshold (0.3)')
plt.axvline(x=0, color='k', linestyle=':', label='Zero Line')
plt.xlabel('Next-Year Interest Expense / EBITDA (Winsorized)')
plt.ylabel('Frequency')
plt.legend()
plt.grid(True, linestyle='--', linewidth=0.5)
sns.despine()
plt.savefig(os.path.join(overleaf_dir, 'Figures/ie_ebitda_excess_interest_loss_only_deals.png'), dpi=300)
plt.show()

unique_tranche_types = tranche_level_ds_compa['tranche_type'].unique()
print(unique_tranche_types)

# Plot for excess_interest_loss == 1
interest_expense_winsorized_loss = tranche_level_ds_compa[tranche_level_ds_compa['excess_interest_loss'] == 1]['interest_expense_by_ebitda_next_1yr'].clip(tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.01), tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.99))

# Plot for excess_interest_30 == 1
interest_expense_winsorized_30 = tranche_level_ds_compa[tranche_level_ds_compa['excess_interest_30'] == 1]['interest_expense_by_ebitda_next_1yr'].clip(tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.01), tranche_level_ds_compa['interest_expense_by_ebitda_next_1yr'].quantile(0.99))

plt.figure(figsize=(10, 6))
sns.histplot(interest_expense_winsorized_loss, bins=100, label='Excess Interest (Loss)', color='blue', alpha=0.5)
sns.histplot(interest_expense_winsorized_30, bins=100, label='Excess Interest (30% Rule)', color='orange', alpha=0.5)
plt.axvline(x=0.3, color='r', linestyle='--', label='Threshold (0.3)')
plt.axvline(x=0, color='k', linestyle=':', label='Zero Line')
plt.xlabel('Next-Year Interest Expense / EBITDA')
plt.ylabel('Frequency')
plt.legend()
plt.grid(True, linestyle='--', linewidth=0.5)
sns.despine()
plt.savefig(os.path.join(overleaf_dir, 'Figures/ie_ebitda_excess_interest_superimposed.png'), dpi=300)
plt.show()

# Create a correlation matrix for the variables in variable_labels_groups
correlation_matrix = tranche_level_ds_compa[variable_labels_groups.keys()].corr()

# Rename the index and columns using the shorter labels
correlation_matrix = correlation_matrix.rename(index=variable_labels_groups, columns=variable_labels_groups)

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

# Also create a heatmap with updated labels and mask the upper triangle
plt.figure(figsize=(14, 12))
correlation_matrix_relabeled = correlation_matrix.rename(index=numbered_labels, columns=numbered_labels)
# Format heatmap annotations to show exactly 2 decimal places
sns.heatmap(correlation_matrix_relabeled, annot=True, cmap='coolwarm', fmt='.2f', 
           linewidths=0.5, mask=mask)
plt.title('Correlation Matrix', fontsize=16)
plt.tight_layout()
plt.savefig(os.path.join(overleaf_dir, 'Figures/correlation_heatmap.png'), dpi=300)

print("Summary Figures generation completed")
