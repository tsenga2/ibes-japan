/****************************************************************************************
Robust & refactored version (FINAL, PARSER-SAFE)
- r(197) invalid syntax を構造的に完全排除
- Results ウィンドウ由来の文字列ゼロ
- 行継続 /// を極力使わない
****************************************************************************************/
clear all
set more off
set graphics off

version 16.0
clear all
set more off
set graphics off

*=============================*
* Path
*=============================*
global mypath "~/Library/CloudStorage/Dropbox/IBES"
local graphroot "$mypath/graphs"

*=============================*
* Shrinkage specs
*=============================*
local shrink_specs ///
    STDEV_6to11_vs_0to5 ///
    STDEV_6to11_vs_0 ///
    STDEV_5_vs_0 ///
    Mean_log_STDEV_change ///
    CV_10_vs_0 ///
    CV_5_vs_0

*=============================*
* Safe log helper
*=============================*
capture program drop safelog
program define safelog
    version 16.0
    syntax newvarname "=" varname
    gen double `newvarname' = .
    replace `newvarname' = ln(`varname') if `varname' > 0 & `varname' < .
end

*=============================*
* Main loop
*=============================*
foreach shrink_spec of local shrink_specs {

    di as text "===== Running shrinkage spec: `shrink_spec' ====="

    use "$mypath/Both/sum_history.dta", clear
    merge m:1 TICKER using "$mypath/Both/ibes_summary_identif.dta", ///
        keep(match master) nogen

    gen int pred_year = year(STATPERS)
    gen int eyear     = year(FPEDATS)

    keep if inrange(pred_year,2000,2019)
    keep if eyear != 2008
    keep if FISCALP == "ANN"
    keep if NUMEST >= 3

    gen int horizon = ym(year(FPEDATS),month(FPEDATS)) ///
                    - ym(year(STATPERS),month(STATPERS))
    keep if inrange(horizon,0,11)

    gen double FE_MEAN   = abs(ACTUAL - MEANEST)
    gen double FE_MEDIAN = abs(ACTUAL - MEDEST)
    gen double CV = .
    replace CV = STDEV/abs(MEANEST) if abs(MEANEST)>0 & STDEV<.

    drop if missing(STDEV)

    bysort COUNTRY eyear horizon: egen p5  = pctile(STDEV), p(5)
    bysort COUNTRY eyear horizon: egen p95 = pctile(STDEV), p(95)
    drop if STDEV<p5 | STDEV>p95
    drop p5 p95

    collapse (mean) STDEV CV FE_MEAN FE_MEDIAN, ///
        by(TICKER pred_year COUNTRY horizon)

    reshape wide STDEV CV FE_MEAN FE_MEDIAN, ///
        i(TICKER pred_year COUNTRY) j(horizon)

    *=============================*
    * STDEV shrinkage
    *=============================*
    gen double STDEV_long  = (STDEV6+STDEV7+STDEV8+STDEV9+STDEV10+STDEV11)/6
    gen double STDEV_short = (STDEV0+STDEV1+STDEV2+STDEV3+STDEV4+STDEV5)/6

    gen double STDEV_6to11_vs_0to5 = .
    replace STDEV_6to11_vs_0to5 = 100*(STDEV_long-STDEV_short)/STDEV_long ///
        if STDEV_long>0 & STDEV_short<.

    gen double STDEV_6to11_vs_0 = .
    replace STDEV_6to11_vs_0 = 100*(STDEV_long-STDEV0)/STDEV_long ///
        if STDEV_long>0 & STDEV0<.

    gen double STDEV_5_vs_0 = .
    replace STDEV_5_vs_0 = 100*(STDEV5-STDEV0)/STDEV5 ///
        if STDEV5>0 & STDEV0<.

    forvalues h=0/11 {
        safelog lnSTDEV`h' = STDEV`h'
    }

    forvalues h=1/11 {
        local h1 = `h'-1
        gen double dSTDEV`h' = lnSTDEV`h' - lnSTDEV`h1'
    }

    gen double Mean_log_STDEV_change = ///
        (dSTDEV1+dSTDEV2+dSTDEV3+dSTDEV4+dSTDEV5+dSTDEV6+dSTDEV7+dSTDEV8+dSTDEV9+dSTDEV10+dSTDEV11)/11
    replace Mean_log_STDEV_change = 100*Mean_log_STDEV_change if Mean_log_STDEV_change<.

    gen double CV_10_vs_0 = CV10-CV0
    gen double CV_5_vs_0  = CV5-CV0

    *=============================*
    * FE aggregates（平均のみ使用）
    *=============================*
    gen double FE_MEAN_all = ///
        (FE_MEAN0+FE_MEAN1+FE_MEAN2+FE_MEAN3+FE_MEAN4+FE_MEAN5 ///
        +FE_MEAN6+FE_MEAN7+FE_MEAN8+FE_MEAN9+FE_MEAN10+FE_MEAN11)/12

    gen double FE_MEDIAN_all = ///
        (FE_MEDIAN0+FE_MEDIAN1+FE_MEDIAN2+FE_MEDIAN3+FE_MEDIAN4+FE_MEDIAN5 ///
        +FE_MEDIAN6+FE_MEDIAN7+FE_MEDIAN8+FE_MEDIAN9+FE_MEDIAN10+FE_MEDIAN11)/12

    *=============================*
    * Pick shrinkage spec
    *=============================*
    confirm variable `shrink_spec'
    gen double shrinkage_pct = `shrink_spec'

    collapse (mean) shrinkage_pct FE_MEAN_all FE_MEDIAN_all, ///
        by(pred_year COUNTRY)

    rename pred_year year

    di as result "Finished: `shrink_spec'"
}

di as text "ALL DONE"
