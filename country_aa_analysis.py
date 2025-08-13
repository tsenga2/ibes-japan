import pandas as pd
import numpy as np

def create_aa_comprehensive_table():
    """Create comprehensive table for country AA with horizon comparisons."""
    
    # Load data
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    print("Loading data...")
    df = pd.read_csv(csv_path)
    df['COUNTRY'] = df['COUNTRY'].fillna('Unknown')
    
    # Filter for country AA
    aa_data = df[df['COUNTRY'] == 'AA'].copy()
    print(f"Country AA data: {aa_data.shape[0]} rows")
    
    if aa_data.empty:
        print("No data found for country AA")
        return None
    
    # Variables to analyze
    variables = {
        'forecast_mean_u4_avg': 'Forecast_U4',
        'forecast_mean_all_avg': 'Forecast_All',
        'disagreement_u4_avg': 'Disagreement_U4',
        'rmse_u4_avg': 'RMSE_U4',
        'STDEV': 'STDEV',
        'MEDEST': 'MEDEST'
    }
    
    # Create comprehensive table
    results = []
    
    # Get all years for country AA
    years = sorted(aa_data['eyear'].unique())
    print(f"Years available for AA: {min(years)} to {max(years)}")
    
    for year in years:
        year_data = aa_data[aa_data['eyear'] == year]
        
        row = {'Year': year}
        
        # For each variable, get horizon 0 and horizon 10 values
        for var, var_name in variables.items():
            h0_data = year_data[year_data['horizon'] == 0][var].iloc[0] if not year_data[year_data['horizon'] == 0].empty else np.nan
            h10_data = year_data[year_data['horizon'] == 10][var].iloc[0] if not year_data[year_data['horizon'] == 10].empty else np.nan
            
            # Add to row
            row[f'{var_name}_H0'] = h0_data
            row[f'{var_name}_H10'] = h10_data
            
            # Calculate difference (H0 - H10)
            if not pd.isna(h0_data) and not pd.isna(h10_data):
                row[f'{var_name}_Diff'] = h0_data - h10_data
            else:
                row[f'{var_name}_Diff'] = np.nan
        
        results.append(row)
    
    # Create DataFrame
    aa_table = pd.DataFrame(results)
    
    # Reorder columns for better readability
    column_order = ['Year']
    for var, var_name in variables.items():
        column_order.extend([f'{var_name}_H10', f'{var_name}_H0', f'{var_name}_Diff'])
    
    aa_table = aa_table[column_order]
    
    # Save to CSV
    output_file = 'country_AA_comprehensive_table.csv'
    aa_table.to_csv(output_file, index=False)
    
    print(f"\n{'='*80}")
    print("COUNTRY AA COMPREHENSIVE TABLE")
    print(f"{'='*80}")
    print(f"Columns explanation:")
    print("- H10: Horizon 10 (long-term forecast)")
    print("- H0: Horizon 0 (short-term forecast)")  
    print("- Diff: H0 - H10 (positive means H0 > H10)")
    print(f"\n{aa_table.to_string(index=False)}")
    
    print(f"\n✅ Saved: {output_file}")
    
    # Summary statistics
    print(f"\n{'='*50}")
    print("SUMMARY STATISTICS FOR AA")
    print(f"{'='*50}")
    
    for var, var_name in variables.items():
        h0_col = f'{var_name}_H0'
        h10_col = f'{var_name}_H10'
        diff_col = f'{var_name}_Diff'
        
        print(f"\n--- {var_name} ---")
        print(f"H0 (short-term):  Mean={aa_table[h0_col].mean():.3f}, Std={aa_table[h0_col].std():.3f}")
        print(f"H10 (long-term):  Mean={aa_table[h10_col].mean():.3f}, Std={aa_table[h10_col].std():.3f}")
        print(f"Difference:       Mean={aa_table[diff_col].mean():.3f}, Std={aa_table[diff_col].std():.3f}")
        
        # Count positive/negative differences
        pos_diff = (aa_table[diff_col] > 0).sum()
        neg_diff = (aa_table[diff_col] < 0).sum()
        print(f"H0 > H10: {pos_diff} years, H0 < H10: {neg_diff} years")
    
    return aa_table

if __name__ == "__main__":
    aa_table = create_aa_comprehensive_table()