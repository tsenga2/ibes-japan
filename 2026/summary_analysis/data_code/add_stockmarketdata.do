clear all

global mypath "/Users/hatsu/ibes-japan/ibes-japan/IBES"

use "$mypath/outputs/shrinkage_all_specs_FDI_pwt.dta", clear
drop _merge

merge 1:1 countrycode year using "$mypath/20251224/stock_market_panel_complete.dta"
keep if year >= 2000 
save "$mypath/outputs/shrinkage_all_specs_FDI_pwt_stock.dta", replace
