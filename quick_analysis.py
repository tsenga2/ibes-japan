import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

def quick_analysis():
    """Quick analysis of all variables."""
    # Load data
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    print("Loading data...")
    df = pd.read_csv(csv_path)
    df['COUNTRY'] = df['COUNTRY'].fillna('Unknown')
    print(f"Data loaded: {df.shape}")
    
    # Variables to analyze
    variables = [
        'forecast_mean_u4_avg',
        'forecast_mean_all_avg', 
        'disagreement_u4_avg',
        'rmse_u4_avg'
    ]
    
    print(f"\nAnalyzing variables: {variables}")
    
    for var in variables:
        print(f"\n{'='*50}")
        print(f"ANALYZING: {var}")
        print(f"{'='*50}")
        
        # Create pivot table
        try:
            pivot_table = df.pivot_table(
                values=var,
                index=['COUNTRY', 'eyear'],
                columns='horizon',
                aggfunc='mean'
            )
            
            # Sort columns
            pivot_table = pivot_table.reindex(sorted(pivot_table.columns), axis=1)
            
            print(f"Pivot table shape: {pivot_table.shape}")
            print("Sample data:")
            print(pivot_table.head(5))
            
            # Save table
            output_file = f'{var}_by_horizon_table.csv'
            pivot_table.to_csv(output_file)
            print(f"✅ Saved: {output_file}")
            
            # Quick trend analysis
            print("\nCalculating trends...")
            trend_results = []
            
            for idx, row in pivot_table.head(100).iterrows():  # Sample first 100 for speed
                if not row.dropna().empty:
                    diffs = row.diff()
                    avg_change = diffs.mean()
                    total_change = row.iloc[-1] - row.iloc[0] if len(row.dropna()) > 1 else np.nan
                    
                    trend_results.append({
                        'COUNTRY': idx[0],
                        'eyear': idx[1],
                        'avg_change_per_horizon': avg_change,
                        'total_change': total_change
                    })
            
            if trend_results:
                trend_df = pd.DataFrame(trend_results)
                trend_file = f'{var}_trend_analysis_sample.csv'
                trend_df.to_csv(trend_file, index=False)
                print(f"✅ Saved: {trend_file}")
                
                print(f"Sample trend statistics:")
                print(f"  Mean change per horizon: {trend_df['avg_change_per_horizon'].mean():.4f}")
                print(f"  Std change per horizon: {trend_df['avg_change_per_horizon'].std():.4f}")
                
        except Exception as e:
            print(f"❌ Error analyzing {var}: {str(e)}")
    
    print(f"\n{'='*60}")
    print("QUICK ANALYSIS COMPLETE!")
    print("Generated files for each variable:")
    print("- [variable]_by_horizon_table.csv")
    print("- [variable]_trend_analysis_sample.csv")

if __name__ == "__main__":
    quick_analysis()