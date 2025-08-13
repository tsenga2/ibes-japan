import pandas as pd
import pandas_datareader as web
import numpy as np

# Retrieve Nikkei 225 index data from 1985-01-01 to 2023-07-31
nikkei_data = web.DataReader('NIKKEI225', 'fred', '1985-01-01', '2023-07-31')

# Calculate daily returns
nikkei_data['Returns'] = nikkei_data['NIKKEI225'].pct_change(fill_method=None)

# Calculate monthly volatility
monthly_volatility = nikkei_data.resample('MS')['Returns'].agg(lambda x: np.sqrt(252) * x.std())

# Create a DataFrame with the monthly volatility and the corresponding month
volatility_data = pd.DataFrame({'Volatility': monthly_volatility})

# Create the 'sym' variable in the desired format (e.g., 1985m1, 1985m2, etc.) as a float
volatility_data['sym'] = (volatility_data.index.year * 100 + volatility_data.index.month).astype(float)

# Export the data to a .dta file
volatility_data.to_stata('nikkei_volatility.dta', write_index=False)