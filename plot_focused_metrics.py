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
    df['Year'] = pd.to_datetime(df['Year'], format='%Y')
    return df

def plot_focused_metrics(df):
    """Create focused plots for disagreement, RMSE, and STDEV"""
    
    # Create figure with subplots (3 rows, 2 columns)
    fig, axes = plt.subplots(3, 2, figsize=(15, 18))
    fig.suptitle('Country AA Analysis: Disagreement, RMSE, and STDEV Metrics', 
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
    ax2.plot(df['Year'], df['Disagreement_U4_Diff'], '^-', label='U4 Diff (H10 - H0)', 
             color='purple', linewidth=2, markersize=6)
    ax2.axhline(y=0, color='black', linestyle='--', alpha=0.7, linewidth=1)
    ax2.set_title('Disagreement Difference (H10 - H0)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Difference', fontsize=12)
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Add annotations for extreme values in disagreement difference
    max_disagreement_diff = df.loc[df['Disagreement_U4_Diff'].idxmax()]
    min_disagreement_diff = df.loc[df['Disagreement_U4_Diff'].idxmin()]
    ax2.annotate(f'Max: {max_disagreement_diff["Year"].year}\n({max_disagreement_diff["Disagreement_U4_Diff"]:.3f})', 
                xy=(max_disagreement_diff['Year'], max_disagreement_diff['Disagreement_U4_Diff']),
                xytext=(10, 10), textcoords='offset points',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='yellow', alpha=0.7),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'))
    
    # 3. RMSE Metrics - H10 and H0
    ax3 = axes[1, 0]
    ax3.plot(df['Year'], df['RMSE_U4_H10'], 'o-', label='U4 H10', 
             color='darkblue', linewidth=2, markersize=6)
    ax3.plot(df['Year'], df['RMSE_U4_H0'], 's-', label='U4 H0', 
             color='darkred', linewidth=2, markersize=6)
    ax3.set_title('RMSE: H10 vs H0', fontsize=14, fontweight='bold')
    ax3.set_ylabel('RMSE', fontsize=12)
    ax3.set_xlabel('Year', fontsize=12)
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
    
    # Add annotations for extreme values in RMSE difference
    max_rmse_diff = df.loc[df['RMSE_U4_Diff'].idxmax()]
    min_rmse_diff = df.loc[df['RMSE_U4_Diff'].idxmin()]
    ax4.annotate(f'Min: {min_rmse_diff["Year"].year}\n({min_rmse_diff["RMSE_U4_Diff"]:.3f})', 
                xy=(min_rmse_diff['Year'], min_rmse_diff['RMSE_U4_Diff']),
                xytext=(10, -10), textcoords='offset points',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='lightblue', alpha=0.7),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'))
    
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
    
    # Add annotations for extreme values in STDEV difference
    max_stdev_diff = df.loc[df['STDEV_Diff'].idxmax()]
    min_stdev_diff = df.loc[df['STDEV_Diff'].idxmin()]
    ax6.annotate(f'Max: {max_stdev_diff["Year"].year}\n({max_stdev_diff["STDEV_Diff"]:.3f})', 
                xy=(max_stdev_diff['Year'], max_stdev_diff['STDEV_Diff']),
                xytext=(10, 10), textcoords='offset points',
                bbox=dict(boxstyle='round,pad=0.3', facecolor='lightgreen', alpha=0.7),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'))
    
    plt.tight_layout()
    return fig

def create_summary_statistics(df):
    """Create summary statistics table"""
    
    key_metrics = ['Disagreement_U4_H10', 'Disagreement_U4_H0', 'Disagreement_U4_Diff',
                   'RMSE_U4_H10', 'RMSE_U4_H0', 'RMSE_U4_Diff',
                   'STDEV_H10', 'STDEV_H0', 'STDEV_Diff']
    
    print("\n" + "="*70)
    print("SUMMARY STATISTICS FOR DISAGREEMENT, RMSE, AND STDEV METRICS")
    print("="*70)
    
    summary_stats = df[key_metrics].describe()
    print(summary_stats.round(4))
    
    print("\n" + "="*60)
    print("EXTREME VALUES ANALYSIS")
    print("="*60)
    
    for metric in key_metrics:
        max_val = df.loc[df[metric].idxmax()]
        min_val = df.loc[df[metric].idxmin()]
        print(f"\n{metric}:")
        print(f"  Maximum: {max_val['Year'].year} ({max_val[metric]:.4f})")
        print(f"  Minimum: {min_val['Year'].year} ({min_val[metric]:.4f})")

def plot_trend_analysis(df):
    """Create trend analysis plots"""
    
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

def main():
    """Main function to run the focused analysis"""
    
    try:
        # Load data
        df = load_and_clean_data('country_AA_comprehensive_table.csv')
        print(f"Data loaded successfully. Shape: {df.shape}")
        print(f"Year range: {df['Year'].min().year} - {df['Year'].max().year}")
        
        # Create focused plots
        print("\nCreating focused metric plots...")
        fig1 = plot_focused_metrics(df)
        plt.savefig('disagreement_rmse_analysis.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Create trend analysis
        print("\nCreating trend analysis...")
        fig2 = plot_trend_analysis(df)
        plt.savefig('disagreement_rmse_trends.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        # Print summary statistics
        create_summary_statistics(df)
        
    except FileNotFoundError:
        print("Error: country_AA_comprehensive_table.csv not found in current directory")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
