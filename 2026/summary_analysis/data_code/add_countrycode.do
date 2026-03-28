version 16.0
clear all
set more off

*=============================*
* Load shrinkage results
*=============================*
use "$mypath/outputs/shrinkage_all_specs.dta", clear

*=============================*
* Merge country code map
*=============================*
merge m:1 COUNTRY using "$mypath/outputs/country_map.dta", ///
    keep(master match) nogen

*=============================*
* Safety check
*=============================*
count if missing(countrycode)
if r(N) > 0 {
    di as error "WARNING: Missing countrycode for some COUNTRY values"
    tab COUNTRY if missing(countrycode)
}

*=============================*
* (Optional) Label dev_group
*=============================*
label define devlbl 1 "Developed" 2 "Emerging" 3 "Frontier"
label values dev_group devlbl

*=============================*
* Save updated all_spec
*=============================*
save "$mypath/outputs/shrinkage_all_specs.dta", replace

di as result "countrycode (and dev_group) successfully added."
