#!/usr/bin/env python3
"""
Example script showing how to use the CountryAnalyzer for different countries.
"""

from country_aa_complete_analysis import CountryAnalyzer

def analyze_multiple_countries():
    """Example of analyzing multiple countries."""
    
    # Set the path to your CSV file
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    
    # List of countries to analyze
    countries_to_analyze = ['AA', 'AN', 'BL', 'DO', 'EA', 'EB', 'EC', 'ED', 'EE', 'EF']
    
    print("="*80)
    print("MULTI-COUNTRY ANALYSIS EXAMPLE")
    print("="*80)
    
    for country_code in countries_to_analyze:
        print(f"\n{'='*60}")
        print(f"ANALYZING COUNTRY: {country_code}")
        print(f"{'='*60}")
        
        try:
            # Create analyzer for this country
            analyzer = CountryAnalyzer(csv_path, country_code)
            
            # Run analysis
            result_table = analyzer.run_complete_analysis()
            
            print(f"✅ Analysis completed for {country_code}")
            
        except Exception as e:
            print(f"❌ Error analyzing {country_code}: {e}")
    
    print(f"\n{'='*80}")
    print("ALL ANALYSES COMPLETED!")
    print("="*80)

def analyze_single_country(country_code='AA'):
    """Example of analyzing a single country."""
    
    csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
    
    print(f"Analyzing country: {country_code}")
    
    # Create analyzer
    analyzer = CountryAnalyzer(csv_path, country_code)
    
    # List available countries first
    analyzer.list_available_countries()
    
    # Run analysis
    result_table = analyzer.run_complete_analysis()
    
    return result_table

def main():
    """Main function with examples."""
    
    print("COUNTRY ANALYZER EXAMPLES")
    print("="*50)
    print("1. Analyze single country (default: AA)")
    print("2. Analyze multiple countries")
    print("3. List available countries only")
    
    choice = input("\nEnter your choice (1-3): ").strip()
    
    if choice == '1':
        country = input("Enter country code (or press Enter for AA): ").strip()
        if not country:
            country = 'AA'
        analyze_single_country(country)
        
    elif choice == '2':
        analyze_multiple_countries()
        
    elif choice == '3':
        csv_path = "/Users/tsenga/Library/CloudStorage/GoogleDrive-t.senga@keio.jp/.shortcut-targets-by-id/15yrbGZaWzi5RPvxBTg_ps15iWtwDwEiw/ibes/data/stats_by_horizon_clean.csv"
        analyzer = CountryAnalyzer(csv_path)
        analyzer.list_available_countries()
        
    else:
        print("Invalid choice. Running default analysis for AA...")
        analyze_single_country('AA')

if __name__ == "__main__":
    main()
