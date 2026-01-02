import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import re

# Set up paths
overleaf_dir = "/Users/zrsong/MIT Dropbox/Zirui Song/Apps/Overleaf/Tax Incidence and Loan Contract Terms"
tabdir = os.path.join(overleaf_dir, 'Tables')
figdir = os.path.join(overleaf_dir, 'Figures')

# Ensure output directory exists
os.makedirs(figdir, exist_ok=True)

# Read the CSV file
csv_file = os.path.join(tabdir, 'margin_ie_excess_dynamic.csv')

if not os.path.exists(csv_file):
    raise FileNotFoundError(f"CSV file not found: {csv_file}")

# Read CSV - esttab mat() output has variable names in first column (as index or first column)
try:
    # Try reading with index_col=0 first (most common format from esttab)
    df = pd.read_csv(csv_file, index_col=0)
    df.reset_index(inplace=True)
    df.columns = ['variable'] + [df.columns[i] for i in range(1, len(df.columns))]
except:
    # If that fails, read normally
    df = pd.read_csv(csv_file)
    if df.columns[0] in ['Unnamed: 0', '0']:
        df.rename(columns={df.columns[0]: 'variable'}, inplace=True)

# Ensure we have at least 3 columns: variable, coefficient, standard error
if len(df.columns) < 3:
    raise ValueError(f"Expected at least 3 columns (variable, coefficient, SE). Found {len(df.columns)}")

# Rename columns to standard names
df.columns = ['variable', 'y1', 'c1'] + list(df.columns[3:])

# Clean up Excel CSV format (="..." strings)
# Remove ="" wrappers if present
for col in ['variable', 'y1', 'c1']:
    if col in df.columns:
        df[col] = df[col].astype(str).str.replace(r'^="|"$', '', regex=True).str.strip()

# Convert y1 and c1 to numeric (handle any string formatting issues)
df['y1'] = pd.to_numeric(df['y1'], errors='coerce')
df['c1'] = pd.to_numeric(df['c1'], errors='coerce')

# Filter for excess_interest_scaled_year_* variables
df_dynamic = df[df['variable'].str.contains('excess_interest_scaled_year_', na=False)].copy()

# Drop rows where we couldn't convert to numeric
df_dynamic = df_dynamic.dropna(subset=['y1', 'c1'])

if len(df_dynamic) == 0:
    raise ValueError("No dynamic coefficient data found. Check CSV file and filtering logic.")

# Extract year from variable name
df_dynamic['year'] = df_dynamic['variable'].str.extract(r'excess_interest_scaled_year_(\d{4})').astype(int)

# Drop any rows where year extraction failed
df_dynamic = df_dynamic.dropna(subset=['year'])

# Sort by year
df_dynamic = df_dynamic.sort_values('year')

# Calculate 95% confidence intervals (1.96 * standard error)
df_dynamic['ci_lower'] = df_dynamic['y1'] - 1.96 * df_dynamic['c1']
df_dynamic['ci_upper'] = df_dynamic['y1'] + 1.96 * df_dynamic['c1']

# Create figure
fig, ax = plt.subplots(figsize=(12, 8))

# Identify hold-out year (2017)
holdout_year = 2017
df_regular = df_dynamic[df_dynamic['year'] != holdout_year].copy()
df_holdout = df_dynamic[df_dynamic['year'] == holdout_year].copy()

# Plot all years (including 2017 if it exists) with the same style
# If 2017 is in the data, include it with regular years
if len(df_holdout) > 0:
    # 2017 exists in data - include it with regular years
    ax.errorbar(df_dynamic['year'], df_dynamic['y1'], 
                yerr=[df_dynamic['y1'] - df_dynamic['ci_lower'], 
                      df_dynamic['ci_upper'] - df_dynamic['y1']],
                fmt='o', capsize=5, capthick=2, markersize=8,
                label='Dynamic Coefficients with 95% Confidence Interval', color='steelblue')
else:
    # 2017 is not in data - plot years before and after separately to avoid connecting across gap
    df_pre = df_regular[df_regular['year'] < holdout_year].copy()
    df_post = df_regular[df_regular['year'] > holdout_year].copy()
    
    # Plot pre-2017 years
    if len(df_pre) > 0:
        ax.errorbar(df_pre['year'], df_pre['y1'], 
                    yerr=[df_pre['y1'] - df_pre['ci_lower'], 
                          df_pre['ci_upper'] - df_pre['y1']],
                    fmt='o', capsize=5, capthick=2, markersize=8,
                    label='Dynamic Coefficients with 95% Confidence Interval', color='steelblue')
    
    # Plot post-2017 years (on same plot, so no duplicate label)
    if len(df_post) > 0:
        ax.errorbar(df_post['year'], df_post['y1'], 
                    yerr=[df_post['y1'] - df_post['ci_lower'], 
                          df_post['ci_upper'] - df_post['y1']],
                    fmt='o', capsize=5, capthick=2, markersize=8,
                    color='steelblue', label='')
    
    # Add 2017 as a regular blue dot (no error bars since no data, no legend entry)
    ax.plot(holdout_year, 0, 'o', markersize=8, color='steelblue', 
            markerfacecolor='steelblue', markeredgecolor='steelblue', zorder=5)

# Add horizontal line at y=0 for reference
ax.axhline(y=0, color='black', linestyle='--', linewidth=1, alpha=0.5)

# Add vertical line at December 2017 (TCJA implementation - slightly left of 2018)
tcja_date = 2017.92  # December 2017 (0.92 represents ~92% through the year)
ax.axvline(x=tcja_date, color='gray', linestyle=':', linewidth=1.5, alpha=0.7, label='TCJA Implementation (Dec 2017)')

# Formatting
ax.set_xlabel('Year', fontsize=14, fontweight='bold')
ax.set_ylabel('Coefficient (Basis Points)', fontsize=14, fontweight='bold')
ax.set_title('Dynamic Treatment Effects: Excess Interest Expense on Interest Spread (Basis Points)', 
             fontsize=16, fontweight='bold', pad=20)

# Set x-axis to show all years, including 2017 if it's missing
all_years = sorted(df_dynamic['year'].unique())
# Ensure 2017 is included in x-axis ticks even if not in data
if holdout_year not in all_years:
    all_years = sorted(list(all_years) + [holdout_year])
ax.set_xticks(all_years)
ax.set_xticklabels(all_years, rotation=45, ha='right')

# Add grid for better readability
ax.grid(True, alpha=0.3, linestyle='--')

# Add legend
ax.legend(loc='best', fontsize=12, framealpha=0.9)

# Adjust layout to avoid clipping
try:
    plt.tight_layout()
except:
    # If tight_layout fails, use manual adjustment
    plt.subplots_adjust(left=0.1, right=0.95, top=0.93, bottom=0.15)

# Save figure
output_file = os.path.join(figdir, 'margin_ie_excess_dynamic.png')
plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='white')
print(f"Figure saved to: {output_file}")

# Also save as PDF for publication
output_file_pdf = os.path.join(figdir, 'margin_ie_excess_dynamic.pdf')
plt.savefig(output_file_pdf, bbox_inches='tight', facecolor='white')
print(f"Figure saved to: {output_file_pdf}")

plt.close()

# Print summary statistics
print("\nDynamic Coefficients Summary:")
print("=" * 60)
print(f"{'Year':<10} {'Coefficient':<15} {'Std Error':<15} {'95% CI':<25}")
print("=" * 60)
for _, row in df_dynamic.iterrows():
    print(f"{int(row['year']):<10} {row['y1']:>10.4f}     {row['c1']:>10.4f}     [{row['ci_lower']:>8.4f}, {row['ci_upper']:>8.4f}]")
print("=" * 60)

####################
# 2014 Hold-out Plot
####################

# Read the CSV file (2014 hold-out version)
csv_file_2014 = os.path.join(tabdir, 'margin_ie_excess_dynamic_2014holdout.csv')

if os.path.exists(csv_file_2014):
    # Read CSV - esttab mat() output has variable names in first column (as index or first column)
    try:
        # Try reading with index_col=0 first (most common format from esttab)
        df_2014 = pd.read_csv(csv_file_2014, index_col=0)
        df_2014.reset_index(inplace=True)
        df_2014.columns = ['variable'] + [df_2014.columns[i] for i in range(1, len(df_2014.columns))]
    except:
        # If that fails, read normally
        df_2014 = pd.read_csv(csv_file_2014)
        if df_2014.columns[0] in ['Unnamed: 0', '0']:
            df_2014.rename(columns={df_2014.columns[0]: 'variable'}, inplace=True)

    # Ensure we have at least 3 columns: variable, coefficient, standard error
    if len(df_2014.columns) >= 3:
        # Rename columns to standard names
        df_2014.columns = ['variable', 'y1', 'c1'] + list(df_2014.columns[3:])

        # Clean up Excel CSV format (="..." strings)
        # Remove ="" wrappers if present
        for col in ['variable', 'y1', 'c1']:
            if col in df_2014.columns:
                df_2014[col] = df_2014[col].astype(str).str.replace(r'^="|"$', '', regex=True).str.strip()

        # Convert y1 and c1 to numeric (handle any string formatting issues)
        df_2014['y1'] = pd.to_numeric(df_2014['y1'], errors='coerce')
        df_2014['c1'] = pd.to_numeric(df_2014['c1'], errors='coerce')

        # Filter for excess_interest_scaled_year_* variables
        df_dynamic_2014 = df_2014[df_2014['variable'].str.contains('excess_interest_scaled_year_', na=False)].copy()

        # Drop rows where we couldn't convert to numeric
        df_dynamic_2014 = df_dynamic_2014.dropna(subset=['y1', 'c1'])

        if len(df_dynamic_2014) > 0:
            # Extract year from variable name
            df_dynamic_2014['year'] = df_dynamic_2014['variable'].str.extract(r'excess_interest_scaled_year_(\d{4})').astype(int)

            # Drop any rows where year extraction failed
            df_dynamic_2014 = df_dynamic_2014.dropna(subset=['year'])

            # Sort by year
            df_dynamic_2014 = df_dynamic_2014.sort_values('year')

            # Calculate 95% confidence intervals (1.96 * standard error)
            df_dynamic_2014['ci_lower'] = df_dynamic_2014['y1'] - 1.96 * df_dynamic_2014['c1']
            df_dynamic_2014['ci_upper'] = df_dynamic_2014['y1'] + 1.96 * df_dynamic_2014['c1']

            # Create figure
            fig, ax = plt.subplots(figsize=(12, 8))

            # Identify hold-out year (2014)
            holdout_year_2014 = 2014
            df_regular_2014 = df_dynamic_2014[df_dynamic_2014['year'] != holdout_year_2014].copy()
            df_holdout_2014 = df_dynamic_2014[df_dynamic_2014['year'] == holdout_year_2014].copy()

            # Plot all years (including 2014 if it exists) with the same style
            # If 2014 is in the data, include it with regular years
            if len(df_holdout_2014) > 0:
                # 2014 exists in data - include it with regular years
                ax.errorbar(df_dynamic_2014['year'], df_dynamic_2014['y1'], 
                            yerr=[df_dynamic_2014['y1'] - df_dynamic_2014['ci_lower'], 
                                  df_dynamic_2014['ci_upper'] - df_dynamic_2014['y1']],
                            fmt='o', capsize=5, capthick=2, markersize=8,
                            label='Dynamic Coefficients with 95% Confidence Interval', color='steelblue')
            else:
                # 2014 is not in data - plot years before and after separately to avoid connecting across gap
                df_pre_2014 = df_regular_2014[df_regular_2014['year'] < holdout_year_2014].copy()
                df_post_2014 = df_regular_2014[df_regular_2014['year'] > holdout_year_2014].copy()
                
                # Plot pre-2014 years (should be none, but handle it)
                if len(df_pre_2014) > 0:
                    ax.errorbar(df_pre_2014['year'], df_pre_2014['y1'], 
                                yerr=[df_pre_2014['y1'] - df_pre_2014['ci_lower'], 
                                      df_pre_2014['ci_upper'] - df_pre_2014['y1']],
                                fmt='o', capsize=5, capthick=2, markersize=8,
                                label='Dynamic Coefficients with 95% Confidence Interval', color='steelblue')
                
                # Plot post-2014 years (on same plot, so no duplicate label)
                if len(df_post_2014) > 0:
                    ax.errorbar(df_post_2014['year'], df_post_2014['y1'], 
                                yerr=[df_post_2014['y1'] - df_post_2014['ci_lower'], 
                                      df_post_2014['ci_upper'] - df_post_2014['y1']],
                                fmt='o', capsize=5, capthick=2, markersize=8,
                                color='steelblue', label='Dynamic Coefficients with 95% Confidence Interval' if len(df_pre_2014) == 0 else '')
                
                # Add 2014 as a regular blue dot (no error bars since no data, no legend entry)
                ax.plot(holdout_year_2014, 0, 'o', markersize=8, color='steelblue', 
                        markerfacecolor='steelblue', markeredgecolor='steelblue', zorder=5)

            # Add horizontal line at y=0 for reference
            ax.axhline(y=0, color='black', linestyle='--', linewidth=1, alpha=0.5)

            # Add vertical line at December 2017 (TCJA implementation - slightly left of 2018)
            tcja_date = 2017.92  # December 2017 (0.92 represents ~92% through the year)
            ax.axvline(x=tcja_date, color='gray', linestyle=':', linewidth=1.5, alpha=0.7, label='TCJA Implementation (Dec 2017)')

            # Formatting
            ax.set_xlabel('Year', fontsize=14, fontweight='bold')
            ax.set_ylabel('Coefficient (Basis Points)', fontsize=14, fontweight='bold')
            ax.set_title('Dynamic Treatment Effects: Excess Interest Expense on Interest Spread (Basis Points)\n(2014 Hold-out)', 
                         fontsize=16, fontweight='bold', pad=20)

            # Set x-axis to show all years, including 2014 if it's missing
            all_years_2014 = sorted(df_dynamic_2014['year'].unique())
            # Ensure 2014 is included in x-axis ticks even if not in data
            if holdout_year_2014 not in all_years_2014:
                all_years_2014 = sorted(list(all_years_2014) + [holdout_year_2014])
            ax.set_xticks(all_years_2014)
            ax.set_xticklabels(all_years_2014, rotation=45, ha='right')

            # Add grid for better readability
            ax.grid(True, alpha=0.3, linestyle='--')

            # Add legend
            ax.legend(loc='best', fontsize=12, framealpha=0.9)

            # Adjust layout to avoid clipping
            try:
                plt.tight_layout()
            except:
                # If tight_layout fails, use manual adjustment
                plt.subplots_adjust(left=0.1, right=0.95, top=0.93, bottom=0.15)

            # Save figure
            output_file_2014 = os.path.join(figdir, 'margin_ie_excess_dynamic_2014holdout.png')
            plt.savefig(output_file_2014, dpi=300, bbox_inches='tight', facecolor='white')
            print(f"Figure saved to: {output_file_2014}")

            # Also save as PDF for publication
            output_file_pdf_2014 = os.path.join(figdir, 'margin_ie_excess_dynamic_2014holdout.pdf')
            plt.savefig(output_file_pdf_2014, bbox_inches='tight', facecolor='white')
            print(f"Figure saved to: {output_file_pdf_2014}")

            plt.close()

            # Print summary statistics
            print("\nDynamic Coefficients Summary (2014 Hold-out):")
            print("=" * 60)
            print(f"{'Year':<10} {'Coefficient':<15} {'Std Error':<15} {'95% CI':<25}")
            print("=" * 60)
            for _, row in df_dynamic_2014.iterrows():
                print(f"{int(row['year']):<10} {row['y1']:>10.4f}     {row['c1']:>10.4f}     [{row['ci_lower']:>8.4f}, {row['ci_upper']:>8.4f}]")
            print("=" * 60)
else:
    print(f"\nNote: {csv_file_2014} not found. Skipping 2014 hold-out plot.")


