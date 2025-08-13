import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

def create_aa_visualizations():
    """Create comprehensive visualizations for Country AA."""
    
    # Load the AA comprehensive table
    aa_file = 'country_AA_comprehensive_table.csv'
    
    try:
        df = pd.read_csv(aa_file)
        print(f"Loaded AA data: {df.shape}")
    except FileNotFoundError:
        print(f"File {aa_file} not found. Please run country_aa_analysis.py first.")
        return
    
    # Set up the plotting style
    plt.style.use('seaborn-v0_8')
    colors = ['#2E86AB', '#A23B72', '#F18F01', '#C73E1D']
    
    # Create figure with subplots
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Country AA: Horizon Comparisons Over Time (2000-2024)', fontsize=16, fontweight='bold')
    
    # 1. Forecast Means Comparison
    ax1 = axes[0, 0]
    ax1.plot(df['Year'], df['Forecast_U4_H0'], marker='o', linewidth=2, label='H0 (Short-term)', color=colors[0])
    ax1.plot(df['Year'], df['Forecast_U4_H10'], marker='s', linewidth=2, label='H10 (Long-term)', color=colors[1])
    ax1.fill_between(df['Year'], df['Forecast_U4_H0'], df['Forecast_U4_H10'], alpha=0.2, color='gray')
    ax1.set_title('Forecast Mean (U4): H0 vs H10', fontweight='bold')
    ax1.set_xlabel('Year')
    ax1.set_ylabel('Forecast Value')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # 2. Disagreement Comparison  
    ax2 = axes[0, 1]
    ax2.plot(df['Year'], df['Disagreement_U4_H0'], marker='o', linewidth=2, label='H0 (Short-term)', color=colors[0])
    ax2.plot(df['Year'], df['Disagreement_U4_H10'], marker='s', linewidth=2, label='H10 (Long-term)', color=colors[1])
    ax2.fill_between(df['Year'], df['Disagreement_U4_H0'], df['Disagreement_U4_H10'], alpha=0.2, color='gray')
    ax2.set_title('Disagreement (U4): H0 vs H10', fontweight='bold')
    ax2.set_xlabel('Year')
    ax2.set_ylabel('Disagreement Value')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 3. RMSE Comparison
    ax3 = axes[1, 0]
    ax3.plot(df['Year'], df['RMSE_U4_H0'], marker='o', linewidth=2, label='H0 (Short-term)', color=colors[0])
    ax3.plot(df['Year'], df['RMSE_U4_H10'], marker='s', linewidth=2, label='H10 (Long-term)', color=colors[1])
    ax3.fill_between(df['Year'], df['RMSE_U4_H0'], df['RMSE_U4_H10'], alpha=0.2, color='gray')
    ax3.set_title('RMSE (U4): H0 vs H10', fontweight='bold')
    ax3.set_xlabel('Year')
    ax3.set_ylabel('RMSE Value')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # 4. All Differences in One Plot
    ax4 = axes[1, 1]
    ax4.plot(df['Year'], df['Forecast_U4_Diff'], marker='o', linewidth=2, label='Forecast Diff (H0-H10)', color=colors[0])
    ax4.plot(df['Year'], df['Disagreement_U4_Diff'], marker='s', linewidth=2, label='Disagreement Diff (H0-H10)', color=colors[1])
    ax4.plot(df['Year'], df['RMSE_U4_Diff'], marker='^', linewidth=2, label='RMSE Diff (H0-H10)', color=colors[2])
    ax4.axhline(y=0, color='black', linestyle='--', alpha=0.5)
    ax4.set_title('Differences (H0 - H10) Over Time', fontweight='bold')
    ax4.set_xlabel('Year')
    ax4.set_ylabel('Difference Value')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('country_AA_horizon_comparison.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Create a second figure focusing on trends
    fig2, axes2 = plt.subplots(1, 3, figsize=(18, 6))
    fig2.suptitle('Country AA: Detailed Trend Analysis', fontsize=16, fontweight='bold')
    
    # Trend 1: Forecast accuracy over time (inverse RMSE)
    ax2_1 = axes2[0]
    forecast_accuracy_h0 = 1 / (1 + df['RMSE_U4_H0'])  # Higher = better
    forecast_accuracy_h10 = 1 / (1 + df['RMSE_U4_H10'])
    
    ax2_1.plot(df['Year'], forecast_accuracy_h0, marker='o', linewidth=2, label='H0 Accuracy', color=colors[0])
    ax2_1.plot(df['Year'], forecast_accuracy_h10, marker='s', linewidth=2, label='H10 Accuracy', color=colors[1])
    ax2_1.set_title('Forecast Accuracy Over Time', fontweight='bold')
    ax2_1.set_xlabel('Year')
    ax2_1.set_ylabel('Accuracy Score')
    ax2_1.legend()
    ax2_1.grid(True, alpha=0.3)
    
    # Trend 2: Forecast vs Reality Gap
    ax2_2 = axes2[1]
    ax2_2.bar(df['Year'], df['Forecast_U4_Diff'], alpha=0.7, color=colors[2])
    ax2_2.axhline(y=0, color='black', linestyle='-', alpha=0.8)
    ax2_2.set_title('Forecast Horizon Bias (H0 - H10)', fontweight='bold')
    ax2_2.set_xlabel('Year')
    ax2_2.set_ylabel('Forecast Difference')
    ax2_2.grid(True, alpha=0.3)
    
    # Add trend line
    z = np.polyfit(df['Year'], df['Forecast_U4_Diff'], 1)
    p = np.poly1d(z)
    ax2_2.plot(df['Year'], p(df['Year']), "r--", alpha=0.8, label=f'Trend (slope={z[0]:.3f})')
    ax2_2.legend()
    
    # Trend 3: Consensus vs Accuracy
    ax2_3 = axes2[2]
    scatter = ax2_3.scatter(df['Disagreement_U4_H0'], df['RMSE_U4_H0'], 
                           c=df['Year'], cmap='viridis', alpha=0.7, s=60)
    ax2_3.set_title('Consensus vs Accuracy (H0)', fontweight='bold')
    ax2_3.set_xlabel('Disagreement (Higher = Less Consensus)')
    ax2_3.set_ylabel('RMSE (Higher = Less Accurate)')
    ax2_3.grid(True, alpha=0.3)
    
    # Add colorbar for years
    cbar = plt.colorbar(scatter, ax=ax2_3)
    cbar.set_label('Year')
    
    plt.tight_layout()
    plt.savefig('country_AA_trend_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Print summary insights
    print("\n" + "="*60)
    print("VISUAL INSIGHTS FOR COUNTRY AA")
    print("="*60)
    
    # Calculate correlations
    corr_forecast_time = np.corrcoef(df['Year'], df['Forecast_U4_Diff'])[0, 1]
    corr_disagreement_time = np.corrcoef(df['Year'], df['Disagreement_U4_Diff'])[0, 1]
    corr_rmse_time = np.corrcoef(df['Year'], df['RMSE_U4_Diff'])[0, 1]
    
    print(f"\nTrend Correlations with Time:")
    print(f"- Forecast Difference:    {corr_forecast_time:.3f}")
    print(f"- Disagreement Difference: {corr_disagreement_time:.3f}")
    print(f"- RMSE Difference:        {corr_rmse_time:.3f}")
    
    # Volatility analysis
    forecast_volatility = df['Forecast_U4_Diff'].std()
    disagreement_volatility = df['Disagreement_U4_Diff'].std()
    rmse_volatility = df['RMSE_U4_Diff'].std()
    
    print(f"\nVolatility (Standard Deviation):")
    print(f"- Forecast Difference:    {forecast_volatility:.3f}")
    print(f"- Disagreement Difference: {disagreement_volatility:.3f}")
    print(f"- RMSE Difference:        {rmse_volatility:.3f}")
    
    # Extreme years
    max_forecast_diff_year = df.loc[df['Forecast_U4_Diff'].idxmax(), 'Year']
    min_forecast_diff_year = df.loc[df['Forecast_U4_Diff'].idxmin(), 'Year']
    
    print(f"\nExtreme Years:")
    print(f"- Highest forecast difference: {max_forecast_diff_year}")
    print(f"- Lowest forecast difference:  {min_forecast_diff_year}")
    
    print(f"\n✅ Visualizations saved:")
    print(f"- country_AA_horizon_comparison.png")
    print(f"- country_AA_trend_analysis.png")

if __name__ == "__main__":
    create_aa_visualizations()