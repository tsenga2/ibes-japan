clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
/* winsor2 が未導入なら：
   ssc install winsor2, replace                                */

use $mypath/merged_data.dta, clear

keep if inlist(CURR_ACT,"USD","JPY","EUR","CAD","CNY","BPN")
gen horizon = eym - sym    

*---forecaster stats---
* forecaster1–112 の列名が forecaster で始まる想定
egen n_fcst_row = rownonmiss(forecaster*)

* 同じ TICKER・eym に複数行（sym など）があっても最大値 1 つで代表させる
collapse (max) n_fcst_row, by(TICKER eym)
rename n_fcst_row n_fcst        // わかりやすい名前に

histogram n_fcst, discrete freq ///
    xlab(0(5)112) xlabel(, angle(vertical)) ///
    title("Number of forecasters per {TICKER, eym}") ///
    xtitle("Forecaster count") ytitle("Frequency")
*-------
