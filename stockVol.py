import pandas as pd
import numpy as np
import yfinance as yf
from tqdm import tqdm

def get_stock_vol(stock_code, start_date, end_date):
    ticker = f"{stock_code}.T"  # Assuming the stocks are from the Tokyo Stock Exchange
    stock_data = yf.download(ticker, start=start_date, end=end_date)
    
    if len(stock_data) == 0:
        return None
    
    stock_data['Stock Code'] = stock_code
    stock_data['Date'] = stock_data.index
    stock_data['StockVol'] = stock_data['Close'].rolling(window=30).std()
    
    monthly_data = stock_data.resample('M', on='Date').last()[['Stock Code', 'StockVol']]
    return monthly_data

start_date = "2022-01-01"
end_date = "2023-04-30"
stock_codes = range(1301, 9998)

monthly_panel_data = []

for stock_code in tqdm(stock_codes, desc="Processing stocks"):
    stock_vol_data = get_stock_vol(stock_code, start_date, end_date)
    
    if stock_vol_data is not None:
        monthly_panel_data.append(stock_vol_data)

monthly_panel = pd.concat(monthly_panel_data)
monthly_panel.reset_index(inplace=True)
monthly_panel['Date'] = monthly_panel['Date'].dt.strftime('%Y-%m')

print(monthly_panel)