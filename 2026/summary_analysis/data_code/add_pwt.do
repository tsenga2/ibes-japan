clear all

global mypath "/Users/hatsu/ibes-japan/ibes-japan/IBES"

use "$mypath/outputs/shrinkage_all_specs.dta", clear

drop if countrycode == ""

merge 1:1 countrycode year using "$mypath/Both/pwt1001.dta"

save "$mypath/outputs/shrinkage_all_specs_FDI_pwt.dta", replace
