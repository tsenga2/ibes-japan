import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from matplotlib.gridspec import GridSpec

# Set style for better-looking plots
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

def load_and_clean_data(file_path):
    """Load and clean the CSV data"""
    df = pd.read_csv(file_path)
    df['Year'] = pd.to_datetime(df['Year'], format='%Y')
    return df

def create_comprehensive_plots(df):
    """Create comprehensive time series plots"""
    
    # Create figure with subplots
    fig = plt.figure(figsize=(16, 20))
    gs = GridSpec(4, 2, figure=fig, hspace=0.3, wspace=0.3)
    
    # 1. Forecast Accuracy Comparison (H10 vs H0)
    ax1 = fig.add_subplot(gs[0, :])
    ax1.plot(df['Year'], df['Forecast_U4_H10'], 'o-', label='U4 H10', linewidth=2, markersize=6)
    ax1.plot(df['Year'], df['Forecast_U4_H0'], 's-', label='U4 H0', linewidth=2, markersize=6)
    ax1.plot(df['Year'], df['Forecast_All_H10'], '^-', label='All H10', linewidth=2, markersize=6)
    ax1.plot(df['Year'], df['Forecast_All_H0'], 'd-', label='All H0', linewidth=2, markersize=6)
    ax1.set_title('Forecast Accuracy Over Time', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Forecast Error', fontsize=12)
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # 2. Forecast Differences
    ax2 = fig.add_subplot(gs[1, 0])
    ax2.plot(df['Year'], df['Forecast_U4_Diff'], 'o-', label='U4 Diff', color='blue', linewidth=2)
    ax2.plot(df['Year'], df['Forecast_All_Diff'], 's-', label='All Diff', color='red', linewidth=2)
    ax2.axhline(y=0, color='black', linestyle='--', alpha=0.5)
    ax2.set_title('Forecast Differences (H10 - H0)', fontsize=12, fontweight='bold')
    ax2.set_ylabel('Difference', fontsize=10)
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 3. Disagreement Metrics
    ax3 = fig.add_subplot(gs[1, 1])
    ax3.plot(df['Year'], df['Disagreement_U4_H10'], 'o-', label='U4 H10', linewidth=2)
    ax3.plot(df['Year'], df['Disagreement_U4_H0'], 's-', label='U4 H0', linewidth=2)
    ax3.plot(df['Year'], df['Disagreement_U4_Diff'], '^-', label='U4 Diff', linewidth=2)
    ax3.set_title('Analyst Disagreement Over Time', fontsize=12, fontweight='bold')
    ax3.set_ylabel('Disagreement', fontsize=10)
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # 4. RMSE Metrics
    ax4 = fig.add_subplot(gs[2, 0])
    ax4.plot(df['Year'], df['RMSE_U4_H10'], 'o-', label='U4 H10', linewidth=2)
    ax4.plot(df['Year'], df['RMSE_U4_H0'], 's-', label='U4 H0', linewidth=2)
    ax4.plot(df['Year'], df['RMSE_U4_Diff'], '^-', label='U4 Diff', linewidth=2)
    ax4.set_title('RMSE Over Time', fontsize=12, fontweight='bold')
    ax4.set_ylabel('RMSE', fontsize=10)
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # 5. Heatmap of correlations
    ax5 = fig.add_subplot(gs[2, 1])
    correlation_cols = ['Forecast_U4_H10', 'Forecast_U4_H0', 'Forecast_U4_Diff',
                       'Disagreement_U4_H10', 'Disagreement_U4_H0', 'Disagreement_U4_Diff',
                       'RMSE_U4_H10', 'RMSE_U4_H0', 'RMSE_U4_Diff']
    corr_matrix = df[correlation_cols].corr()
    im = ax5.imshow(corr_matrix, cmap='RdBu_r', aspect='auto', vmin=-1, vmax=1)
    ax5.set_xticks(range(len(correlation_cols)))
    ax5.set_yticks(range(len(correlation_cols)))
    ax5.set_xticklabels([col.replace('_', '\n') for col in correlation_cols], rotation=45, ha='right')
    ax5.set_yticklabels([col.replace('_', '\n') for col in correlation_cols])
    ax5.set_title('Correlation Matrix', fontsize=12, fontweight='bold')
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax5, shrink=0.8)
    cbar.set_label('Correlation Coefficient', fontsize=10)
    
    # 6. Summary statistics over time periods
    ax6 = fig.add_subplot(gs[3, :])
    
    # Define time periods
    df['Period'] = pd.cut(df['Year'].dt.year, 
                         bins=[1999, 2005, 2010, 2015, 2025], 
                         labels=['2000-2005', '2006-2010', '2011-2015', '2016-2024'])
    
    period_stats = df.groupby('Period')[['Forecast_U4_H10', 'Forecast_U4_H0', 
                                        'Disagreement_U4_H10', 'RMSE_U4_H10']].mean()
    
    x_pos = np.arange(len(period_stats))
    width = 0.2
    
    ax6.bar(x_pos - width*1.5, period_stats['Forecast_U4_H10'], width, label='Forecast U4 H10', alpha=0.8)
    ax6.bar(x_pos - width*0.5, period_stats['Forecast_U4_H0'], width, label='Forecast U4 H0', alpha=0.8)
    ax6.bar(x_pos + width*0.5, period_stats['Disagreement_U4_H10'], width, label='Disagreement U4 H10', alpha=0.8)
    ax6.bar(x_pos + width*1.5, period_stats['RMSE_U4_H10'], width, label='RMSE U4 H10', alpha=0.8)
    
    ax6.set_title('Average Metrics by Time Period', fontsize=12, fontweight='bold')
    ax6.set_xlabel('Time Period', fontsize=10)
    ax6.set_ylabel('Average Value', fontsize=10)
    ax6.set_xticks(x_pos)
    ax6.set_xticklabels(period_stats.index)
    ax6.legend()
    ax6.grid(True, alpha=0.3)
    
    plt.tight_layout()
    return fig

def create_individual_plots(df):
    """Create individual detailed plots for each metric"""
    
    metrics = {
        'Forecast': ['Forecast_U4_H10', 'Forecast_U4_H0', 'Forecast_All_H10', 'Forecast_All_H0'],
        'Disagreement': ['Disagreement_U4_H10', 'Disagreement_U4_H0', 'Disagreement_U4_Diff'],
        'RMSE': ['RMSE_U4_H10', 'RMSE_U4_H0', 'RMSE_U4_Diff']
    }
    
    for metric_name, cols in metrics.items():
        fig, ax = plt.subplots(figsize=(12, 6))
        
        for col in cols:
            if col in df.columns:
                ax.plot(df['Year'], df[col], 'o-', label=col.replace('_', ' '), linewidth=2, markersize=6)
        
        ax.set_title(f'{metric_name} Metrics Over Time', fontsize=14, fontweight='bold')
        ax.set_xlabel('Year', fontsize=12)
        ax.set_ylabel(metric_name, fontsize=12)
        ax.legend()
        ax.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(f'{metric_name.lower()}_timeseries.png', dpi=300, bbox_inches='tight')
        plt.show()

def main():
    """Main function to run the analysis"""
    
    # Load data
    try:
        df = load_and_clean_data('country_AA_comprehensive_table.csv')
        print(f"Data loaded successfully. Shape: {df.shape}")
        print(f"Year range: {df['Year'].min().year} - {df['Year'].max().year}")
        print("\nColumns in the dataset:")
        for col in df.columns:
            print(f"  - {col}")
        
        # Create comprehensive plot
        print("\nCreating comprehensive time series plot...")
        fig = create_comprehensive_plots(df)
        plt.savefig('country_aa_comprehensive_timeseries.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Create individual plots
        print("\nCreating individual metric plots...")
        create_individual_plots(df)
        
        # Print summary statistics
        print("\nSummary Statistics:")
        print(df.describe())
        
    except FileNotFoundError:
        print("Error: country_AA_comprehensive_table.csv not found in current directory")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
