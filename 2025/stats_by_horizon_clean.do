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

* Horizon変数を作成
gen horizon = eym - sym

* 対象範囲のみに限定
keep if inrange(horizon, 0, 11) & eyear >= 2000

sort TICKER eym sym

* ============================================
* u4のみを使った分散・RMSE と 予想の平均を作成
* 全予想者の平均も計算
* ============================================
gen disagreement_u4 = .
gen rmse_u4         = .

tempvar sum_x sum_x2 count se_sum sum_all count_all
gen double `sum_x'     = 0
gen double `sum_x2'    = 0
gen double `count'     = 0
gen double `se_sum'    = 0
gen double `sum_all'   = 0
gen double `count_all' = 0

forvalues i = 1/112 {
    gen byte _use_u4_`i'  = flag_u4_`i' == 1 & !missing(forecaster`i') & !missing(ACTUAL)
    gen byte _use_all_`i' = !missing(forecaster`i') & !missing(ACTUAL)
    
    replace `sum_x'     = `sum_x'   + forecaster`i'              if _use_u4_`i'
    replace `sum_x2'    = `sum_x2'  + forecaster`i'^2            if _use_u4_`i'
    replace `count'     = `count'   + 1                          if _use_u4_`i'
    replace `se_sum'    = `se_sum'  + ((forecaster`i'-ACTUAL)^2) if _use_u4_`i'

    * 全予想者の単純平均用
    replace `sum_all'   = `sum_all'   + forecaster`i'            if _use_all_`i'
    replace `count_all' = `count_all' + 1                        if _use_all_`i'

    drop _use_u4_`i' _use_all_`i'
}

replace disagreement_u4 = sqrt((`sum_x2' - (`sum_x'^2)/`count') / (`count' - 1)) if `count' >= 2
replace rmse_u4         = sqrt(`se_sum'   / `count')                             if `count' >= 1

* 予想の平均（u4 / 全予想者）
gen forecast_mean_u4  = `sum_x'   / `count'     if `count'     >= 1
gen forecast_mean_all = `sum_all' / `count_all' if `count_all' >= 1

drop `sum_x' `sum_x2' `count' `se_sum' `sum_all' `count_all'

* ============================================================
* 外れ値処理：各国ごとに上位10%を除外（disagreement_u4ベース）
* ============================================================
bys COUNTRY: egen p90_dis  = pctile(disagreement_u4), p(90)
bys COUNTRY: egen p90_rmse = pctile(rmse_u4),         p(90)

drop if disagreement_u4 > p90_dis
* drop if rmse_u4 > p90_rmse   // rmseでもtrimmingする場合は解除
drop p90_dis p90_rmse

* ------------------------------------------------------------
* 企業数（unique TICKER）を作成：トリミング後のデータで計上
* 1) COUNTRY × eyear × horizon 単位
* 2) COUNTRY × horizon 単位（依頼どおり）
* ------------------------------------------------------------
egen byte tag_ceh = tag(COUNTRY eyear horizon TICKER)
bys COUNTRY eyear horizon: egen n_ticker_ceh = total(tag_ceh)
drop tag_ceh

egen byte tag_ch = tag(COUNTRY horizon TICKER)
bys COUNTRY horizon: egen n_ticker_ch = total(tag_ch)
drop tag_ch

* ------------------------------------------------------------
* 集計：COUNTRY×eyear×horizon
* STDEV があればmeanとmedianで集計
* ------------------------------------------------------------
local extra ""
capture confirm variable STDEV
if _rc == 0 local extra " (mean) STDEV (mean) MEDEST"

collapse (mean) ACTUAL forecast_mean_u4 forecast_mean_all ///
                 disagreement_u4 rmse_u4 `extra' ///
         (max)  n_ticker_ceh n_ticker_ch, ///
         by(COUNTRY eyear horizon)

rename disagreement_u4         disagreement_u4_avg
rename rmse_u4                 rmse_u4_avg
rename ACTUAL                  ACTUAL_avg
rename forecast_mean_u4        forecast_mean_u4_avg
rename forecast_mean_all       forecast_mean_all_avg
rename n_ticker_ceh            n_ticker_unique_ceh   // 国×年×horizonのユニーク企業数
rename n_ticker_ch             n_ticker_unique_ch    // 国×horizonのユニーク企業数

* 出力
export delimited using "$mypath/stats_by_horizon_clean.csv", replace

* 確認表示
list COUNTRY eyear horizon n_ticker_unique_ceh n_ticker_unique_ch ///
     ACTUAL_avg forecast_mean_u4_avg forecast_mean_all_avg ///
     disagreement_u4_avg rmse_u4_avg, noobs
