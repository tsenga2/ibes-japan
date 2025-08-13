#!/usr/bin/env python3
"""
Script to calculate means of Disagreement_U4_Diff, RMSE_U4_Diff, and STDEV_Diff 
for various countries from the IBES Japan data.
"""

import pandas as pd
import numpy as np

def load_and_process_data(csv_path):
    """Load data and calculate means by country."""
    
    # Load the data
    print(f"Loading data from: {csv_path}")
    df = pd.read_csv(csv_path)
    
    # Fill missing country values
    df['COUNTRY'] = df['COUNTRY'].fillna('Unknown')
    
    print(f"Total rows: {len(df)}")
    print(f"Unique countries: {sorted(df['COUNTRY'].unique())}")
    
    return df

def calculate_horizon_differences(df):
    """Calculate differences between H0 and H10 for each metric by country and year."""
    
    results = []
    
    # Group by country and year
    for (country, year), group in df.groupby(['COUNTRY', 'eyear']):
        
        # Get H0 and H10 data
        h0_data = group[group['horizon'] == 0]
        h10_data = group[group['horizon'] == 10]
        
        if len(h0_data) == 0 or len(h10_data) == 0:
            continue
            
        # Extract values for each metric
        result_row = {
            'COUNTRY': country,
            'Year': year
        }
        
        metrics = ['disagreement_u4_avg', 'rmse_u4_avg', 'STDEV']
        diff_names = ['Disagreement_U4_Diff', 'RMSE_U4_Diff', 'STDEV_Diff']
        
        for metric, diff_name in zip(metrics, diff_names):
            h0_val = h0_data[metric].iloc[0] if len(h0_data) > 0 and not h0_data[metric].isna().iloc[0] else np.nan
            h10_val = h10_data[metric].iloc[0] if len(h10_data) > 0 and not h10_data[metric].isna().iloc[0] else np.nan
            
            # Calculate difference (H0 - H10)
            if not pd.isna(h0_val) and not pd.isna(h10_val):
                result_row[diff_name] = h0_val - h10_val
            else:
                result_row[diff_name] = np.nan
        
        results.append(result_row)
    
    return pd.DataFrame(results)

def calculate_country_means(diff_df):
    """Calculate mean values for each country."""
    
    print("\n" + "="*60)
    print("CALCULATING MEANS BY COUNTRY")
    print("="*60)
    
    # Group by country and calculate means
    country_means = diff_df.groupby('COUNTRY').agg({
        'Disagreement_U4_Diff': ['mean', 'std', 'count'],
        'RMSE_U4_Diff': ['mean', 'std', 'count'],
        'STDEV_Diff': ['mean', 'std', 'count']
    }).round(4)
    
    # Flatten column names
    country_means.columns = ['_'.join(col).strip() for col in country_means.columns.values]
    
    # Reset index to make COUNTRY a column
    country_means = country_means.reset_index()
    
    return country_means

def print_results(country_means):
    """Print formatted results."""
    
    print("\n" + "="*80)
    print("MEAN VALUES BY COUNTRY")
    print("="*80)
    
    # Sort by country name
    country_means_sorted = country_means.sort_values('COUNTRY')
    
    for _, row in country_means_sorted.iterrows():
        country = row['COUNTRY']
        print(f"\n--- {country} ---")
        
        # Disagreement
        disagr_mean = row['Disagreement_U4_Diff_mean']
        disagr_std = row['Disagreement_U4_Diff_std']
        disagr_count = row['Disagreement_U4_Diff_count']
        print(f"Disagreement_U4_Diff: Mean={disagr_mean:.4f}, Std={disagr_std:.4f}, N={disagr_count}")
        
        # RMSE
        rmse_mean = row['RMSE_U4_Diff_mean']
        rmse_std = row['RMSE_U4_Diff_std']
        rmse_count = row['RMSE_U4_Diff_count']
        print(f"RMSE_U4_Diff:        Mean={rmse_mean:.4f}, Std={rmse_std:.4f}, N={rmse_count}")
        
        # STDEV
        stdev_mean = row['STDEV_Diff_mean']
        stdev_std = row['STDEV_Diff_std']
        stdev_count = row['STDEV_Diff_count']
        print(f"STDEV_Diff:          Mean={stdev_mean:.4f}, Std={stdev_std:.4f}, N={stdev_count}")

def main():
    """Main function to calculate means by country."""
    
    # Path to the data file
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    
    # Load and process data
    df = load_and_process_data(csv_path)
    
    # Calculate differences for each country/year
    print("\nCalculating horizon differences...")
    diff_df = calculate_horizon_differences(df)
    
    if diff_df.empty:
        print("No valid data found for difference calculations.")
        return
    
    print(f"Difference data shape: {diff_df.shape}")
    print(f"Countries with difference data: {sorted(diff_df['COUNTRY'].unique())}")
    
    # Calculate means by country
    country_means = calculate_country_means(diff_df)
    
    # Print results
    print_results(country_means)
    
    # Save results to CSV
    output_file = 'country_means_summary.csv'
    country_means.to_csv(output_file, index=False)
    
    # Also save the detailed differences
    detailed_output_file = 'detailed_differences_by_country_year.csv'
    diff_df.to_csv(detailed_output_file, index=False)
    
    print(f"\n" + "="*60)
    print("FILES SAVED:")
    print("="*60)
    print(f"✅ {output_file}")
    print(f"✅ {detailed_output_file}")
    
    return country_means, diff_df

if __name__ == "__main__":
    country_means, detailed_data = main()