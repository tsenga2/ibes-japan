import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set style for better-looking plots
plt.style.use('default')
sns.set_palette("husl")

class CountryAnalyzer:
    def __init__(self, csv_path, country_code='AA'):
        """Initialize the analyzer with the CSV file path and country code."""
        self.csv_path = csv_path
        self.country_code = country_code
        self.country_table = None
        
    def create_comprehensive_table(self):
        """Create comprehensive table for specified country with horizon comparisons."""
        
        print("="*80)
        print(f"STEP 1: CREATING COMPREHENSIVE DATA TABLE FOR COUNTRY {self.country_code}")
        print("="*80)
        
        # Load data
        print("Loading data...")
        df = pd.read_csv(self.csv_path)
        df['COUNTRY'] = df['COUNTRY'].fillna('Unknown')
        
        # Filter for specified country
        country_data = df[df['COUNTRY'] == self.country_code].copy()
        print(f"Country {self.country_code} data: {country_data.shape[0]} rows")
        
        if country_data.empty:
            print(f"No data found for country {self.country_code}")
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
        
        # Get all years for specified country
        years = sorted(country_data['eyear'].unique())
        print(f"Years available for {self.country_code}: {min(years)} to {max(years)}")
        
        for year in years:
            year_data = country_data[country_data['eyear'] == year]
            
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
        self.country_table = pd.DataFrame(results)
        
        # Reorder columns for better readability
        column_order = ['Year']
        for var, var_name in variables.items():
            column_order.extend([f'{var_name}_H10', f'{var_name}_H0', f'{var_name}_Diff'])
        
        self.country_table = self.country_table[column_order]
        
        # Save to CSV
        output_file = f'country_{self.country_code}_comprehensive_table.csv'
        self.country_table.to_csv(output_file, index=False)
        
        print(f"\n✅ Data table saved: {output_file}")
        print(f"Table shape: {self.country_table.shape}")
        
        # Print summary statistics
        self.print_summary_statistics(variables)
        
        return self.country_table
    
    def print_summary_statistics(self, variables):
        """Print summary statistics for all variables."""
        print(f"\n{'='*60}")
        print(f"SUMMARY STATISTICS FOR {self.country_code}")
        print(f"{'='*60}")
        
        for var, var_name in variables.items():
            h0_col = f'{var_name}_H0'
            h10_col = f'{var_name}_H10'
            diff_col = f'{var_name}_Diff'
            
            print(f"\n--- {var_name} ---")
            print(f"H0 (short-term):  Mean={self.country_table[h0_col].mean():.3f}, Std={self.country_table[h0_col].std():.3f}")
            print(f"H10 (long-term):  Mean={self.country_table[h10_col].mean():.3f}, Std={self.country_table[h10_col].std():.3f}")
            print(f"Difference:       Mean={self.country_table[diff_col].mean():.3f}, Std={self.country_table[diff_col].std():.3f}")
            
            # Count positive/negative differences
            pos_diff = (self.country_table[diff_col] > 0).sum()
            neg_diff = (self.country_table[diff_col] < 0).sum()
            print(f"H0 > H10: {pos_diff} years, H0 < H10: {neg_diff} years")
    
    def create_visualizations(self):
        """Create comprehensive visualizations."""
        
        print(f"\n{'='*80}")
        print("STEP 2: CREATING VISUALIZATIONS")
        print("="*80)
        
        if self.country_table is None:
            print("Error: No data table found. Run create_comprehensive_table() first.")
            return
        
        # Prepare data for plotting
        df_plot = self.country_table.copy()
        df_plot['Year'] = pd.to_datetime(df_plot['Year'], format='%Y')
        
        # Create main focused metrics plot
        print("Creating focused metrics plot...")
        fig1 = self.plot_focused_metrics(df_plot)
        plt.savefig(f'country_{self.country_code}_comprehensive_analysis.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Create trend analysis plot
        print("Creating trend analysis plot...")
        fig2 = self.plot_trend_analysis(df_plot)
        plt.savefig(f'country_{self.country_code}_trend_analysis.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Print detailed statistics
        self.print_detailed_statistics(df_plot)
        
        print(f"\n✅ Visualizations saved:")
        print(f"- country_{self.country_code}_comprehensive_analysis.png")
        print(f"- country_{self.country_code}_trend_analysis.png")
    
    def plot_focused_metrics(self, df):
        """Create focused plots for disagreement, RMSE, and STDEV."""
        
        # Create figure with subplots (3 rows, 2 columns)
        fig, axes = plt.subplots(3, 2, figsize=(15, 18))
        fig.suptitle(f'Country {self.country_code} Analysis: Disagreement, RMSE, and STDEV Metrics', 
                     fontsize=16, fontweight='bold')
        
        # 1. Disagreement Metrics - H10 and H0
        ax1 = axes[0, 0]
        ax1.plot(df['Year'], df['Disagreement_U4_H10'], 'o-', label='U4 H10', 
                 color='green', linewidth=2, markersize=6)
        ax1.plot(df['Year'], df['Disagreement_U4_H0'], 's-', label='U4 H0', 
                 color='orange', linewidth=2, markersize=6)
        ax1.set_title('Analyst Disagreement: H10 vs H0', fontsize=14, fontweight='bold')
        ax1.set_ylabel('Disagreement', fontsize=12)
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # 2. Disagreement Difference
        ax2 = axes[0, 1]
        ax2.plot(df['Year'], df['Disagreement_U4_Diff'], '^-', label='U4 Diff (H0 - H10)', 
                 color='purple', linewidth=2, markersize=6)
        ax2.axhline(y=0, color='black', linestyle='--', alpha=0.7, linewidth=1)
        ax2.set_title('Disagreement Difference (H0 - H10)', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Difference', fontsize=12)
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # 3. RMSE Metrics - H10 and H0
        ax3 = axes[1, 0]
        ax3.plot(df['Year'], df['RMSE_U4_H10'], 'o-', label='U4 H10', 
                 color='darkblue', linewidth=2, markersize=6)
        ax3.plot(df['Year'], df['RMSE_U4_H0'], 's-', label='U4 H0', 
                 color='darkred', linewidth=2, markersize=6)
        ax3.set_title('RMSE: H10 vs H0', fontsize=14, fontweight='bold')
        ax3.set_ylabel('RMSE', fontsize=12)
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # 4. RMSE Difference
        ax4 = axes[1, 1]
        ax4.plot(df['Year'], df['RMSE_U4_Diff'], '^-', label='U4 Diff (H0 - H10)', 
                 color='darkgreen', linewidth=2, markersize=6)
        ax4.axhline(y=0, color='black', linestyle='--', alpha=0.7, linewidth=1)
        ax4.set_title('RMSE Difference (H0 - H10)', fontsize=14, fontweight='bold')
        ax4.set_ylabel('Difference', fontsize=12)
        ax4.legend()
        ax4.grid(True, alpha=0.3)
        
        # 5. STDEV Metrics - H10 and H0
        ax5 = axes[2, 0]
        ax5.plot(df['Year'], df['STDEV_H10'], 'o-', label='STDEV H10', 
                 color='purple', linewidth=2, markersize=6)
        ax5.plot(df['Year'], df['STDEV_H0'], 's-', label='STDEV H0', 
                 color='brown', linewidth=2, markersize=6)
        ax5.set_title('Standard Deviation: H10 vs H0', fontsize=14, fontweight='bold')
        ax5.set_ylabel('STDEV', fontsize=12)
        ax5.set_xlabel('Year', fontsize=12)
        ax5.legend()
        ax5.grid(True, alpha=0.3)
        
        # 6. STDEV Difference
        ax6 = axes[2, 1]
        ax6.plot(df['Year'], df['STDEV_Diff'], '^-', label='STDEV Diff (H0 - H10)', 
                 color='darkmagenta', linewidth=2, markersize=6)
        ax6.axhline(y=0, color='black', linestyle='--', alpha=0.7, linewidth=1)
        ax6.set_title('STDEV Difference (H0 - H10)', fontsize=14, fontweight='bold')
        ax6.set_ylabel('Difference', fontsize=12)
        ax6.set_xlabel('Year', fontsize=12)
        ax6.legend()
        ax6.grid(True, alpha=0.3)
        
        plt.tight_layout()
        return fig
    
    def plot_trend_analysis(self, df):
        """Create trend analysis plots."""
        
        fig, axes = plt.subplots(2, 3, figsize=(20, 12))
        fig.suptitle('Trend Analysis: Rolling Averages and Linear Trends', 
                     fontsize=16, fontweight='bold')
        
        metrics = ['Disagreement_U4_H10', 'Disagreement_U4_H0', 'RMSE_U4_H10', 'RMSE_U4_H0', 'STDEV_H10', 'STDEV_H0']
        colors = ['green', 'orange', 'blue', 'red', 'purple', 'brown']
        dark_colors = ['darkgreen', 'darkorange', 'navy', 'darkred', 'darkmagenta', 'saddlebrown']
        titles = ['Disagreement U4 H10', 'Disagreement U4 H0', 'RMSE U4 H10', 'RMSE U4 H0', 'STDEV H10', 'STDEV H0']
        
        for i, (metric, color, dark_color, title) in enumerate(zip(metrics, colors, dark_colors, titles)):
            row = i // 3
            col = i % 3
            ax = axes[row, col]
            
            # Original data
            ax.plot(df['Year'], df[metric], 'o-', color=color, alpha=0.7, 
                    label='Original Data', linewidth=2, markersize=6)
            
            # Rolling average (3-year window)
            rolling_avg = df[metric].rolling(window=3, center=True).mean()
            ax.plot(df['Year'], rolling_avg, 's-', color=dark_color, 
                    label='3-Year Rolling Avg', linewidth=2, markersize=4)
            
            # Linear trend
            x_numeric = np.arange(len(df))
            z = np.polyfit(x_numeric, df[metric], 1)
            p = np.poly1d(z)
            ax.plot(df['Year'], p(x_numeric), '--', color='black', 
                    label=f'Trend (slope: {z[0]:.3f})', linewidth=2)
            
            ax.set_title(title, fontsize=12, fontweight='bold')
            ax.set_ylabel('Value', fontsize=10)
            if row == 1:  # Bottom row
                ax.set_xlabel('Year', fontsize=10)
            ax.legend()
            ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        return fig
    
    def print_detailed_statistics(self, df):
        """Print detailed statistics."""
        
        key_metrics = ['Disagreement_U4_H10', 'Disagreement_U4_H0', 'Disagreement_U4_Diff',
                       'RMSE_U4_H10', 'RMSE_U4_H0', 'RMSE_U4_Diff',
                       'STDEV_H10', 'STDEV_H0', 'STDEV_Diff']
        
        print(f"\n{'='*70}")
        print("DETAILED STATISTICAL SUMMARY")
        print("="*70)
        
        summary_stats = df[key_metrics].describe()
        print(summary_stats.round(4))
        
        print(f"\n{'='*70}")
        print("EXTREME VALUES ANALYSIS")
        print("="*70)
        
        for metric in key_metrics:
            max_val = df.loc[df[metric].idxmax()]
            min_val = df.loc[df[metric].idxmin()]
            print(f"\n{metric}:")
            print(f"  Maximum: {max_val['Year'].year} ({max_val[metric]:.4f})")
            print(f"  Minimum: {min_val['Year'].year} ({min_val[metric]:.4f})")
    
    def run_complete_analysis(self):
        """Run the complete analysis pipeline."""
        print("="*80)
        print(f"COUNTRY {self.country_code} COMPLETE ANALYSIS PIPELINE")
        print("="*80)
        
        # Step 1: Create comprehensive table
        self.create_comprehensive_table()
        
        # Step 2: Create visualizations
        self.create_visualizations()
        
        print(f"\n{'='*80}")
        print("ANALYSIS COMPLETE!")
        print("="*80)
        print("Generated files:")
        print(f"✅ country_{self.country_code}_comprehensive_table.csv")
        print(f"✅ country_{self.country_code}_comprehensive_analysis.png")
        print(f"✅ country_{self.country_code}_trend_analysis.png")
        
        return self.country_table
    
    def list_available_countries(self):
        """List all available countries in the dataset."""
        df = pd.read_csv(self.csv_path)
        # Filter out NaN values and convert to strings for sorting
        countries = df['COUNTRY'].dropna().unique()
        countries = sorted([str(country) for country in countries])
        print(f"\n{'='*60}")
        print("AVAILABLE COUNTRIES IN DATASET")
        print("="*60)
        for i, country in enumerate(countries, 1):
            print(f"{i:2d}. {country}")
        print(f"{'='*60}")
        return countries

def main(country_code='AA'):
    """Main function to run the complete analysis."""
    
    # Set the path to your CSV file
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    
    # Create analyzer
    analyzer = CountryAnalyzer(csv_path, country_code)
    
    # Run complete analysis
    country_table = analyzer.run_complete_analysis()
    
    return country_table

if __name__ == "__main__":
    # Example usage - you can change the country code here
    result_table = main('AA')  # Default to AA, but you can change to any country code