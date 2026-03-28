/*==============================================================================
    Stock Market Development Panel Data - Stata Do-File
    
    Purpose: Download World Bank stock market indicators and create panel dataset
             ready for merge with existing country-year data
    
    Data Sources:
    1. World Bank WDI (via wbopendata)
    2. World Bank Global Financial Development Database (manual download)
    
    Author: [Your Name]
    Date: December 2024
==============================================================================*/

clear all
set more off

* Set your working directory
* cd "YOUR_PATH_HERE"

/*------------------------------------------------------------------------------
    PART 0: Install required packages (run once)
------------------------------------------------------------------------------*/
* ssc install wbopendata, replace

/*------------------------------------------------------------------------------
    PART 1: Define country list and variable mappings
------------------------------------------------------------------------------*/

* Your 39 countries with ISO3 codes
global countries "AUS AUT BEL BRA CAN CHE CHL CHN COL DEU DNK ESP FIN FRA GBR GRC HKG HUN IDN IND IRL ISR ITA JPN KOR MEX MYS NLD NOR NZL PHL POL PRT SGP SWE THA TUR USA ZAF"

* WDI indicator codes for stock market development
* CM.MKT.LCAP.GD.ZS  = Market capitalization of listed domestic companies (% of GDP)
* CM.MKT.LCAP.CD     = Market capitalization of listed domestic companies (current US$)
* CM.MKT.TRAD.GD.ZS  = Stocks traded, total value (% of GDP)
* CM.MKT.TRNR        = Stocks traded, turnover ratio of domestic shares (%)
* CM.MKT.LDOM.NO     = Listed domestic companies, total

/*------------------------------------------------------------------------------
    PART 2: Download data using wbopendata
------------------------------------------------------------------------------*/

* 2.1 Market Capitalization (% of GDP)
wbopendata, indicator(CM.MKT.LCAP.GD.ZS) long clear
rename cm_mkt_lcap_gd_zs mktcap_gdp
keep countrycode year mktcap_gdp
tempfile mktcap_gdp
save `mktcap_gdp'

* 2.2 Market Capitalization (current US$)
wbopendata, indicator(CM.MKT.LCAP.CD) long clear
rename cm_mkt_lcap_cd mktcap_usd
* Convert to millions for easier interpretation
replace mktcap_usd = mktcap_usd / 1000000
label var mktcap_usd "Market cap (million USD)"
keep countrycode year mktcap_usd
tempfile mktcap_usd
save `mktcap_usd'

* 2.3 Stocks Traded (% of GDP)
wbopendata, indicator(CM.MKT.TRAD.GD.ZS) long clear
rename cm_mkt_trad_gd_zs traded_gdp
keep countrycode year traded_gdp
tempfile traded_gdp
save `traded_gdp'

* 2.4 Turnover Ratio
wbopendata, indicator(CM.MKT.TRNR) long clear
rename cm_mkt_trnr turnover
keep countrycode year turnover
tempfile turnover
save `turnover'

* 2.5 Number of Listed Companies
wbopendata, indicator(CM.MKT.LDOM.NO) long clear
rename cm_mkt_ldom_no listed_firms
keep countrycode year listed_firms
tempfile listed
save `listed'

/*------------------------------------------------------------------------------
    PART 3: Merge all indicators
------------------------------------------------------------------------------*/

use `mktcap_gdp', clear

merge 1:1 countrycode year using `mktcap_usd', nogen
merge 1:1 countrycode year using `traded_gdp', nogen
merge 1:1 countrycode year using `turnover', nogen
merge 1:1 countrycode year using `listed', nogen

/*------------------------------------------------------------------------------
    PART 4: Keep only your 39 countries
------------------------------------------------------------------------------*/

gen keep_country = 0
foreach c in $countries {
    replace keep_country = 1 if countrycode == "`c'"
}
keep if keep_country == 1
drop keep_country

/*------------------------------------------------------------------------------
    PART 5: Add country metadata (index names, tickers)
------------------------------------------------------------------------------*/

* Create country info
gen country_name = ""
gen local_index = ""
gen bloomberg_ticker = ""

replace country_name = "Australia"       if countrycode == "AUS"
replace local_index = "S&P/ASX 200"      if countrycode == "AUS"
replace bloomberg_ticker = "AS51:IND"    if countrycode == "AUS"

replace country_name = "Austria"         if countrycode == "AUT"
replace local_index = "ATX Index"        if countrycode == "AUT"
replace bloomberg_ticker = "ATX:IND"     if countrycode == "AUT"

replace country_name = "Belgium"         if countrycode == "BEL"
replace local_index = "BEL 20"           if countrycode == "BEL"
replace bloomberg_ticker = "BEL20:IND"   if countrycode == "BEL"

replace country_name = "Brazil"          if countrycode == "BRA"
replace local_index = "Bovespa"          if countrycode == "BRA"
replace bloomberg_ticker = "IBOV:IND"    if countrycode == "BRA"

replace country_name = "Canada"          if countrycode == "CAN"
replace local_index = "S&P/TSX Composite" if countrycode == "CAN"
replace bloomberg_ticker = "SPTSX:IND"   if countrycode == "CAN"

replace country_name = "Switzerland"     if countrycode == "CHE"
replace local_index = "SMI"              if countrycode == "CHE"
replace bloomberg_ticker = "SMI:IND"     if countrycode == "CHE"

replace country_name = "Chile"           if countrycode == "CHL"
replace local_index = "IPSA"             if countrycode == "CHL"
replace bloomberg_ticker = "IPSA:IND"    if countrycode == "CHL"

replace country_name = "China"           if countrycode == "CHN"
replace local_index = "Shanghai Composite" if countrycode == "CHN"
replace bloomberg_ticker = "SHCOMP:IND"  if countrycode == "CHN"

replace country_name = "Colombia"        if countrycode == "COL"
replace local_index = "COLCAP"           if countrycode == "COL"
replace bloomberg_ticker = "COLCAP:IND"  if countrycode == "COL"

replace country_name = "Germany"         if countrycode == "DEU"
replace local_index = "DAX"              if countrycode == "DEU"
replace bloomberg_ticker = "DAX:IND"     if countrycode == "DEU"

replace country_name = "Denmark"         if countrycode == "DNK"
replace local_index = "OMX Copenhagen 25" if countrycode == "DNK"
replace bloomberg_ticker = "OMXC25:IND"  if countrycode == "DNK"

replace country_name = "Spain"           if countrycode == "ESP"
replace local_index = "IBEX 35"          if countrycode == "ESP"
replace bloomberg_ticker = "IBEX:IND"    if countrycode == "ESP"

replace country_name = "Finland"         if countrycode == "FIN"
replace local_index = "OMX Helsinki 25"  if countrycode == "FIN"
replace bloomberg_ticker = "OMXH25:IND"  if countrycode == "FIN"

replace country_name = "France"          if countrycode == "FRA"
replace local_index = "CAC 40"           if countrycode == "FRA"
replace bloomberg_ticker = "CAC:IND"     if countrycode == "FRA"

replace country_name = "United Kingdom"  if countrycode == "GBR"
replace local_index = "FTSE 100"         if countrycode == "GBR"
replace bloomberg_ticker = "UKX:IND"     if countrycode == "GBR"

replace country_name = "Greece"          if countrycode == "GRC"
replace local_index = "ASE General"      if countrycode == "GRC"
replace bloomberg_ticker = "ASE:IND"     if countrycode == "GRC"

replace country_name = "Hong Kong"       if countrycode == "HKG"
replace local_index = "Hang Seng"        if countrycode == "HKG"
replace bloomberg_ticker = "HSI:IND"     if countrycode == "HKG"

replace country_name = "Hungary"         if countrycode == "HUN"
replace local_index = "BUX"              if countrycode == "HUN"
replace bloomberg_ticker = "BUX:IND"     if countrycode == "HUN"

replace country_name = "Indonesia"       if countrycode == "IDN"
replace local_index = "Jakarta Composite" if countrycode == "IDN"
replace bloomberg_ticker = "JCI:IND"     if countrycode == "IDN"

replace country_name = "India"           if countrycode == "IND"
replace local_index = "NIFTY 50"         if countrycode == "IND"
replace bloomberg_ticker = "NIFTY:IND"   if countrycode == "IND"

replace country_name = "Ireland"         if countrycode == "IRL"
replace local_index = "ISEQ Overall"     if countrycode == "IRL"
replace bloomberg_ticker = "ISEQ:IND"    if countrycode == "IRL"

replace country_name = "Israel"          if countrycode == "ISR"
replace local_index = "TA-35"            if countrycode == "ISR"
replace bloomberg_ticker = "TA35:IND"    if countrycode == "ISR"

replace country_name = "Italy"           if countrycode == "ITA"
replace local_index = "FTSE MIB"         if countrycode == "ITA"
replace bloomberg_ticker = "FTSEMIB:IND" if countrycode == "ITA"

replace country_name = "Japan"           if countrycode == "JPN"
replace local_index = "Nikkei 225"       if countrycode == "JPN"
replace bloomberg_ticker = "NKY:IND"     if countrycode == "JPN"

replace country_name = "South Korea"     if countrycode == "KOR"
replace local_index = "KOSPI"            if countrycode == "KOR"
replace bloomberg_ticker = "KOSPI:IND"   if countrycode == "KOR"

replace country_name = "Mexico"          if countrycode == "MEX"
replace local_index = "IPC"              if countrycode == "MEX"
replace bloomberg_ticker = "MEXBOL:IND"  if countrycode == "MEX"

replace country_name = "Malaysia"        if countrycode == "MYS"
replace local_index = "FTSE Bursa Malaysia KLCI" if countrycode == "MYS"
replace bloomberg_ticker = "FBMKLCI:IND" if countrycode == "MYS"

replace country_name = "Netherlands"     if countrycode == "NLD"
replace local_index = "AEX"              if countrycode == "NLD"
replace bloomberg_ticker = "AEX:IND"     if countrycode == "NLD"

replace country_name = "Norway"          if countrycode == "NOR"
replace local_index = "OBX"              if countrycode == "NOR"
replace bloomberg_ticker = "OBX:IND"     if countrycode == "NOR"

replace country_name = "New Zealand"     if countrycode == "NZL"
replace local_index = "NZX 50"           if countrycode == "NZL"
replace bloomberg_ticker = "NZ50:IND"    if countrycode == "NZL"

replace country_name = "Philippines"     if countrycode == "PHL"
replace local_index = "PSEi"             if countrycode == "PHL"
replace bloomberg_ticker = "PCOMP:IND"   if countrycode == "PHL"

replace country_name = "Poland"          if countrycode == "POL"
replace local_index = "WIG20"            if countrycode == "POL"
replace bloomberg_ticker = "WIG20:IND"   if countrycode == "POL"

replace country_name = "Portugal"        if countrycode == "PRT"
replace local_index = "PSI 20"           if countrycode == "PRT"
replace bloomberg_ticker = "PSI20:IND"   if countrycode == "PRT"

replace country_name = "Singapore"       if countrycode == "SGP"
replace local_index = "STI"              if countrycode == "SGP"
replace bloomberg_ticker = "STI:IND"     if countrycode == "SGP"

replace country_name = "Sweden"          if countrycode == "SWE"
replace local_index = "OMX Stockholm 30" if countrycode == "SWE"
replace bloomberg_ticker = "OMXS30:IND"  if countrycode == "SWE"

replace country_name = "Thailand"        if countrycode == "THA"
replace local_index = "SET Index"        if countrycode == "THA"
replace bloomberg_ticker = "SET:IND"     if countrycode == "THA"

replace country_name = "Turkey"          if countrycode == "TUR"
replace local_index = "BIST 100"         if countrycode == "TUR"
replace bloomberg_ticker = "XU100:IND"   if countrycode == "TUR"

replace country_name = "United States"   if countrycode == "USA"
replace local_index = "S&P 500"          if countrycode == "USA"
replace bloomberg_ticker = "SPX:IND"     if countrycode == "USA"

replace country_name = "South Africa"    if countrycode == "ZAF"
replace local_index = "FTSE/JSE All Share" if countrycode == "ZAF"
replace bloomberg_ticker = "JALSH:IND"   if countrycode == "ZAF"

/*------------------------------------------------------------------------------
    PART 6: Label variables
------------------------------------------------------------------------------*/

label var countrycode "ISO3 Country Code"
label var country_name "Country Name"
label var year "Year"
label var local_index "Representative Local Stock Index"
label var bloomberg_ticker "Bloomberg Ticker"
label var mktcap_gdp "Stock Market Capitalization (% of GDP)"
label var mktcap_usd "Stock Market Capitalization (million USD)"
label var traded_gdp "Stocks Traded, Total Value (% of GDP)"
label var turnover "Stock Market Turnover Ratio (%)"
label var listed_firms "Number of Listed Domestic Companies"

/*------------------------------------------------------------------------------
    PART 7: Order and sort
------------------------------------------------------------------------------*/

order countrycode country_name year local_index bloomberg_ticker ///
      mktcap_gdp mktcap_usd traded_gdp turnover listed_firms

sort countrycode year

/*------------------------------------------------------------------------------
    PART 8: Save dataset
------------------------------------------------------------------------------*/

compress
save "stock_market_panel_wdi.dta", replace

* Also export to CSV for reference
export delimited using "stock_market_panel_wdi.csv", replace

/*------------------------------------------------------------------------------
    PART 9: Summary statistics
------------------------------------------------------------------------------*/

di _n "============================================================"
di "Summary Statistics"
di "============================================================"

summarize mktcap_gdp traded_gdp turnover listed_firms, detail

di _n "Data coverage by country:"
tab countrycode if !missing(mktcap_gdp)

di _n "Data coverage by year:"
tab year if !missing(mktcap_gdp)

/*------------------------------------------------------------------------------
    PART 10: Merging with your existing dataset
    
    Assuming your existing data has a variable "countrycode" in ISO3 format
    and "year" variable
------------------------------------------------------------------------------*/

/*
* Example merge code (uncomment and modify as needed):

use "your_existing_data.dta", clear

* Merge stock market data
merge m:1 countrycode year using "stock_market_panel_wdi.dta", ///
    keepusing(mktcap_gdp mktcap_usd traded_gdp turnover listed_firms)

* Check merge results
tab _merge

* Keep only matched or master observations
keep if _merge == 1 | _merge == 3
drop _merge

save "your_data_with_stock_market.dta", replace
*/

/*==============================================================================
    END OF DO-FILE
==============================================================================*/
