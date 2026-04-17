/****************************************************************************************
Robust & refactored version (FINAL, PARSER-SAFE)
WITH ANALYST COVERAGE (NUMEST)
****************************************************************************************/

version 16.0
clear all
set more off
set graphics off

*=============================*
* Path
*=============================*
global mypath "~/Library/CloudStorage/Dropbox/IBES"

*=============================*
* Main
*=============================*

di as text "===== Running shrinkage (NO LOOP) ====="

use "$mypath/Both/sum_history.dta", clear
merge m:1 TICKER using "$mypath/Both/ibes_summary_identif.dta", keep(match master) nogen

gen int pred_year = year(STATPERS)
gen int eyear     = year(FPEDATS)

keep if inrange(pred_year, 2000, 2019)
keep if eyear != 2008
keep if FISCALP == "ANN"
keep if NUMEST >= 3

gen int horizon = ym(year(FPEDATS), month(FPEDATS)) - ym(year(STATPERS), month(STATPERS))
keep if inrange(horizon, 0, 11)

gen double FE_MEAN   = abs(ACTUAL - MEANEST)
gen double FE_MEDIAN = abs(ACTUAL - MEDEST)

gen double CV = .
replace CV = STDEV/abs(MEANEST) if abs(MEANEST) > 0 & MEANEST < . & STDEV < .

drop if missing(STDEV)

*=============================*
* Winsorize STDEV
*=============================*

bysort COUNTRY eyear horizon: egen double p5  = pctile(STDEV), p(5)
bysort COUNTRY eyear horizon: egen double p95 = pctile(STDEV), p(95)

drop if STDEV < p5 | STDEV > p95

drop p5 p95

*=============================*
* Firm-year-horizon collapse
*=============================*

collapse (mean) ///
STDEV CV FE_MEAN FE_MEDIAN MEANEST MEDEST NUMEST ///
, by(TICKER pred_year COUNTRY horizon)

*=============================*
* Reshape wide
*=============================*

reshape wide ///
STDEV CV FE_MEAN FE_MEDIAN MEANEST MEDEST NUMEST ///
, i(TICKER pred_year COUNTRY) j(horizon)

*------------------------------------------------*
* STDEV shrinkage
*------------------------------------------------*

gen double STDEV_long  = (STDEV6 +STDEV7 +STDEV8 +STDEV9 +STDEV10+STDEV11)/6
gen double STDEV_short = (STDEV0 +STDEV1 +STDEV2 +STDEV3 +STDEV4 +STDEV5 )/6

gen double STDEV_6to11_vs_0to5 = .
replace STDEV_6to11_vs_0to5 = 100*(STDEV_long - STDEV_short)/STDEV_long if STDEV_long > 0 & STDEV_short < .

gen double STDEV_6to11_vs_0 = .
replace STDEV_6to11_vs_0 = 100*(STDEV_long - STDEV0)/STDEV_long if STDEV_long > 0 & STDEV0 < .

gen double STDEV_5_vs_0 = .
replace STDEV_5_vs_0 = 100*(STDEV5 - STDEV0)/STDEV5 if STDEV5 > 0 & STDEV0 < .

forvalues h = 0/11 {
    gen double lnSTDEV`h' = ln(STDEV`h')
    replace lnSTDEV`h' = . if STDEV`h' <= 0
}

forvalues h = 1/11 {
    local h1 = `=`h'-1'
    gen double dSTDEV`h' = lnSTDEV`h' - lnSTDEV`h1'
}

gen double Mean_log_STDEV_change = ///
(dSTDEV1 +dSTDEV2 +dSTDEV3 +dSTDEV4 +dSTDEV5 +dSTDEV6 +dSTDEV7 +dSTDEV8 +dSTDEV9 +dSTDEV10+dSTDEV11)/11

replace Mean_log_STDEV_change = 100*Mean_log_STDEV_change if Mean_log_STDEV_change < .

gen double CV_10_vs_0 = CV10 - CV0
gen double CV_5_vs_0  = CV5  - CV0

*------------------------------------------------*
* FE shrinkage
*------------------------------------------------*

gen double FE_long  = (FE_MEAN6 +FE_MEAN7 +FE_MEAN8 +FE_MEAN9 +FE_MEAN10+FE_MEAN11)/6
gen double FE_short = (FE_MEAN0 +FE_MEAN1 +FE_MEAN2 +FE_MEAN3 +FE_MEAN4 +FE_MEAN5 )/6

gen double FE_6to11_vs_0to5 = .
replace FE_6to11_vs_0to5 = 100*(FE_long - FE_short)/FE_long if FE_long > 0 & FE_short < .

gen double FE_6to11_vs_0 = .
replace FE_6to11_vs_0 = 100*(FE_long - FE_MEAN0)/FE_long if FE_long > 0 & FE_MEAN0 < .

gen double FE_5_vs_0 = .
replace FE_5_vs_0 = 100*(FE_MEAN5 - FE_MEAN0)/FE_MEAN5 if FE_MEAN5 > 0 & FE_MEAN0 < .

forvalues h = 0/11 {
    gen double lnFE`h' = ln(FE_MEAN`h')
    replace lnFE`h' = . if FE_MEAN`h' <= 0
}

forvalues h = 1/11 {
    local h1 = `=`h'-1'
    gen double dFE`h' = lnFE`h' - lnFE`h1'
}

gen double Mean_log_FE_change = ///
(dFE1 +dFE2 +dFE3 +dFE4 +dFE5 +dFE6 +dFE7 +dFE8 +dFE9 +dFE10+dFE11)/11

replace Mean_log_FE_change = 100*Mean_log_FE_change if Mean_log_FE_change < .

gen double FE_MEAN_all = ///
(FE_MEAN0+FE_MEAN1+FE_MEAN2+FE_MEAN3+FE_MEAN4+FE_MEAN5+ ///
 FE_MEAN6+FE_MEAN7+FE_MEAN8+FE_MEAN9+FE_MEAN10+FE_MEAN11)/12

gen double FE_MEDIAN_all = ///
(FE_MEDIAN0+FE_MEDIAN1+FE_MEDIAN2+FE_MEDIAN3+FE_MEDIAN4+FE_MEDIAN5+ ///
 FE_MEDIAN6+FE_MEDIAN7+FE_MEDIAN8+FE_MEDIAN9+FE_MEDIAN10+FE_MEDIAN11)/12

*------------------------------------------------*
* MEANEST levels
*------------------------------------------------*

gen double MEANEST_long  = (MEANEST6 +MEANEST7 +MEANEST8 +MEANEST9 +MEANEST10+MEANEST11)/6
gen double MEANEST_short = (MEANEST0 +MEANEST1 +MEANEST2 +MEANEST3 +MEANEST4 +MEANEST5 )/6

*------------------------------------------------*
* MEDEST levels
*------------------------------------------------*

gen double MEDEST_long  = (MEDEST6 +MEDEST7 +MEDEST8 +MEDEST9 +MEDEST10+MEDEST11)/6
gen double MEDEST_short = (MEDEST0 +MEDEST1 +MEDEST2 +MEDEST3 +MEDEST4 +MEDEST5 )/6

*------------------------------------------------*
* NUMEST (Analyst Coverage)
*------------------------------------------------*

gen double NUMEST_long  = (NUMEST6 +NUMEST7 +NUMEST8 +NUMEST9 +NUMEST10+NUMEST11)/6
gen double NUMEST_short = (NUMEST0 +NUMEST1 +NUMEST2 +NUMEST3 +NUMEST4 +NUMEST5 )/6


*------------------------------------------------*
* Collapse to country-year
*------------------------------------------------*

collapse (mean) ///
STDEV_long ///
STDEV_short ///
STDEV0 ///
STDEV5 ///
STDEV_6to11_vs_0to5 ///
STDEV_6to11_vs_0 ///
STDEV_5_vs_0 ///
Mean_log_STDEV_change ///
CV_10_vs_0 ///
CV_5_vs_0 ///
FE_long ///
FE_short ///
FE_MEAN0 ///
FE_MEAN5 ///
FE_6to11_vs_0to5 ///
FE_6to11_vs_0 ///
FE_5_vs_0 ///
Mean_log_FE_change ///
FE_MEAN_all ///
FE_MEDIAN_all ///
MEANEST_long ///
MEANEST_short ///
MEANEST0 ///
MEANEST5 ///
MEDEST_long ///
MEDEST_short ///
MEDEST0 ///
MEDEST5 ///
NUMEST_long ///
NUMEST_short ///
NUMEST0 ///
NUMEST5 ///
, by(pred_year COUNTRY)

rename pred_year year

di as result "Finished."

save "$mypath/outputs/shrinkage_all_specs.dta", replace

di as text "ALL DONE"
