clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
use $mypath/merged_data.dta, clear

* 基本フィルタ
keep if inlist(COUNTRY, "NA", "FJ", "EX")
gen horizon = eym - sym
sort TICKER eym sym

* 一時的に 4回以上アップデートフラグの合計と観測数を計算
egen over4 = rowtotal(flag_u4_*) 
egen total = rownonmiss(forecaster*)

preserve
keep if horizon == 0
collapse (mean) over4 total (first) COUNTRY, by(TICKER eym)
gen ratio = over4 / total

collapse (mean) ratio, by(COUNTRY)
list COUNTRY ratio, noobs
