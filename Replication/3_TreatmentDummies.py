import pandas as pd
import numpy as np
import os

# Ensure output directory exists
processed_dir = os.path.join('..', '..', '3. Data', 'Processed')
os.makedirs(processed_dir, exist_ok=True)

# Read in the processed data with all variables already generated and filtered
tranche_level_ds_compa = pd.read_csv(os.path.join(processed_dir, 'tranche_level_ds_compa_all.csv'))
comp_crspa_merged = pd.read_csv(os.path.join(processed_dir, "comp_crspa_merged.csv"))

### Add different treatment-year dummies

year_dummies = pd.get_dummies(tranche_level_ds_compa['year'], prefix='year', drop_first=False).astype(int)

def output_analysis_dta(definition):
    tranche_level_ds_compa_dta = tranche_level_ds_compa.copy()

    tranche_level_ds_compa_dta['treated'] = (tranche_level_ds_compa_dta[f'excess_interest_30{definition}'] > 0).astype(int)

    # Generated treated_loss = excess_interest_loss = 1
    tranche_level_ds_compa_dta['treated_loss'] = (tranche_level_ds_compa_dta[f'excess_interest_loss{definition}'] > 0).astype(int)

    # post = 1 if year > 2017 (2017 as hold-out period)
    tranche_level_ds_compa_dta['post'] = (tranche_level_ds_compa_dta['year'] > 2017).astype(int)

    # Generate the interaction term
    tranche_level_ds_compa_dta['treated_post'] = tranche_level_ds_compa_dta['treated'] * tranche_level_ds_compa_dta['post']

    # Generate the interaction term for treated loss
    tranche_level_ds_compa_dta['treated_loss_post'] = tranche_level_ds_compa_dta['treated_loss'] * tranche_level_ds_compa_dta['post']

    # Generate interaction terms for each year dummy and the treated_post variable, ensuring integer output
    interactions = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated']).astype(int))

    # Generate interaction terms for each year dummy and the treated_loss_post variable, ensuring integer output
    interactions_loss = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss']).astype(int))

    # Rename the interaction columns to have 'treated_year' as names
    interactions.columns = [f'treated_{col}' for col in year_dummies.columns]

    # Rename the interaction columns to have 'treated_loss_year' as names
    interactions_loss.columns = [f'treated_loss_{col}' for col in year_dummies.columns]

    # Add the year dummies and interaction terms back to the original data frame
    tranche_level_ds_compa_dta = pd.concat([tranche_level_ds_compa_dta, year_dummies, interactions, interactions_loss], axis=1)

    # drop duplicated columns
    tranche_level_ds_compa_dta = tranche_level_ds_compa_dta.loc[:, ~tranche_level_ds_compa_dta.columns.duplicated()]

    # Convert ipodate to string to avoid ValueError
    tranche_level_ds_compa_dta['ipodate'] = tranche_level_ds_compa_dta['ipodate'].astype(str)
    
    # save as .dta with version=117
    tranche_level_ds_compa_dta.to_stata(os.path.join(processed_dir, f'tranche_level_ds_compa{definition}.dta'), version=117)

output_analysis_dta('')
output_analysis_dta('_prev_3yr')
output_analysis_dta('_prev_5yr')

tranche_level_ds_compa_dta = tranche_level_ds_compa.copy()

tranche_level_ds_compa_dta['treated'] = (tranche_level_ds_compa_dta[f'excess_interest_30'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_prev_3yr'] = (tranche_level_ds_compa_dta[f'excess_interest_30_prev_3yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_prev_5yr'] = (tranche_level_ds_compa_dta[f'excess_interest_30_prev_5yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_next_1yr'] = (tranche_level_ds_compa_dta[f'excess_interest_30_next_1yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_next_3yr'] = (tranche_level_ds_compa_dta[f'excess_interest_30_next_3yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_next_5yr'] = (tranche_level_ds_compa_dta[f'excess_interest_30_next_5yr'] > 0).astype(int)

# Generated treated_loss = excess_interest_loss = 1
tranche_level_ds_compa_dta['treated_loss'] = (tranche_level_ds_compa_dta[f'excess_interest_loss'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_loss_prev_3yr'] = (tranche_level_ds_compa_dta[f'excess_interest_loss_prev_3yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_loss_prev_5yr'] = (tranche_level_ds_compa_dta[f'excess_interest_loss_prev_5yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_loss_next_1yr'] = (tranche_level_ds_compa_dta[f'excess_interest_loss_next_1yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_loss_next_3yr'] = (tranche_level_ds_compa_dta[f'excess_interest_loss_next_3yr'] > 0).astype(int)
tranche_level_ds_compa_dta['treated_loss_next_5yr'] = (tranche_level_ds_compa_dta[f'excess_interest_loss_next_5yr'] > 0).astype(int)

# Generate the interaction term
tranche_level_ds_compa_dta['treated_post'] = tranche_level_ds_compa_dta['treated'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_prev_3yr_post'] = tranche_level_ds_compa_dta['treated_prev_3yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_prev_5yr_post'] = tranche_level_ds_compa_dta['treated_prev_5yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_next_1yr_post'] = tranche_level_ds_compa_dta['treated_next_1yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_next_3yr_post'] = tranche_level_ds_compa_dta['treated_next_3yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_next_5yr_post'] = tranche_level_ds_compa_dta['treated_next_5yr'] * tranche_level_ds_compa_dta['post']

# Generate the interaction term for treated loss
tranche_level_ds_compa_dta['treated_loss_post'] = tranche_level_ds_compa_dta['treated_loss'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_loss_prev_3yr_post'] = tranche_level_ds_compa_dta['treated_loss_prev_3yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_loss_prev_5yr_post'] = tranche_level_ds_compa_dta['treated_loss_prev_5yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_loss_next_1yr_post'] = tranche_level_ds_compa_dta['treated_loss_next_1yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_loss_next_3yr_post'] = tranche_level_ds_compa_dta['treated_loss_next_3yr'] * tranche_level_ds_compa_dta['post']
tranche_level_ds_compa_dta['treated_loss_next_5yr_post'] = tranche_level_ds_compa_dta['treated_loss_next_5yr'] * tranche_level_ds_compa_dta['post']

# Generate interaction terms for each year dummy and the treated_post variable, ensuring integer output
interactions = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated']).astype(int))
interactions_prev_3yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_prev_3yr']).astype(int))
interactions_prev_5yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_prev_5yr']).astype(int))
interactions_next_1yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_next_1yr']).astype(int))
interactions_next_3yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_next_3yr']).astype(int))
interactions_next_5yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_next_5yr']).astype(int))

# Generate interaction terms for each year dummy and the treated_loss_post variable, ensuring integer output
interactions_loss = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss']).astype(int))
interactions_loss_prev_3yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss_prev_3yr']).astype(int))
interactions_loss_prev_5yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss_prev_5yr']).astype(int))
interactions_loss_next_1yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss_next_1yr']).astype(int))
interactions_loss_next_3yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss_next_3yr']).astype(int))
interactions_loss_next_5yr = year_dummies.apply(lambda x: (x * tranche_level_ds_compa_dta['treated_loss_next_5yr']).astype(int))

# Rename the interaction columns to have 'treated_year' as names 
interactions.columns = [f'treated_{col}' for col in year_dummies.columns]
interactions_prev_3yr.columns = [f'treated_prev_3yr_{col}' for col in year_dummies.columns]
interactions_prev_5yr.columns = [f'treated_prev_5yr_{col}' for col in year_dummies.columns]
interactions_next_1yr.columns = [f'treated_next_1yr_{col}' for col in year_dummies.columns]
interactions_next_3yr.columns = [f'treated_next_3yr_{col}' for col in year_dummies.columns]
interactions_next_5yr.columns = [f'treated_next_5yr_{col}' for col in year_dummies.columns]

# Rename the interaction columns to have 'treated_loss_year' as names
interactions_loss.columns = [f'treated_loss_{col}' for col in year_dummies.columns]
interactions_loss_prev_3yr.columns = [f'treated_loss_prev_3yr_{col}' for col in year_dummies.columns]
interactions_loss_prev_5yr.columns = [f'treated_loss_prev_5yr_{col}' for col in year_dummies.columns]
interactions_loss_next_1yr.columns = [f'treated_loss_next_1yr_{col}' for col in year_dummies.columns]
interactions_loss_next_3yr.columns = [f'treated_loss_next_3yr_{col}' for col in year_dummies.columns]
interactions_loss_next_5yr.columns = [f'treated_loss_next_5yr_{col}' for col in year_dummies.columns]

# Add the year dummies and interaction terms back to the original data frame
tranche_level_ds_compa_dta = pd.concat([tranche_level_ds_compa_dta, year_dummies, interactions, interactions_prev_3yr, interactions_prev_5yr, interactions_next_1yr, interactions_next_3yr, interactions_next_5yr, 
                                        interactions_loss, interactions_loss_prev_3yr, interactions_loss_prev_5yr, interactions_loss_next_1yr, interactions_loss_next_3yr, interactions_loss_next_5yr], axis=1)

# drop duplicated columns
tranche_level_ds_compa_dta = tranche_level_ds_compa_dta.loc[:, ~tranche_level_ds_compa_dta.columns.duplicated()]

# Convert ipodate to string to avoid ValueError
tranche_level_ds_compa_dta['ipodate'] = tranche_level_ds_compa_dta['ipodate'].astype(str)
    
# save as .dta with version=117
tranche_level_ds_compa_dta.to_stata(os.path.join(processed_dir, 'tranche_level_ds_compa.dta'), version=117)

# Analysis on Persistence of Treatment Groups

# generate list of gvkey from tranche_level_ds_compa
gvkey_list = tranche_level_ds_compa['gvkey'].unique()
# Merge with gvkey_list
gvkey_list = pd.DataFrame(gvkey_list)
# rename columns to gvkey
gvkey_list.columns = ['gvkey']

ds_gvkey_treatment_assignment = comp_crspa_merged.merge(pd.DataFrame(gvkey_list), on='gvkey')
# drop any duplicates in terms of gvkey and fyear
ds_gvkey_treatment_assignment = ds_gvkey_treatment_assignment.drop_duplicates(subset=['gvkey', 'fyear'])

# Generate treated_one if only excess_interest_30 == 1
ds_gvkey_treatment_assignment['treated_one'] = ((ds_gvkey_treatment_assignment['excess_interest_30'] == 1) & (ds_gvkey_treatment_assignment['excess_interest_loss'] == 0)).astype(int)

# Generate treated_two if only excess_interest_loss == 1
ds_gvkey_treatment_assignment['treated_two'] = ((ds_gvkey_treatment_assignment['excess_interest_loss'] == 1) & (ds_gvkey_treatment_assignment['excess_interest_30'] == 0)).astype(int)

# Generate treated_three if both excess_interest_30 == 1 and excess_interest_loss == 1
ds_gvkey_treatment_assignment['treated_three'] = ((ds_gvkey_treatment_assignment['excess_interest_30'] == 1) & (ds_gvkey_treatment_assignment['excess_interest_loss'] == 1)).astype(int)

# Generate control if neither excess_interest_30 == 1 nor excess_interest_loss == 1
ds_gvkey_treatment_assignment['control'] = ((ds_gvkey_treatment_assignment['excess_interest_30'] == 0) & (ds_gvkey_treatment_assignment['excess_interest_loss'] == 0)).astype(int)

# generate next_five_year_excess_interest_30 and next_five_year_excess_interest_loss which are sum of excess_interest_30 and excess_interest_loss in the next 5 years
ds_gvkey_treatment_assignment['next_four_year_excess_interest_30'] = ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_30'].shift(-1) + ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_30'].shift(-2) + ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_30'].shift(-3) + ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_30'].shift(-4) 
ds_gvkey_treatment_assignment['next_four_year_excess_interest_loss'] = ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_loss'].shift(-1) + ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_loss'].shift(-2) + ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_loss'].shift(-3) + ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_loss'].shift(-4)

# generate next_year which is the sum of interest_expense_total_excess in the next 4 years
ds_gvkey_treatment_assignment['next_year_excess_interest_total'] = ds_gvkey_treatment_assignment.groupby('gvkey')['interest_expense_total_excess'].shift(-1).fillna(0)
ds_gvkey_treatment_assignment['next_year_excess_interest_30'] = ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_30'].shift(-1).fillna(0)
ds_gvkey_treatment_assignment['next_year_excess_interest_loss'] = ds_gvkey_treatment_assignment.groupby('gvkey')['excess_interest_loss'].shift(-1).fillna(0)

# scale by total assets
ds_gvkey_treatment_assignment['next_year_excess_interest_total'] = ds_gvkey_treatment_assignment['next_year_excess_interest_total'] / ds_gvkey_treatment_assignment.groupby('gvkey')['xint'].shift(-1)
ds_gvkey_treatment_assignment['next_year_excess_interest_30'] = ds_gvkey_treatment_assignment['next_year_excess_interest_30'] / ds_gvkey_treatment_assignment.groupby('gvkey')['xint'].shift(-1)
ds_gvkey_treatment_assignment['next_year_excess_interest_loss'] = ds_gvkey_treatment_assignment['next_year_excess_interest_loss'] / ds_gvkey_treatment_assignment.groupby('gvkey')['xint'].shift(-1)

# order gvkey fyear next_five_year_excess_interest_30 next_five_year_excess_interest_loss excess_interest_30 excess_interest_loss to be seen in the first columns
ds_gvkey_treatment_assignment = ds_gvkey_treatment_assignment[['gvkey', 'fyear','control', 'treated_one', 'treated_two', 'treated_three', 'next_four_year_excess_interest_30', 'next_four_year_excess_interest_loss', 'excess_interest_30', 'excess_interest_loss'] + [col for col in ds_gvkey_treatment_assignment.columns if col not in ['gvkey', 'fyear', 'control', 'treated_one', 'treated_two', 'treated_three', 'next_four_year_excess_interest_30', 'next_four_year_excess_interest_loss', 'excess_interest_30', 'excess_interest_loss']]]

# generate the upper quartile value of next_four_year_excess_interest_total for each fyear
upper_quartile = ds_gvkey_treatment_assignment.groupby('fyear')['next_year_excess_interest_total'].quantile(0.5).reset_index()
# treated = 1 if next_four_year_excess_interest_total is greater than the upper quartile value and = 0 otherwise
#ds_gvkey_treatment_assignment['treated'] = (ds_gvkey_treatment_assignment['next_year_excess_interest_total'] > ds_gvkey_treatment_assignment['fyear'].map(upper_quartile.set_index('fyear')['next_year_excess_interest_total'])).astype(int)
# treated = 1 if next_four_year_excess_interest_total is greater than 0 and = 0 otherwise
ds_gvkey_treatment_assignment['treated'] = (ds_gvkey_treatment_assignment['next_year_excess_interest_total'] > 0).astype(int)
ds_gvkey_treatment_assignment['treated1'] = (ds_gvkey_treatment_assignment['excess_interest_30'] > 0).astype(int) & (ds_gvkey_treatment_assignment['excess_interest_loss'] == 0)
ds_gvkey_treatment_assignment['treated2'] = (ds_gvkey_treatment_assignment['excess_interest_loss'] > 0).astype(int) & (ds_gvkey_treatment_assignment['excess_interest_30'] == 0)
ds_gvkey_treatment_assignment['treated3'] = (ds_gvkey_treatment_assignment['excess_interest_loss'] > 0).astype(int) & (ds_gvkey_treatment_assignment['excess_interest_30'] > 0)
ds_gvkey_treatment_assignment['control'] = ((ds_gvkey_treatment_assignment['excess_interest_30'] == 0) & (ds_gvkey_treatment_assignment['excess_interest_loss'] == 0)).astype(int)

ds_gvkey_treatment_assignment = ds_gvkey_treatment_assignment[ds_gvkey_treatment_assignment['fyear'] >= 2013]

# save a copy of the data including only gvkey fyear treated variable
ds_gvkey_treatment_assignment.to_stata(os.path.join(processed_dir, 'ds_gvkey_treatment_assignment.dta'), version=117)

print("Treatment dummies and persistence analysis completed")
