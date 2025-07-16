clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"

use $mypath/merged_data.dta, clear
drop _merge
merge m:m OFTIC using "$mypath/ibes_summary_identif.dta"
