import pandas as pd
import numpy as np
import yfinance as yf

# Fetch the daily series data of Nikkei 225 index from Yahoo Finance
nikkei_data = yf.download('^N225', start='1985-01-01', end='2023-07-31')

# Calculate daily returns
nikkei_data['Returns'] = nikkei_data['Close'].pct_change()

# Calculate monthly volatility (standard deviation of daily returns)
monthly_volatility = nikkei_data['Returns'].resample('M').std()

# Convert monthly volatility to annualized volatility
annualized_volatility = monthly_volatility * np.sqrt(252)

# Prepare the dataset for export
volatility_df = annualized_volatility.reset_index()
volatility_df.columns = ['sym', 'Volatility']
volatility_df['sym'] = volatility_df['sym'].dt.to_period('M')

# Export the data to a .dta file
volatility_df.to_stata('nikkei_monthly_volatility.dta', write_index=False)
