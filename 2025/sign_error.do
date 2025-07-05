clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
/* winsor2 が未導入なら：
   ssc install winsor2, replace                                */

use $mypath/merged_data.dta, clear


* 1. 行平均（forecaster1–112 の平均）を作成
egen mean_fcst = rowmean(forecaster*)

* 2. 誤差列（ACTUAL − 平均予想）を作成
gen  error = ACTUAL - mean_fcst
label var error "ACTUAL minus mean(forecaster*)"
