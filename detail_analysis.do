cls
clear all
set graph on

*global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/international"
global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/ibes-detail-international.dta, clear

keep if CURR == "JPY"
drop if missing(ACTUAL)

egen group_actual = group(ACTUAL)
egen group_analys = group(ANALYS)

egen update_frequency = nvals(VALUE), by(group_actual group_analys)

preserve
* ここ再検討しましょうか（アップデート頻度の件ですね）
duplicates drop group_actual group_analys, force

binscatter ACTUAL update_frequency

* 99%パーセンタイルを計算
sum ACTUAL, detail
local p1 = r(p1) 
local p99 = r(p99)

* 上位1%のデータを削除
drop if ACTUAL < `p1' | ACTUAL > `p99'

* binscatter を再描画
binscatter ACTUAL update_frequency

restore
* ここまでですね

* 以下は新たなトライです
egen update_frequency_sum = nvals(VALUE), by(TICKER ESTIMATOR ANALYS FPEDATS)
replace update_frequency_sum = update_frequency_sum - 1

* Calculate summary stats for update_frequency_sum
tabstat update_frequency_sum, stats(n mean sd min p5 p25 p50 p75 p95 max) ///
    columns(statistics) format(%9.2f)

* アップデート頻度のヒストグラム
histogram update_frequency_sum, frequency normal title("Distribution of Update Frequency") ///
    xtitle("Update Frequency") ytitle("Frequency") name(hist_update_frequency, replace)

* 変化率を計算します
sort TICKER ESTIMATOR ANALYS FPEDATS ANNDATS
by TICKER ESTIMATOR ANALYS FPEDATS: gen value_change = ((VALUE - VALUE[_n-1])/VALUE[_n-1])*100 if _n > 1

format value_change %9.2f
label variable value_change "Value Rate of Change (%)"

* なんとなく見やすく順番を変えます
order TICKER CNAME ESTIMATOR ANALYS ANNDATS FPEDATS VALUE value_change update_frequency_sum ACTUAL

* Generate summary statistics
summarize value_change, detail

* Create winsorized version using winsor2
winsor2 value_change, suffix(_wins) cuts(1 99)

* Create visualization
* Histogram of original values
histogram value_change, frequency normal title("Distribution of Value Changes") ///
    xtitle("Percentage Change") ytitle("Frequency") name(hist_value_change, replace)

* Histogram without outliers
histogram value_change_wins, frequency normal title("Distribution of Winsorized Value Changes") ///
    xtitle("Percentage Change") ytitle("Frequency") name(hist_value_change_wins, replace)

* Combine graphs
graph combine hist_update_frequency hist_value_change_wins

* Calculate summary stats for both original and winsorized values
tabstat value_change value_change_wins, stats(n mean sd min p5 p25 p50 p75 p95 max) ///
    columns(statistics) format(%9.2f)





