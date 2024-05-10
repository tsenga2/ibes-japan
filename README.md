<h2 align="center">
  IBES-JAPAN project
</h2> 

---
---

## Here are the related papers in nice markdown format:

1. アナリスト予想データとアクティブ運用.pdf
2. 予想利益の精度と価値関連性I:B:E:S四季報経営者予想の比較.pdf
3. 業績予想における経営者予想とアナリスト予想の役割.pdf
4. 経営者予想とアナリスト予想の精度とバイアス.pdf

---
---
## tseries.do performs several tasks related to analyzing analyst forecast data for Japanese companies. Here's a summary of what the do-file does:
1. It loads the "ibes-summary-international.dta" dataset and keeps only the observations where the currency code is "JPY" (Japanese Yen).
2. It creates several date variables and generates measures of forecast dispersion (Fdis_CV), forecast error (FE_log and FE_pct), and other summary statistics.
3. It collapses the data by month and calculates the mean and standard deviation of various variables.
4. It creates time-series plots of the mean forecast dispersion (mean_Fdis_CV) and mean forecast error (mean_FE_pct) over time, adding labels for significant events.
5. It imports additional time-series data from FRED (Federal Reserve Economic Data) for Japan, including the Nikkei 225 index, industrial production, and economic policy uncertainty (EPU) index.
6. It merges the IBES summary data with the FRED data and calculates the volatility of the Nikkei 225 index.
7. It creates moving average variables for EPU and the mean forecast dispersion and error.
8. It generates various time-series plots to visualize the relationships between forecast dispersion, forecast error, EPU, industrial production, and the Nikkei 225 index.
9. It runs a series of regressions to examine the relationship between the dependent variables (forecast dispersion, forecast error, EPU, and volatility) and independent variables (industrial production and Nikkei 225 index), controlling for month and year fixed effects.
10. It creates LaTeX tables of the regression results and a cross-correlation matrix of the main variables.

Overall, this do-file performs a comprehensive analysis of the relationships between analyst forecast dispersion, forecast error, economic uncertainty, and stock market performance in Japan using the IBES dataset and additional macroeconomic data from FRED.

---
---
## describe.do
## Data Preparation and Analysis

- Set the working directory to $mypath/graph and create a new folder $mypath/table if it doesn't exist.
- Filter the dataset to include only observations where CURCODE is "JPY".
- Generate new variables:

- syear: year of STATPERS
- sm: month of STATPERS
- sym: year-month combination of syear and sm
- month: same as sym
- eyear: year of FPEDATS
- em: month of FPEDATS
- eym: year-month combination of eyear and em


- Convert OFTIC to numeric format.
- Create additional variables:

- Fdis_CV: forecast dispersion, calculated as STDEV/abs(MEDEST)
- FE_log: forecast error (log), calculated as abs(log(ACTUAL/MEDEST))
- FE_pct: forecast error (percentage), calculated as abs(ACTUAL/MEDEST -1)

- Sort the dataset by OFTIC, sym, and eym, and order the variables.
- Generate oftic and period variables, and drop observations with missing oftic.
- Remove duplicate observations based on oftic and period.

## Data Merging and Visualization

- Preserve the current dataset.
- Import the "combined_data.csv" file and remove duplicates based on oftic and period.
- Convert period to a numeric format and set it as the panel time variable.
- Save the imported dataset as "combined_data.dta".
- Restore the preserved dataset.
- Merge the current dataset with "combined_data.dta" based on oftic and period, generating a new variable _merge_nikkei.
- Create indicator variables count_merge_3 and count_merge_2 to count the number of observations where _merge_nikkei is 3 and 2, respectively.
- Collapse the data to obtain the sum of count_merge_3 and count_merge_2 for each period.
- Create a stacked bar chart showing the number of observations for each merge type (_merge_nikkei) by period.
- Customize the bar colors and remove the legend.
- Export the bar chart as "merge_nikkei_counts.png" in the $mypath/graph directory.

This do-file performs data preparation, generates new variables, merges datasets, and creates a visualization of the merge results using a stacked bar chart.
