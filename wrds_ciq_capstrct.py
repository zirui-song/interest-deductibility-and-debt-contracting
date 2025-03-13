#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script imports the ciq_capstrct.wrds_summary dataset from WRDS for 2010-2024,
cleans the data, and filters it to keep only gvkeys that are in the sample of
tranche_level_ds_compa from the Dealscan analysis.
"""

import pandas as pd
import numpy as np
import wrds
import os
import pickle
from datetime import datetime

# Connect to WRDS
def connect_to_wrds(username='zrsong'):
    """Connect to the WRDS database"""
    print(f"Connecting to WRDS as {username}...")
    conn = wrds.Connection(wrds_username=username)
    print("Connected successfully!")
    return conn

# Import ciq_capstrct.wrds_summary data
def get_ciq_capstrct_data(conn, start_year=2010, end_year=2024):
    """Query and retrieve ciq_capstrct.wrds_summary data from WRDS"""
    print(f"Fetching ciq_capstrct.wrds_summary data for years {start_year}-{end_year}...")
    
    # Construct query to get data for years 2010-2024
    query = f"""
        SELECT *
        FROM ciq_capstrct.wrds_summary
        WHERE EXTRACT(YEAR FROM filingdate) BETWEEN {start_year} AND {end_year}
    """
    
    # Execute the query
    df = conn.raw_sql(query)
    print(f"Retrieved {len(df)} rows of data.")
    return df

# Clean the data
def clean_ciq_data(df):
    """Clean the ciq_capstrct data"""
    print("Cleaning the data...")
    
    # Make a copy to avoid modifying the original
    df_clean = df.copy()
    
    # Convert date columns to datetime
    date_columns = [col for col in df_clean.columns if 'date' in col.lower()]
    for col in date_columns:
        df_clean[col] = pd.to_datetime(df_clean[col], errors='coerce')
    
    # Handle missing values
    numeric_cols = df_clean.select_dtypes(include=['float64', 'int64']).columns
    for col in numeric_cols:
        # Replace extreme outliers with NaN (optional, adjust as needed)
        # df_clean[col] = df_clean[col].mask(df_clean[col].abs() > df_clean[col].quantile(0.99) * 10)
        
        # For this example, we'll just fill NaNs with 0 for numeric columns
        df_clean[col] = df_clean[col].fillna(0)
    
    # Convert gvkey to string if it's not already
    if 'gvkey' in df_clean.columns:
        df_clean['gvkey'] = df_clean['gvkey'].astype(str)
    
    print(f"Cleaning complete. Shape after cleaning: {df_clean.shape}")
    return df_clean

# Load the gvkeys from the Dealscan analysis
def load_dealscan_gvkeys():
    """
    Load gvkeys from tranche_level_ds_compa dataframe in Dealscan_Analysis.ipynb.
    This function attempts multiple approaches to get the gvkeys.
    """
    print("Attempting to load gvkeys from Dealscan analysis...")
    
    try:
        # Try to read directly from the notebook if it saved variables
        if os.path.exists('Dealscan_Analysis_variables.pkl'):
            with open('Dealscan_Analysis_variables.pkl', 'rb') as f:
                variables = pickle.load(f)
                if 'tranche_level_ds_compa' in variables:
                    gvkeys = variables['tranche_level_ds_compa']['gvkey'].unique().tolist()
                    print(f"Loaded {len(gvkeys)} unique gvkeys from saved variables")
                    return gvkeys
        
        # If that fails, try to extract from Dealscan_Analysis.ipynb
        # First, check if any CSV export of tranche_level_ds_compa exists
        potential_csv_files = [
            'tranche_level_ds_compa.csv',
            'dealscan_compa.csv',
            'dealscan_data.csv'
        ]
        
        for csv_file in potential_csv_files:
            if os.path.exists(csv_file):
                df = pd.read_csv(csv_file)
                if 'gvkey' in df.columns:
                    gvkeys = df['gvkey'].unique().tolist()
                    print(f"Loaded {len(gvkeys)} unique gvkeys from {csv_file}")
                    return gvkeys
        
        # If we couldn't find the data automatically, prompt the user
        print("\nCould not automatically locate the tranche_level_ds_compa data.")
        print("Please manually export the gvkeys from tranche_level_ds_compa in your notebook using:")
        print("tranche_level_ds_compa['gvkey'].unique().tolist()")
        print("Then save them to a file named 'dealscan_gvkeys.csv' or provide the path below.")
        
        # As a fallback, create a simple input mechanism
        gvkeys_file = input("Path to CSV file with gvkeys (or press Enter to look for 'dealscan_gvkeys.csv'): ")
        
        if not gvkeys_file:
            gvkeys_file = 'dealscan_gvkeys.csv'
        
        if os.path.exists(gvkeys_file):
            gvkeys = pd.read_csv(gvkeys_file, header=None).iloc[:, 0].tolist()
            print(f"Loaded {len(gvkeys)} unique gvkeys from {gvkeys_file}")
            return gvkeys
            
        raise FileNotFoundError("Could not find the necessary gvkeys data")
        
    except Exception as e:
        print(f"Error loading gvkeys: {e}")
        print("Using a placeholder function to continue with the script.")
        
        # Create a function that will read gvkeys when called by the main script
        def get_gvkeys_interactively():
            print("\nPlease run the following in your Jupyter notebook:")
            print("tranche_level_ds_compa['gvkey'].unique().tolist()")
            print("Then copy the output and paste it here.")
            
            gvkey_input = input("Paste the list of gvkeys here: ")
            try:
                # Try to evaluate the input as a Python list
                gvkeys = eval(gvkey_input)
                if isinstance(gvkeys, list):
                    print(f"Loaded {len(gvkeys)} unique gvkeys from user input")
                    return gvkeys
            except:
                print("Invalid input. Using sample gvkeys for demonstration.")
                return ['sample_gvkey_1', 'sample_gvkey_2']  # Placeholder
        
        return get_gvkeys_interactively()

# Filter the data to keep only matching gvkeys
def filter_by_gvkeys(df, gvkeys):
    """Filter the dataframe to keep only rows with gvkeys in the provided list"""
    print(f"Filtering data to keep only {len(gvkeys)} gvkeys from Dealscan analysis...")
    
    # Ensure gvkey column is string type for both datasets for proper comparison
    if 'gvkey' in df.columns:
        df['gvkey'] = df['gvkey'].astype(str)
    
    # Filter the dataframe
    gvkeys_str = [str(gvkey) for gvkey in gvkeys]
    filtered_df = df[df['gvkey'].isin(gvkeys_str)]
    
    print(f"Kept {len(filtered_df)} rows after filtering by gvkeys")
    return filtered_df

# Save the filtered data
def save_data(df, filename='ciq_capstrct_filtered.csv'):
    """Save the filtered dataframe to a CSV file"""
    print(f"Saving filtered data to {filename}...")
    df.to_csv(filename, index=False)
    print(f"Data saved successfully to {filename}")
    
    # Also save as pickle for faster loading with pandas
    pickle_filename = filename.replace('.csv', '.pkl')
    df.to_pickle(pickle_filename)
    print(f"Data also saved as pickle to {pickle_filename}")
    
    return filename

def main():
    """Main function to run the entire process"""
    print(f"Starting WRDS ciq_capstrct data import and filtering process at {datetime.now()}")
    
    # Connect to WRDS
    conn = connect_to_wrds()
    
    # Get the data
    ciq_data = get_ciq_capstrct_data(conn)
    
    # Clean the data
    ciq_data_clean = clean_ciq_data(ciq_data)
    
    # Load gvkeys from Dealscan analysis
    dealscan_gvkeys = load_dealscan_gvkeys()
    
    # If dealscan_gvkeys is a function (from the fallback method), call it
    if callable(dealscan_gvkeys):
        dealscan_gvkeys = dealscan_gvkeys()
    
    # Filter data by gvkeys
    filtered_ciq_data = filter_by_gvkeys(ciq_data_clean, dealscan_gvkeys)
    
    # Save the filtered data
    output_file = save_data(filtered_ciq_data)
    
    # Close the WRDS connection
    conn.close()
    print("WRDS connection closed.")
    
    print(f"Process completed at {datetime.now()}")
    print(f"Filtered data saved to {output_file}")
    
    return filtered_ciq_data

if __name__ == "__main__":
    filtered_data = main() 