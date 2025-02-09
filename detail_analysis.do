cls
clear all
set graph on

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/international"
use $mypath/ibes-detail-international.dta, clear

keep if CURR == "JPY"
drop if missing(ACTUAL)


egen group_actual = group(ACTUAL)
egen group_analys = group(ANALYS)

egen update_frequency = nvals(VALUE), by(group_actual group_analys)

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



