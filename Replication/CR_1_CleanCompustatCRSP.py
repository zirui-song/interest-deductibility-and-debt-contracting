import wrds
import pandas as pd
import numpy as np
import os
import datetime
import time

# Get the current working directory
script_dir = os.getcwd()

# Set the working directory to the current script's directory (which in this case is already the working directory)
os.chdir(script_dir)

print(f"Working directory is set to: {script_dir}")

# Connect to WRDS
db = wrds.Connection(wrds_username='zrsong')

# Define the start and end dates
start_date = '2009-01-01'
end_date = '2024-06-30'

# Ensure output directory exists
processed_dir = os.path.join('..', '..', '3. Data', 'Processed')
os.makedirs(processed_dir, exist_ok=True)

# Compustat / CRSP
fund_table = 'funda'

varlist = ['conm', 'tic', 'cusip','fyear', 'fyr', 'at','capx', 'ceq', 'cogs', 'csho', 'dlc', 'dlcch','dltt', 'dp', 'ib', 'itcb', 
           'lt', 'mib', 'naicsh', 'ni', 'prstkcc', 'pstk', 'pstkl', 'pstkrv', 're', 'revt', 'sale', 'ebitda', 'dpc', 'oiadp', 'oibdp',
           'seq', 'sich', 'txdb', 'txdi', 'txditc', 'wcapch', 'xint', 'xlr', 'xrd', 'xsga', 'ppegt', 'xrd', 'ebit', 'aqc',
           'act', 'che', 'dltis', 'dltr', 'dvc', 'idit', 'intan', 'lct', 'dclo', 'oancf', 'pi', 'pifo', 'ppent', 'prcc_f', 'tlcf', 'txfo',
           'txdba', 'txdbca', 'txndb']

query = """SELECT gvkey, datadate, {}
           FROM comp.{}
           WHERE datafmt = 'STD'
           AND popsrc = 'D'
           AND indfmt = 'INDL'
           AND consol = 'C'
           AND fyear>=2005;""".format(", ".join(varlist), fund_table)

compa = db.raw_sql(query, date_cols=['datadate'])

del(fund_table, varlist, query)

# Import SIC codes from comp.company
sic_table = 'company'
query = "SELECT gvkey, sic, ipodate FROM comp.company"
sic_codes = db.raw_sql(query)

# Merge SIC codes back to compa dataframe
compa = compa.merge(sic_codes, how='left', on='gvkey')

# all colnames of compa
# check if sic exists
# for each gvkey fyear, keep the one with the highest at
compa = compa.sort_values(['gvkey', 'fyear', 'at'], ascending=[True, True, False])
compa = compa.drop_duplicates(subset=['gvkey', 'fyear'], keep='first')

# change ipodate to date format
compa['ipodate'] = pd.to_datetime(compa['ipodate'])

# drop if at is missing
compa = compa.dropna(subset=['at'])

# drop if xint is missing or negative
compa = compa.dropna(subset=['xint'])
compa = compa[compa['xint'] > 0]

# missing values of ebitda (due to missing dp/oiabp)
compa['ebitda'] = compa['ebitda'].fillna(compa['ebit'] + compa['dp'])
# replace ebitda = pi + xint - idit + dp if ebitda is still missing
compa['ebitda'] = compa['ebitda'].fillna(compa['pi'] + compa['xint'] - compa['idit'] + compa['dp'])
# replace ebit = pi + xint - idit if ebit is still missing
compa['ebit'] = compa['ebit'].fillna(compa['pi'] + compa['xint'] - compa['idit'])

# drop if ebitda is missing
compa = compa.dropna(subset=['ebitda'])

# define profit as EBITDA up till 2021 and EBIT from 2022 onwards (according to Michelle Hanlon's paper)
compa['profit'] = np.where(compa['fyear'] < 2022, compa['ebitda'], compa['ebit'])  

# Remove duplicate columns
compa = compa.loc[:, ~compa.columns.duplicated()]

compa['dclo'] = compa['dclo'].fillna(0)
compa['idit'] = compa['idit'].fillna(0)

# Debt
compa['debt'] = compa['dltt'] + compa['dlc'] - compa['dclo']

# Dividend_payer (NA if dvc is missing)
_mask_na = compa['dvc'].isna()
_ind = (compa['dvc'] > 0)
compa['dividend_payer'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# Excess_interest 30% rule (NA if any input missing)
_mask_na = compa[['xint', 'idit', 'profit']].isna().any(axis=1)
_ind = compa['xint'] > (compa['idit'] + 0.3 * compa['profit'].clip(lower=0))
compa['excess_interest_30'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')
# Excess_interest loss rule (NA if pi missing)
_mask_na = compa['pi'].isna()
_ind = compa['pi'] < 0
compa['excess_interest_loss'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# generete excess_interest_30_prev_3yr and excess_interest_loss_prev_3yr if the excess_interest_30 / excess_interest_loss == 1 at least once in the previous 3 years including the current year excess_interest_30
compa['excess_interest_30_prev_3yr_sum'] = compa.groupby('gvkey')['excess_interest_30'].shift(1) + compa.groupby('gvkey')['excess_interest_30'].shift(2)
# excess_interest_30_prev_3yr = 1 if excess_interest_30 == 1 and excess_interest_30_prev_3yr_sum >= 1
_mask_na = compa['excess_interest_30'].isna() | compa['excess_interest_30_prev_3yr_sum'].isna()
_ind = (compa['excess_interest_30'] == 1) & (compa['excess_interest_30_prev_3yr_sum'] >= 1)
compa['excess_interest_30_prev_3yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_loss_prev_3yr_sum'] = compa.groupby('gvkey')['excess_interest_loss'].shift(1) + compa.groupby('gvkey')['excess_interest_loss'].shift(2)
# excess_interest_loss_prev_3yr = 1 if excess_interest_loss == 1 and excess_interest_loss_prev_3yr_sum >= 1
_mask_na = compa['excess_interest_loss'].isna() | compa['excess_interest_loss_prev_3yr_sum'].isna()
_ind = (compa['excess_interest_loss'] == 1) & (compa['excess_interest_loss_prev_3yr_sum'] >= 1)
compa['excess_interest_loss_prev_3yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# Do the same for the previous 5 years
compa['excess_interest_30_prev_5yr_sum'] = compa.groupby('gvkey')['excess_interest_30'].shift(1) + compa.groupby('gvkey')['excess_interest_30'].shift(2) + compa.groupby('gvkey')['excess_interest_30'].shift(3) + compa.groupby('gvkey')['excess_interest_30'].shift(4)
_mask_na = compa['excess_interest_30'].isna() | compa['excess_interest_30_prev_5yr_sum'].isna()
_ind = (compa['excess_interest_30'] == 1) & (compa['excess_interest_30_prev_5yr_sum'] >= 1)
compa['excess_interest_30_prev_5yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_loss_prev_5yr_sum'] = compa.groupby('gvkey')['excess_interest_loss'].shift(1) + compa.groupby('gvkey')['excess_interest_loss'].shift(2) + compa.groupby('gvkey')['excess_interest_loss'].shift(3) + compa.groupby('gvkey')['excess_interest_loss'].shift(4)
_mask_na = compa['excess_interest_loss'].isna() | compa['excess_interest_loss_prev_5yr_sum'].isna()
_ind = (compa['excess_interest_loss'] == 1) & (compa['excess_interest_loss_prev_5yr_sum'] >= 1)
compa['excess_interest_loss_prev_5yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# replace 5yr measures with 3yr measures if 5yr < 3yr, preserving missing values
_mask_30_prev = (
    compa['excess_interest_30_prev_5yr'].notna() &
    compa['excess_interest_30_prev_3yr'].notna() &
    (compa['excess_interest_30_prev_5yr'] < compa['excess_interest_30_prev_3yr'])
)
compa.loc[_mask_30_prev, 'excess_interest_30_prev_5yr'] = compa.loc[_mask_30_prev, 'excess_interest_30_prev_3yr']

_mask_loss_prev = (
    compa['excess_interest_loss_prev_5yr'].notna() &
    compa['excess_interest_loss_prev_3yr'].notna() &
    (compa['excess_interest_loss_prev_5yr'] < compa['excess_interest_loss_prev_3yr'])
)
compa.loc[_mask_loss_prev, 'excess_interest_loss_prev_5yr'] = compa.loc[_mask_loss_prev, 'excess_interest_loss_prev_3yr']

# generate excess_interest_30_next_1/3/5yr and excess_interest_loss_next_1/3/5yr if the excess_interest_30 / excess_interest_loss == 1 at least once in the next 1/3/5 years including the current year excess_interest_30
compa['excess_interest_30_next_1yr_sum'] = compa.groupby('gvkey')['excess_interest_30'].shift(-1)
_mask_na = compa['excess_interest_30_next_1yr_sum'].isna()
_ind = compa['excess_interest_30_next_1yr_sum'] == 1
compa['excess_interest_30_next_1yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_loss_next_1yr_sum'] = compa.groupby('gvkey')['excess_interest_loss'].shift(-1)
_mask_na = compa['excess_interest_loss_next_1yr_sum'].isna()
_ind = compa['excess_interest_loss_next_1yr_sum'] == 1
compa['excess_interest_loss_next_1yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_30_next_3yr_sum'] = compa.groupby('gvkey')['excess_interest_30'].shift(-2) + compa.groupby('gvkey')['excess_interest_30'].shift(-3)
_mask_na = compa['excess_interest_30_next_1yr'].isna() | compa['excess_interest_30_next_3yr_sum'].isna()
_ind = (compa['excess_interest_30_next_1yr'] == 1) & (compa['excess_interest_30_next_3yr_sum'] >= 1)
compa['excess_interest_30_next_3yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_loss_next_3yr_sum'] = compa.groupby('gvkey')['excess_interest_loss'].shift(-2) + compa.groupby('gvkey')['excess_interest_loss'].shift(-3)
_mask_na = compa['excess_interest_loss_next_1yr'].isna() | compa['excess_interest_loss_next_3yr_sum'].isna()
_ind = (compa['excess_interest_loss_next_1yr'] == 1) & (compa['excess_interest_loss_next_3yr_sum'] >= 1)
compa['excess_interest_loss_next_3yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_30_next_5yr_sum'] = compa.groupby('gvkey')['excess_interest_30'].shift(-2) + compa.groupby('gvkey')['excess_interest_30'].shift(-3) + compa.groupby('gvkey')['excess_interest_30'].shift(-4) + compa.groupby('gvkey')['excess_interest_30'].shift(-5)
_mask_na = compa['excess_interest_30_next_1yr'].isna() | compa['excess_interest_30_next_5yr_sum'].isna()
_ind = (compa['excess_interest_30_next_1yr'] == 1) & (compa['excess_interest_30_next_5yr_sum'] >= 1)
compa['excess_interest_30_next_5yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

compa['excess_interest_loss_next_5yr_sum'] = compa.groupby('gvkey')['excess_interest_loss'].shift(-2) + compa.groupby('gvkey')['excess_interest_loss'].shift(-3) + compa.groupby('gvkey')['excess_interest_loss'].shift(-4) + compa.groupby('gvkey')['excess_interest_loss'].shift(-5)
_mask_na = compa['excess_interest_loss_next_1yr'].isna() | compa['excess_interest_loss_next_5yr_sum'].isna()
_ind = (compa['excess_interest_loss_next_1yr'] == 1) & (compa['excess_interest_loss_next_5yr_sum'] >= 1)
compa['excess_interest_loss_next_5yr'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# replace 5yr measures with 3yr measures if 5yr < 3yr, preserving missing values
_mask_30_next = (
    compa['excess_interest_30_next_5yr'].notna() &
    compa['excess_interest_30_next_3yr'].notna() &
    (compa['excess_interest_30_next_5yr'] < compa['excess_interest_30_next_3yr'])
)
compa.loc[_mask_30_next, 'excess_interest_30_next_5yr'] = compa.loc[_mask_30_next, 'excess_interest_30_next_3yr']

_mask_loss_next = (
    compa['excess_interest_loss_next_5yr'].notna() &
    compa['excess_interest_loss_next_3yr'].notna() &
    (compa['excess_interest_loss_next_5yr'] < compa['excess_interest_loss_next_3yr'])
)
compa.loc[_mask_loss_next, 'excess_interest_loss_next_5yr'] = compa.loc[_mask_loss_next, 'excess_interest_loss_next_3yr']

# Financial deficit (NA if any input missing)
_mask_na = compa[['oancf', 'capx', 'dvc']].isna().any(axis=1)
_ind = (compa['oancf'] - compa['capx'] - compa['dvc']) < 0
compa['financial_deficit'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# Immediate_depletion (NA if any input missing)
_mask_na = compa[['che', 'oancf', 'capx', 'dvc']].isna().any(axis=1)
_ind = (compa['che'] + compa['oancf'] - compa['capx'] - compa['dvc']) < 0
compa['immediate_depletion'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# Interest expense loss rule
compa['interest_expense_loss_rule'] = np.where(
    (compa['pi'] + compa['xint']) <= 0,
    compa['xint'],
    np.where(
        compa['xint'] > (compa['pi'] + compa['xint']),
        compa['xint'] - (compa['pi'] + compa['xint']),
        0
    )
)

# Interest expense 30% rule
compa['interest_expense_30_rule'] = compa['xint'] - compa['interest_expense_loss_rule'] - (compa['idit'] +  0.3 * compa['profit'].clip(lower=0))
# clip lower bound to 0
compa['interest_expense_30_rule'] = compa['interest_expense_30_rule'].clip(lower=0)

# Interest expense not excess
compa['interest_expense_not_excess'] = compa['xint'] - compa['interest_expense_loss_rule'] - compa['interest_expense_30_rule']

# Interest expense total excess
compa['interest_expense_total_excess'] = compa['interest_expense_loss_rule'] + compa['interest_expense_30_rule']
# clip lower bound to 0
compa['interest_expense_total_excess'] = compa['interest_expense_total_excess'].clip(lower=0)

# Investment
compa['investment'] = compa['aqc'] + compa['capx'] + compa['xrd']

# Loss before interest expense (NA if pi or idit missing)
_mask_na = compa[['pi', 'idit']].isna().any(axis=1)
_ind = (compa['pi'] + compa['idit']) < 0
compa['loss_before_interest_expense'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# Market to book
compa['market_to_book'] = (compa['debt'] + compa['pstk'] + (compa['prcc_f'] * compa['csho'])) / compa['at']

# replace txfo and pifo with 0 if missing
compa['txfo'] = compa['txfo'].fillna(0)
compa['pifo'] = compa['pifo'].fillna(0)

# MNC (indicator = 1 if pifo or txfo non-zero)
compa['mnc'] = (compa['pifo'] != 0) | (compa['txfo'] != 0)

# Net interest
compa['net_interest'] = compa['xint'] - compa['idit']

# NOL (NA if tlcf missing)
_mask_na = compa['tlcf'].isna()
_ind = compa['tlcf'] > 0
compa['nol'] = _ind.where(~_mask_na, other=pd.NA).astype('Int64')

# Sales growth
compa['sales_growth'] = (compa['sale'] - compa['sale'].shift(1)) / compa['sale'].shift(1)
# change sales growth to 0 if inf
compa['sales_growth'] = compa['sales_growth'].replace([np.inf, -np.inf], 0)
# clip sales growth to -1 and 1
compa['sales_growth'] = compa['sales_growth'].clip(-1, 1)

# Z-score
compa['z_score'] = (3.3 * compa['pi'] + 1.0 * compa['sale'] + 1.4 * compa['re'] + 1.2 * (compa['act'] - compa['lct'])) / compa['at']

# Delta_DCF
compa['delta_dcf'] = compa['dltis'] - compa['dltr']

# calculate the interest coverage ratio
compa['interest_expense_by_ebitda'] = (compa['xint'] - compa['idit']) / compa['profit']
# describe the interest coverage ratio
compa['interest_expense_by_ebitda'].describe()

# generate next year's interest coverage ratio
compa['interest_expense_by_ebitda_next_1yr'] = compa.groupby('gvkey')['interest_expense_by_ebitda'].shift(-1)

# Define the variables to be imported
crsp_vars = ['cusip', 'permco', 'permno', 'date', 'ret', 'vol', 'shrout', 'prc']

# Define the query to get the annual returns of North American firms
crsp_query = f"""
    SELECT {', '.join(crsp_vars)}
    FROM crsp.msf
    WHERE date >= '{start_date}' AND date <= '{end_date}'
"""

# Execute the query and fetch the data
crspm = db.raw_sql(crsp_query, date_cols=['date'])

# Display the first few rows of the dataframe
print(crspm.head())

# header information from the CRSP file
crsp_hdr_query = """
    SELECT *
    FROM crsp.dsfhdr
"""

# Execute the query and fetch the data
crsp_hdr = db.raw_sql(crsp_hdr_query, date_cols=['date'])

# Display the first few rows of the dataframe
print(crsp_hdr.head())

# merge crspm and crsp_hdr with permno
crspm = crspm.merge(crsp_hdr[['permno', 'dlstcd']], on='permno', how='left')

# sort by permno date
crspm = crspm.sort_values(['permno', 'date'])

# Aggregate the data by permno and year and calculate the buy and hold return over the year as well as the volatility
crspm['year'] = crspm['date'].dt.year

# Display the first few rows of the dataframe
print(crspm.head())

std_ret = crspm.groupby(['permno', 'year'])['ret'].std().reset_index()
buy_and_hold_return = crspm.groupby(['permno', 'year'])['ret'].apply(lambda x: (1 + x).prod() - 1).reset_index()
# merge the buy and hold return and the volatility to the crspm dataframe
crspm = crspm.merge(buy_and_hold_return, on=['permno', 'year'], suffixes=('', '_buy_and_hold'))
crspm = crspm.merge(std_ret, on=['permno', 'year'], suffixes=('', '_vol'))

# aggregate to permno and year level (keep ret_buy_and_hold and ret_vol and dlstcd)
crspa = crspm.groupby(['permno', 'year']).agg({
    'ret_buy_and_hold': 'first',
    'ret_vol': 'first',
    'dlstcd': 'first'
}).reset_index()

# Compustat/CRSP Link Table
ccm_query = """
    SELECT gvkey, lpermno, linktype, linkprim, linkdt, linkenddt
    FROM crsp.ccmxpf_linktable
"""

# Execute the query and fetch the data
ccm = db.raw_sql(ccm_query, date_cols=['linkdt', 'linkenddt'])

# Display the first few rows of the dataframe
print(ccm.head())

# merge crspa and ccm
crspac = crspa.merge(ccm, left_on='permno', right_on='lpermno', how='left')

# keep only the rows where the link date is before the year and the link end date is after the year
# change linkenddt to 2024-12-31 if it is NaT
crspac['linkenddt'] = crspac['linkenddt'].fillna(pd.Timestamp('2024-12-31'))
crspac = crspac[(crspac['year'] >= crspac['linkdt'].dt.year) & (crspac['year'] <= crspac['linkenddt'].dt.year)]

# merge crspac with compa on gvkey (keep everything)
comp_crspa_merged = compa.merge(crspac, left_on=['gvkey', 'fyear'], right_on=['gvkey', 'year'], how='inner')
# drop year
comp_crspa_merged = comp_crspa_merged.drop(columns='year')

# change gvkey to int
comp_crspa_merged['gvkey'] = comp_crspa_merged['gvkey'].astype(int)

# drop if sale < 25 million throughout the sample period (to match the sample in Michelle Hanlon's paper)
# generate largest sale for each gvkey
compa['largest_sale'] = compa.groupby('gvkey')['sale'].transform('max')
# drop if sale < 25 million
compa = compa[compa['largest_sale'] >= 25]

# for each gvkey fyear, sort by ret_buy_and_hold and ret_vol and keep the first one 
comp_crspa_merged = comp_crspa_merged.sort_values(['gvkey', 'fyear', 'ret_buy_and_hold', 'ret_vol'], ascending=[True, True, False, False])
comp_crspa_merged = comp_crspa_merged.drop_duplicates(subset=['gvkey', 'fyear'], keep='first')

# output csv. format
comp_crspa_merged.to_csv(os.path.join(processed_dir, "comp_crspa_merged.csv"), index=False)

print("Compustat/CRSP data cleaning completed and saved to comp_crspa_merged.csv")
