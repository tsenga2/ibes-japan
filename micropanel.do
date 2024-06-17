cls
clear all
set graph off

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan"
use $mypath/merged.dta, clear

capture mkdir $mypath/graph 
capture mkdir $mypath/table 

gen oftic = OFTIC
generate period = sym
format period %tm

preserve
import delimited "$mypath/combined_data.csv", clear
duplicates drop oftic period, force

gen period_float = monthly(period, "YM")
format period_float %tm
drop period
rename period_float period
save "$mypath/combined_data.dta", replace
restore

rename _merge _merge_dbj
sort oftic period sym
order oftic period sym

keep if _merge_dbj == 3
drop _merge_dbj
sort oftic period

gen str7 period_str = string(period, "%tm")
sort oftic period_str
merge 1:1 oftic period using "$mypath/combined_data.dta", generate(_merge_nikkei)

keep if _merge_nikkei == 3
drop _merge_nikkei

gen highlow = highprice - lowprice
replace highlow = highlow / openingprice
gen abshighlow = abs(highlow)

gen horizon = eym - sym

gen Fdis_CV =  STDEV/abs(MEDEST)
gen FE_log = abs(log(ACTUAL/MEDEST))
gen FE_pct = abs(ACTUAL/MEDEST -1)

bysort CNAME: egen first_year = min(eyear)
bysort CNAME: egen Age = max(eyear - first_year)

order OFTIC STATPERS syear eyear MEDEST ACTUAL sale ni
sort OFTIC STATPERS syear eyear

preserve
collapse (mean) abshighlow ACTUAL sale ni NUMEST Fdis_CV FE_log FE_pct MEDEST, by(OFTIC eyear)

gen stockvol = abshighlow
by OFTIC (eyear): gen ACTUAL_growth = (ACTUAL - ACTUAL[_n-1]) / ACTUAL[_n-1]
by OFTIC (eyear): gen SD_ACTUAL_growth = sqrt((sum((ACTUAL_growth - ACTUAL_growth[_n-1])/ACTUAL_growth[_n-1])^2)/(_N-1))

keep OFTIC eyear SD_ACTUAL_growth stockvol
save "$mypath/sd_growth.dta", replace
restore

merge m:1 OFTIC eyear using "$mypath/sd_growth.dta"
drop _merge

555

keep if OFTIC==6701
winsor2 Fdis_CV, replace cuts(1 99) 
tsset sym

set graph on
twoway (tsline Fdis_CV, yaxis(1)) (tsline topix, yaxis(2)) (tsline openingprice, yaxis(3)), ///
xtitle("") ytitle("Fdis_CV", axis(1)) ytitle("topix", axis(2)) ytitle("openingprice", axis(3)) ///
legend(order(1 "Fdis_CV" 2 "topix" 3 "openingprice") position(inside)) ///
name(graph1)

twoway (tsline Fdis_CV, yaxis(1)) (tsline highlow, yaxis(2)) (tsline openingprice, yaxis(3)), ///
xtitle("") ytitle("Fdis_CV", axis(1)) ytitle("highlow", axis(2)) ytitle("openingprice", axis(3)) ///
legend(order(1 "Fdis_CV" 2 "highlow" 3 "openingprice") position(inside)) ///
name(graph2)



777






preserve
keep OFTIC eyear ACTUAL sale ni NUMEST Fdis_CV FE_log FE_pct MEDEST SD_ACTUAL_growth Age stockvol
winsor2 *, replace cuts(1 99) trim
collapse (mean) ACTUAL sale ni NUMEST Fdis_CV FE_log FE_pct MEDEST SD_ACTUAL_growth Age stockvol, by(OFTIC eyear)

xtset OFTIC eyear

eststo clear


