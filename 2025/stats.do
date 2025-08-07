clear
set more off
* Set path based on current user
if c(username) == "kawabatahatsu" {
    global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
}
else if c(username) == "tsenga" {
    global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/Both"
}
else {
    display as error "Unknown user. Please set the correct path manually."
    exit
}
use $mypath/merged_data.dta, clear

gen horizon = eym - sym
sort TICKER eym sym

* 4回以上アップデートの合計（per row）
egen over4 = rowtotal(flag_u4_*) 
egen total = rownonmiss(forecaster*)

* 予想者数のカウント
foreach var of varlist forecaster* {
    gen temp_`var' = !missing(`var')
}
egen forecaster_count = rowtotal(temp_forecaster*)
drop temp_forecaster*

* 年度0のみに限定
preserve
keep if horizon == 0

* disagreement（標準偏差）と rmse を、4回以上更新した予想者だけで計算
gen disagreement_u4 = .
gen rmse_u4 = .

tempvar sum_x sum_x2 count se_sum
gen double `sum_x' = 0
gen double `sum_x2' = 0
gen double `count' = 0
gen double `se_sum' = 0

forvalues i = 1/112 {
    gen byte _use_`i' = flag_u4_`i' == 1 & !missing(forecaster`i') & !missing(ACTUAL)
    
    replace `sum_x'  = `sum_x'  + forecaster`i'              if _use_`i'
    replace `sum_x2' = `sum_x2' + forecaster`i'^2            if _use_`i'
    replace `count'  = `count'  + 1                          if _use_`i'
    replace `se_sum' = `se_sum' + ((forecaster`i'-ACTUAL)^2) if _use_`i'

    drop _use_`i'
}

replace disagreement_u4 = sqrt((`sum_x2' - (`sum_x'^2)/`count') / (`count' - 1)) if `count' >= 2
replace rmse_u4 = sqrt(`se_sum' / `count') if `count' >= 1

drop `sum_x' `sum_x2' `count' `se_sum'

* collapse用に企業ID保持
gen firm = TICKER

* TICKER × eym 単位で中間集計
collapse (mean) over4 total forecaster_count disagreement_u4 rmse_u4 (first) COUNTRY eyear, by(TICKER eym)

gen ratio = over4 / total
gen one = 1

* 最終集計：COUNTRY × eyear ごと
collapse ///
    (mean) ratio ///
    (mean) forecaster_count ///
    (sum) over4 total ///
    (count) one ///
    (mean) disagreement_u4 ///
    (mean) rmse_u4, ///
    by(COUNTRY eyear)

rename one firm_count
rename over4 over4_total
rename total total_total
rename disagreement_u4 disagreement_u4_avg
rename rmse_u4 rmse_u4_avg

* 出力（CSV）
export delimited using "$mypath/stats.csv", replace

* 確認表示
list COUNTRY eyear ratio forecaster_count firm_count over4_total total_total disagreement_u4_avg rmse_u4_avg, noobs
