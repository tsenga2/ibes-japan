import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

class ForecastAnalyzer:
    def __init__(self, csv_path):
        """Initialize the analyzer with the CSV file path."""
        self.csv_path = csv_path
        self.df = None
        self.load_data()
    
    def load_data(self):
        """Load and prepare the data."""
        print("Loading data...")
        self.df = pd.read_csv(self.csv_path)
        print(f"Data loaded: {self.df.shape[0]} rows, {self.df.shape[1]} columns")
        
        # Clean the data
        self.df['COUNTRY'] = self.df['COUNTRY'].fillna('Unknown')
        print(f"Years: {self.df['eyear'].min()} - {self.df['eyear'].max()}")
        print(f"Countries: {self.df['COUNTRY'].unique()}")
        print(f"Horizons: {sorted(self.df['horizon'].unique())}")
    
    def summary_statistics(self):
        """Generate summary statistics for the dataset."""
        print("\n=== SUMMARY STATISTICS ===")
        
        # Basic info
        print(f"Dataset shape: {self.df.shape}")
        print(f"Missing values per column:")
        print(self.df.isnull().sum())
        
        # Numerical summary
        print(f"\nNumerical summary:")
        numeric_cols = ['ACTUAL_avg', 'forecast_mean_u4_avg', 'forecast_mean_all_avg', 
                       'disagreement_u4_avg', 'rmse_u4_avg', 'STDEV', 'MEDEST']
        print(self.df[numeric_cols].describe())
        
        return self.df.describe()
    
    def analyze_variable_by_horizon(self, variable_name):
        """
        Create table showing how a variable behaves when horizon gets smaller
        for each country and year.
        """
        print(f"\n=== {variable_name.upper()} BEHAVIOR BY HORIZON ===")
        
        # Create pivot table
        pivot_table = self.df.pivot_table(
            values=variable_name,
            index=['COUNTRY', 'eyear'],
            columns='horizon',
            aggfunc='mean'
        )
        
        # Sort columns by horizon (ascending - smaller horizons first)
        pivot_table = pivot_table.reindex(sorted(pivot_table.columns), axis=1)
        
        print(f"{variable_name} by Horizon - Sample:")
        print(pivot_table.head(10))
        
        # Save to CSV
        output_path = f'{variable_name}_by_horizon_table.csv'
        pivot_table.to_csv(output_path)
        print(f"\nTable saved to: {output_path}")
        
        # Calculate trends (difference between consecutive horizons)
        trend_data = []
        
        for (country, year), row in pivot_table.iterrows():
            if not row.dropna().empty:  # Skip rows with all NaN values
                # Calculate differences between consecutive horizons
                diffs = row.diff()
                avg_change = diffs.mean()
                total_change = row.iloc[-1] - row.iloc[0] if len(row.dropna()) > 1 else np.nan
                
                trend_data.append({
                    'COUNTRY': country,
                    'eyear': year,
                    'avg_change_per_horizon': avg_change,
                    'total_change': total_change
                })
        
        trend_analysis = pd.DataFrame(trend_data).set_index(['COUNTRY', 'eyear'])
        
        print(f"\nTrend Analysis for {variable_name} (Change as horizon decreases):")
        print(trend_analysis.head(10))
        trend_analysis.to_csv(f'{variable_name}_trend_analysis.csv')
        
        return pivot_table, trend_analysis
    
    def forecast_behavior_by_horizon(self):
        """
        Create table showing how forecast_mean_u4_avg behaves when horizon gets smaller
        for each country and year.
        """
        return self.analyze_variable_by_horizon('forecast_mean_u4_avg')
    
    def plot_horizon_behavior(self, countries=None, years=None):
        """Plot forecast behavior across horizons."""
        plt.figure(figsize=(12, 8))
        
        # Filter data if specific countries/years requested
        plot_data = self.df.copy()
        if countries:
            plot_data = plot_data[plot_data['COUNTRY'].isin(countries)]
        if years:
            plot_data = plot_data[plot_data['eyear'].isin(years)]
        
        # Group by horizon and calculate mean
        horizon_means = plot_data.groupby('horizon')['forecast_mean_u4_avg'].mean()
        
        plt.subplot(2, 2, 1)
        plt.plot(horizon_means.index, horizon_means.values, marker='o')
        plt.xlabel('Horizon')
        plt.ylabel('Mean Forecast (U4)')
        plt.title('Average Forecast by Horizon')
        plt.grid(True)
        
        # Box plot by horizon
        plt.subplot(2, 2, 2)
        self.df.boxplot(column='forecast_mean_u4_avg', by='horizon', ax=plt.gca())
        plt.title('Forecast Distribution by Horizon')
        plt.suptitle('')  # Remove default title
        
        # Heatmap for selected countries/years
        plt.subplot(2, 2, 3)
        sample_data = self.df[self.df['COUNTRY'].isin(['Unknown', 'SS'])].head(100)  # Sample for visualization
        pivot_sample = sample_data.pivot_table(
            values='forecast_mean_u4_avg',
            index='eyear',
            columns='horizon',
            aggfunc='mean'
        )
        sns.heatmap(pivot_sample, annot=False, cmap='viridis')
        plt.title('Forecast Heatmap (Sample)')
        
        # Trend over years for different horizons
        plt.subplot(2, 2, 4)
        for horizon in [0, 3, 6, 11]:  # Sample horizons
            horizon_data = self.df[self.df['horizon'] == horizon]
            year_means = horizon_data.groupby('eyear')['forecast_mean_u4_avg'].mean()
            plt.plot(year_means.index, year_means.values, marker='o', label=f'Horizon {horizon}')
        
        plt.xlabel('Year')
        plt.ylabel('Mean Forecast (U4)')
        plt.title('Forecast Trends by Year')
        plt.legend()
        plt.grid(True)
        
        plt.tight_layout()
        plt.savefig('forecast_analysis_plots.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print("Plots saved to: forecast_analysis_plots.png")
    
    def plot_all_variables_behavior(self):
        """Plot behavior of all key variables across horizons."""
        variables = [
            'forecast_mean_u4_avg',
            'forecast_mean_all_avg', 
            'disagreement_u4_avg',
            'rmse_u4_avg'
        ]
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        axes = axes.flatten()
        
        for i, var in enumerate(variables):
            ax = axes[i]
            
            # Group by horizon and calculate mean
            horizon_means = self.df.groupby('horizon')[var].mean()
            
            ax.plot(horizon_means.index, horizon_means.values, marker='o', linewidth=2, markersize=6)
            ax.set_xlabel('Horizon')
            ax.set_ylabel(f'Mean {var}')
            ax.set_title(f'Average {var} by Horizon')
            ax.grid(True, alpha=0.3)
            
            # Add trend line
            from scipy import stats
            if not horizon_means.dropna().empty:
                slope, intercept, r_value, p_value, std_err = stats.linregress(
                    horizon_means.dropna().index, horizon_means.dropna().values
                )
                trend_line = slope * horizon_means.index + intercept
                ax.plot(horizon_means.index, trend_line, '--', alpha=0.7, color='red',
                       label=f'Trend (R²={r_value**2:.3f})')
                ax.legend()
        
        plt.tight_layout()
        plt.savefig('all_variables_analysis_plots.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print("Multi-variable plots saved to: all_variables_analysis_plots.png")
    
    def run_full_analysis(self):
        """Run complete analysis pipeline for all variables."""
        print("Starting full analysis...")
        
        # Summary statistics
        self.summary_statistics()
        
        # Variables to analyze
        variables = [
            'forecast_mean_u4_avg',
            'forecast_mean_all_avg', 
            'disagreement_u4_avg',
            'rmse_u4_avg'
        ]
        
        results = {}
        
        # Analyze each variable
        for var in variables:
            print(f"\n{'='*60}")
            pivot_table, trend_analysis = self.analyze_variable_by_horizon(var)
            results[var] = {'pivot': pivot_table, 'trend': trend_analysis}
        
        # Generate plots for all variables
        self.plot_all_variables_behavior()
        
        print("\n" + "="*60)
        print("=== ANALYSIS COMPLETE ===")
        print("Generated files:")
        for var in variables:
            print(f"- {var}_by_horizon_table.csv")
            print(f"- {var}_trend_analysis.csv")
        print("- all_variables_analysis_plots.png")
        
        return results


def main():
    # Set the path to your CSV file
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    
    # Create analyzer
    analyzer = ForecastAnalyzer(csv_path)
    
    # Run analysis for all variables
    results = analyzer.run_full_analysis()
    
    # Print key findings for each variable
    print("\n" + "="*60)
    print("=== KEY FINDINGS FOR ALL VARIABLES ===")
    
    variables = ['forecast_mean_u4_avg', 'forecast_mean_all_avg', 'disagreement_u4_avg', 'rmse_u4_avg']
    
    for var in variables:
        print(f"\n--- {var.upper()} ---")
        trend_analysis = results[var]['trend']
        print("Countries with most consistent patterns:")
        if not trend_analysis.empty:
            consistent_countries = trend_analysis.groupby(level='COUNTRY')['avg_change_per_horizon'].std().sort_values().head(3)
            print(consistent_countries)
            
            print(f"\nOverall trend patterns:")
            avg_trends = trend_analysis['avg_change_per_horizon'].describe()
            print(f"  Mean change per horizon: {avg_trends['mean']:.4f}")
            print(f"  Std of changes: {avg_trends['std']:.4f}")
            print(f"  Most increasing: {trend_analysis['avg_change_per_horizon'].max():.4f}")
            print(f"  Most decreasing: {trend_analysis['avg_change_per_horizon'].min():.4f}")


if __name__ == "__main__":
    main()