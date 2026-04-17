clear all
set more off

*=============================*
* Load shrinkage results
*=============================*
global mypath "~/Library/CloudStorage/Dropbox/IBES"
use "$mypath/Both/sum_history.dta", clear

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

collapse (mean) ACTUAL STDEV CV FE_MEAN FE_MEDIAN, by(TICKER pred_year horizon)

reshape wide ACTUAL STDEV CV FE_MEAN FE_MEDIAN, i(TICKER pred_year) j(horizon)
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

* 対数（レベル）
forvalues h = 0/11 {
    gen double lnSTDEV`h' = ln(STDEV`h')
    replace lnSTDEV`h' = . if STDEV`h' <= 0
}

* 対数差分
forvalues h = 1/11 {
    local h1 = `=`h'-1'
    gen double dSTDEV`h' = lnSTDEV`h' - lnSTDEV`h1'
}

gen double Mean_log_STDEV_change = .
replace Mean_log_STDEV_change = ///
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

* 対数（レベル）
forvalues h = 0/11 {
    gen double lnFE`h' = ln(FE_MEAN`h')
    replace lnFE`h' = . if FE_MEAN`h' <= 0
}

* 対数差分
forvalues h = 1/11 {
    local h1 = `=`h'-1'
    gen double dFE`h' = lnFE`h' - lnFE`h1'
}

gen double Mean_log_FE_change = .
replace Mean_log_FE_change = ///
    (dFE1 +dFE2 +dFE3 +dFE4 +dFE5 +dFE6 +dFE7 +dFE8 +dFE9 +dFE10+dFE11)/11
replace Mean_log_FE_change = 100*Mean_log_FE_change if Mean_log_FE_change < .

* 12 horizons average（wide後の FE_MEAN* / FE_MEDIAN* を平均）
gen double FE_MEAN_all = ///
    (FE_MEAN0+FE_MEAN1+FE_MEAN2+FE_MEAN3+FE_MEAN4+FE_MEAN5+ ///
     FE_MEAN6+FE_MEAN7+FE_MEAN8+FE_MEAN9+FE_MEAN10+FE_MEAN11)/12

gen double FE_MEDIAN_all = ///
    (FE_MEDIAN0+FE_MEDIAN1+FE_MEDIAN2+FE_MEDIAN3+FE_MEDIAN4+FE_MEDIAN5+ ///
     FE_MEDIAN6+FE_MEDIAN7+FE_MEDIAN8+FE_MEDIAN9+FE_MEDIAN10+FE_MEDIAN11)/12
	 
	 
local yvars ///
    STDEV_6to11_vs_0to5 STDEV_6to11_vs_0 STDEV_5_vs_0 Mean_log_STDEV_change ///
    CV_10_vs_0 CV_5_vs_0 ///
    FE_6to11_vs_0to5 FE_6to11_vs_0 FE_5_vs_0 Mean_log_FE_change ///
    FE_MEAN_all FE_MEDIAN_all
	
foreach y of local yvars {

    twoway ///
        (scatter `y' Actual_0, msize(small)) ///
        (qfit `y' Actual_0), ///
        ytitle("`y'") ///
        xtitle("Actual_0") ///
        title("`y' vs Actual_0")

}

foreach y of local yvars {

    twoway ///
        (scatter `y' Actual_0, msize(small)) ///
        (qfit `y' Actual_0), ///
        ytitle("`y'") ///
        xtitle("Actual_0")

    graph export "~/ibes-japan/2026/summary_analysis/graph/micro level scatter/`y'_vs_Actual_0.png", replace
}

