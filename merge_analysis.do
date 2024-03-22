cls
clear all
set more off

use  "/Users/kawabatahatsu/Desktop/ra/IBES/international/merged.dta", clear

keep if _merge == 3

gen Fdis_CV =  STDEV/abs(MEDEST)
gen FE_log = abs(log(ACTUAL/MEDEST))
gen FE_pct = abs(ACTUAL/MEDEST -1)

preserve

keep sale ta  Fdis_CV FE_log FE_pct

summarize, detail
outsheet using "merged_summary.txt", replace

restore

gen tfa_log = log(tfa)

binscatter NUMEST tfa_log, name(NUMEST_merged, replace)
binscatter STDEV tfa_log, name(STDEV_merged, replace)

graph combine NUMEST_merged STDEV_merged, title("") graphregion(color(white)) name(combo_merged, replace)

