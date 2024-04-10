import pandas as pd
import os

# Load the CSV file
df = pd.read_csv('1.csv', encoding='shift_jis')

# Display the column names in Japanese
print(df.columns)

# List of CSV file names
csv_files = [file for file in os.listdir() if file.endswith('.csv')]

# Initialize an empty list to store the DataFrames
dataframes = []

# Loop through each CSV file
for file in csv_files:
    # Check if the file exists
    if os.path.isfile(file):
        # Read the CSV file into a DataFrame with 'shift_jis' encoding
        df = pd.read_csv(file, encoding='shift_jis')
        dataframes.append(df)
    else:
        print(f"File '{file}' not found.")

# Concatenate all DataFrames vertically
combined_df = pd.concat(dataframes, ignore_index=True)
# Assuming the original column is named 'original_period'
combined_df['期間'] = pd.to_datetime(combined_df['期間'], format='%Y/%m').dt.strftime('%Ym%m')
# Print the combined DataFrame
print(combined_df)



# Rename columns to English
combined_df.rename(columns={
    '期間': 'period',
    '日経平均': 'Nikkei Average',
    'topix': 'TOPIX',
    '株式コード': 'OFTIC',
    '上場コード': 'Listing Code',
    '銘柄名称': 'Stock Name',
    '本決算実績・一株利益': 'Actual Earnings Per Share',
    '本決算予想・一株利益': 'Estimated Earnings Per Share',
    '本決算予想・更新日': 'Earnings Forecast Update Date',
    '本決算予想・決算期': 'Earnings Forecast Period',
    '時価総額（発行済み株式数ベース）': 'Market Capitalization Based on Issued Shares',
    '株式区分': 'Stock Type',
    '取引所': 'Exchange',
    '上場場部': 'Listing Section',
    '始値': 'Opening Price',
    '高値': 'High Price',
    '安値': 'Low Price',
    '終値': 'Closing Price',
    '売買高': 'Trading Volume',
    '東証業種コード３３分類': '33 Sector Classification Code',
    '日経業種区分': 'Nikkei Sector Classification',
    '日経業種中分類コード': 'Nikkei Sector Middle Classification Code',
    '日経業種小分類コード': 'Nikkei Sector Small Classification Code',
    '額面': 'Face Value',
    '発行済み株式数（権利落ベース）': 'Issued Shares Rights Off Base'
}, inplace=True)


# Export the combined DataFrame as a CSV file
combined_df.to_csv('combined_data.csv', index=False, encoding='shift_jis')