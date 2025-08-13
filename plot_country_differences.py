import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

# Set style for better-looking plots
plt.style.use('default')
sns.set_palette("husl")

def load_and_clean_data(file_path):
    """Load and clean the CSV data"""
    df = pd.read_csv(file_path)
    
    # Remove rows with missing values in any of the three metrics
    metrics = ['Disagreement_U4_Diff_mean', 'RMSE_U4_Diff_mean', 'STDEV_Diff_mean']
    df_clean = df.dropna(subset=metrics)
    
    # Remove countries with very few observations (less than 5)
    df_clean = df_clean[df_clean['Disagreement_U4_Diff_count'] >= 5]
    
    # Load country code mapping first
    country_code_file = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_with_countrycode.csv"
    try:
        country_df = pd.read_csv(country_code_file)
        # Get unique country-code mapping
        country_mapping = country_df[['COUNTRY', 'countrycode']].drop_duplicates()
        country_mapping = country_mapping.dropna()
        
        # Merge with main data
        df_clean = df_clean.merge(country_mapping, on='COUNTRY', how='left')
        
        # Fill missing country codes with original COUNTRY value
        df_clean['countrycode'] = df_clean['countrycode'].fillna(df_clean['COUNTRY'])
        
        print(f"Country code mapping loaded. Found {len(country_mapping)} unique country-code pairs.")
        
    except Exception as e:
        print(f"Warning: Could not load country code mapping: {e}")
        print("Using original COUNTRY codes.")
        df_clean['countrycode'] = df_clean['COUNTRY']
    
    # Remove extreme outliers (South Korea, Hungary, and Greece)
    outliers_to_remove = ['KOR', 'HUN', 'GRC']
    df_clean = df_clean[~df_clean['countrycode'].isin(outliers_to_remove)]
    print(f"Removed outliers: {outliers_to_remove}")
    print(f"Remaining countries: {len(df_clean)}")
    
    return df_clean

def plot_country_differences(df):
    """Create three bar charts for the three _Diff metrics"""
    
    # Create figure with subplots
    fig, axes = plt.subplots(3, 1, figsize=(16, 20))
    fig.suptitle('Country Differences: Disagreement, RMSE, and STDEV (H10 - H0)', 
                 fontsize=16, fontweight='bold')
    
    metrics = ['Disagreement_U4_Diff_mean', 'RMSE_U4_Diff_mean', 'STDEV_Diff_mean']
    titles = ['Disagreement Difference (H10 - H0)', 'RMSE Difference (H10 - H0)', 'STDEV Difference (H10 - H0)']
    colors = ['skyblue', 'lightcoral', 'lightgreen']
    
    for i, (metric, title, color) in enumerate(zip(metrics, titles, colors)):
        ax = axes[i]
        
        # Sort countries by the metric value (descending order)
        df_sorted = df.sort_values(metric, ascending=False)
        
        # Create bar chart
        bars = ax.bar(range(len(df_sorted)), df_sorted[metric], 
                     color=color, alpha=0.7, edgecolor='black', linewidth=0.5)
        
        # Add horizontal line at zero
        ax.axhline(y=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
        
        # Customize the plot
        ax.set_title(title, fontsize=14, fontweight='bold')
        ax.set_ylabel('Difference', fontsize=12)
        ax.set_xlabel('Countries', fontsize=12)
        
        # Set x-axis labels (country codes)
        ax.set_xticks(range(len(df_sorted)))
        ax.set_xticklabels(df_sorted['countrycode'], rotation=45, ha='right', fontsize=10)
        
        # Add value labels on bars
        for j, (bar, value) in enumerate(zip(bars, df_sorted[metric])):
            height = bar.get_height()
            if abs(height) > 0.01:  # Only show labels for significant values
                ax.text(bar.get_x() + bar.get_width()/2., height + (0.01 if height >= 0 else -0.01),
                       f'{value:.3f}', ha='center', va='bottom' if height >= 0 else 'top',
                       fontsize=8, fontweight='bold')
        
        # Add grid
        ax.grid(True, alpha=0.3, axis='y')
        
        # Add count information in the title
        count_col = metric.replace('_mean', '_count')
        total_count = df_sorted[count_col].sum()
        ax.set_title(f'{title}\n(Total observations: {total_count})', fontsize=14, fontweight='bold')
    
    plt.tight_layout()
    return fig

def plot_top_bottom_countries(df):
    """Create a summary plot showing top and bottom countries for each metric"""
    
    fig, axes = plt.subplots(3, 2, figsize=(18, 15))
    fig.suptitle('Top and Bottom Countries by Difference Metrics', 
                 fontsize=16, fontweight='bold')
    
    metrics = ['Disagreement_U4_Diff_mean', 'RMSE_U4_Diff_mean', 'STDEV_Diff_mean']
    titles = ['Disagreement Difference', 'RMSE Difference', 'STDEV Difference']
    colors = ['skyblue', 'lightcoral', 'lightgreen']
    
    for i, (metric, title, color) in enumerate(zip(metrics, titles, colors)):
        # Top 10 countries
        top_countries = df.nlargest(10, metric)
        ax1 = axes[i, 0]
        bars1 = ax1.bar(range(len(top_countries)), top_countries[metric], 
                       color=color, alpha=0.7, edgecolor='black', linewidth=0.5)
        ax1.set_title(f'Top 10 Countries - {title}', fontsize=12, fontweight='bold')
        ax1.set_ylabel('Difference', fontsize=10)
        ax1.set_xticks(range(len(top_countries)))
        ax1.set_xticklabels(top_countries['countrycode'], rotation=45, ha='right', fontsize=9)
        ax1.grid(True, alpha=0.3, axis='y')
        
        # Bottom 10 countries
        bottom_countries = df.nsmallest(10, metric)
        ax2 = axes[i, 1]
        bars2 = ax2.bar(range(len(bottom_countries)), bottom_countries[metric], 
                       color=color, alpha=0.7, edgecolor='black', linewidth=0.5)
        ax2.set_title(f'Bottom 10 Countries - {title}', fontsize=12, fontweight='bold')
        ax2.set_ylabel('Difference', fontsize=10)
        ax2.set_xticks(range(len(bottom_countries)))
        ax2.set_xticklabels(bottom_countries['countrycode'], rotation=45, ha='right', fontsize=9)
        ax2.grid(True, alpha=0.3, axis='y')
        
        # Add horizontal line at zero
        ax1.axhline(y=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
        ax2.axhline(y=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
    
    plt.tight_layout()
    return fig

def plot_scatter_relationships(df):
    """Create scatter plots showing relationships between metrics"""
    
    fig, axes = plt.subplots(1, 2, figsize=(16, 8))
    fig.suptitle('Relationships Between Difference Metrics', 
                 fontsize=16, fontweight='bold')
    
    # 1. Disagreement vs RMSE
    ax1 = axes[0]
    scatter1 = ax1.scatter(df['Disagreement_U4_Diff_mean'], df['RMSE_U4_Diff_mean'], 
                          alpha=0.7, s=100, c='blue', edgecolors='black', linewidth=0.5)
    
    # Add country labels for points with extreme values
    for _, row in df.iterrows():
        # Label points with high absolute values
        if abs(row['Disagreement_U4_Diff_mean']) > 0.1 or abs(row['RMSE_U4_Diff_mean']) > 1:
            ax1.annotate(row['countrycode'], 
                        (row['Disagreement_U4_Diff_mean'], row['RMSE_U4_Diff_mean']),
                        xytext=(5, 5), textcoords='offset points', fontsize=8,
                        bbox=dict(boxstyle='round,pad=0.2', facecolor='yellow', alpha=0.7))
    
    # Add trend line
    z = np.polyfit(df['Disagreement_U4_Diff_mean'], df['RMSE_U4_Diff_mean'], 1)
    p = np.poly1d(z)
    ax1.plot(df['Disagreement_U4_Diff_mean'], p(df['Disagreement_U4_Diff_mean']), 
             "r--", alpha=0.8, linewidth=2)
    
    # Calculate correlation
    correlation = df['Disagreement_U4_Diff_mean'].corr(df['RMSE_U4_Diff_mean'])
    ax1.text(0.05, 0.95, f'Correlation: {correlation:.3f}', 
             transform=ax1.transAxes, fontsize=12, fontweight='bold',
             bbox=dict(boxstyle='round,pad=0.3', facecolor='white', alpha=0.8))
    
    ax1.set_xlabel('Disagreement Difference (H10 - H0)', fontsize=12)
    ax1.set_ylabel('RMSE Difference (H10 - H0)', fontsize=12)
    ax1.set_title('Disagreement vs RMSE Differences', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    
    # Add reference lines
    ax1.axhline(y=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
    ax1.axvline(x=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
    
    # 2. STDEV vs RMSE
    ax2 = axes[1]
    scatter2 = ax2.scatter(df['STDEV_Diff_mean'], df['RMSE_U4_Diff_mean'], 
                          alpha=0.7, s=100, c='green', edgecolors='black', linewidth=0.5)
    
    # Add country labels for points with extreme values
    for _, row in df.iterrows():
        # Label points with high absolute values
        if abs(row['STDEV_Diff_mean']) > 0.5 or abs(row['RMSE_U4_Diff_mean']) > 1:
            ax2.annotate(row['countrycode'], 
                        (row['STDEV_Diff_mean'], row['RMSE_U4_Diff_mean']),
                        xytext=(5, 5), textcoords='offset points', fontsize=8,
                        bbox=dict(boxstyle='round,pad=0.2', facecolor='yellow', alpha=0.7))
    
    # Add trend line
    z = np.polyfit(df['STDEV_Diff_mean'], df['RMSE_U4_Diff_mean'], 1)
    p = np.poly1d(z)
    ax2.plot(df['STDEV_Diff_mean'], p(df['STDEV_Diff_mean']), 
             "r--", alpha=0.8, linewidth=2)
    
    # Calculate correlation
    correlation = df['STDEV_Diff_mean'].corr(df['RMSE_U4_Diff_mean'])
    ax2.text(0.05, 0.95, f'Correlation: {correlation:.3f}', 
             transform=ax2.transAxes, fontsize=12, fontweight='bold',
             bbox=dict(boxstyle='round,pad=0.3', facecolor='white', alpha=0.8))
    
    ax2.set_xlabel('STDEV Difference (H10 - H0)', fontsize=12)
    ax2.set_ylabel('RMSE Difference (H10 - H0)', fontsize=12)
    ax2.set_title('STDEV vs RMSE Differences', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    
    # Add reference lines
    ax2.axhline(y=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
    ax2.axvline(x=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
    
    plt.tight_layout()
    return fig

def create_summary_statistics(df):
    """Create summary statistics for the three metrics"""
    
    metrics = ['Disagreement_U4_Diff_mean', 'RMSE_U4_Diff_mean', 'STDEV_Diff_mean']
    metric_names = ['Disagreement Difference', 'RMSE Difference', 'STDEV Difference']
    
    print("\n" + "="*80)
    print("SUMMARY STATISTICS FOR COUNTRY DIFFERENCES")
    print("="*80)
    
    for metric, name in zip(metrics, metric_names):
        print(f"\n{name}:")
        print(f"  Mean: {df[metric].mean():.4f}")
        print(f"  Median: {df[metric].median():.4f}")
        print(f"  Std Dev: {df[metric].std():.4f}")
        print(f"  Min: {df[metric].min():.4f} ({df.loc[df[metric].idxmin(), 'countrycode']})")
        print(f"  Max: {df[metric].max():.4f} ({df.loc[df[metric].idxmax(), 'countrycode']})")
        print(f"  Countries with positive values: {(df[metric] > 0).sum()}")
        print(f"  Countries with negative values: {(df[metric] < 0).sum()}")
    
    print("\n" + "="*80)
    print("TOP 5 COUNTRIES BY EACH METRIC")
    print("="*80)
    
    for metric, name in zip(metrics, metric_names):
        print(f"\n{name} (Top 5):")
        top_5 = df.nlargest(5, metric)
        for _, row in top_5.iterrows():
            print(f"  {row['countrycode']}: {row[metric]:.4f}")
        
        print(f"\n{name} (Bottom 5):")
        bottom_5 = df.nsmallest(5, metric)
        for _, row in bottom_5.iterrows():
            print(f"  {row['countrycode']}: {row[metric]:.4f}")

def main():
    """Main function to run the country differences analysis"""
    
    try:
        # Load data
        df = load_and_clean_data('country_means_summary.csv')
        print(f"Data loaded successfully. Shape: {df.shape}")
        print(f"Number of countries with sufficient data: {len(df)}")
        
        # Create main bar charts
        print("\nCreating country difference bar charts...")
        fig1 = plot_country_differences(df)
        plt.savefig('country_differences_bar_charts.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Create top/bottom summary
        print("\nCreating top/bottom countries summary...")
        fig2 = plot_top_bottom_countries(df)
        plt.savefig('country_differences_top_bottom.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Create scatter plots
        print("\nCreating scatter plots for relationships...")
        fig3 = plot_scatter_relationships(df)
        plt.savefig('country_differences_scatter_plots.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Print summary statistics
        create_summary_statistics(df)
        
    except FileNotFoundError:
        print("Error: country_means_summary.csv not found in current directory")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
