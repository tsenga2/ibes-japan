<h2 align="center">
  IBES-JAPAN project
</h2> 

Here are the related papers in nice markdown format:

- アナリスト予想データとアクティブ運用.pdf
- 予想利益の精度と価値関連性I:B:E:S四季報経営者予想の比較.pdf
- 業績予想における経営者予想とアナリスト予想の役割.pdf
- 経営者予想とアナリスト予想の精度とバイアス.pdf


##tseries.do performs several tasks related to analyzing analyst forecast data for Japanese companies. Here's a summary of what the do-file does:

###It loads the "ibes-summary-international.dta" dataset and keeps only the observations where the currency code is "JPY" (Japanese Yen).
###It creates several date variables and generates measures of forecast dispersion (Fdis_CV), forecast error (FE_log and FE_pct), and other summary statistics.
###It collapses the data by month and calculates the mean and standard deviation of various variables.
###It creates time-series plots of the mean forecast dispersion (mean_Fdis_CV) and mean forecast error (mean_FE_pct) over time, adding labels for significant events.
###It imports additional time-series data from FRED (Federal Reserve Economic Data) for Japan, including the Nikkei 225 index, industrial production, and economic policy uncertainty (EPU) index.
###It merges the IBES summary data with the FRED data and calculates the volatility of the Nikkei 225 index.
###It creates moving average variables for EPU and the mean forecast dispersion and error.
###It generates various time-series plots to visualize the relationships between forecast dispersion, forecast error, EPU, industrial production, and the Nikkei 225 index.
###It runs a series of regressions to examine the relationship between the dependent variables (forecast dispersion, forecast error, EPU, and volatility) and independent variables (industrial production and Nikkei 225 index), controlling for month and year fixed effects.
###It creates LaTeX tables of the regression results and a cross-correlation matrix of the main variables.

Overall, this do-file performs a comprehensive analysis of the relationships between analyst forecast dispersion, forecast error, economic uncertainty, and stock market performance in Japan using the IBES dataset and additional macroeconomic data from FRED.
