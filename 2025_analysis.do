global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/merged_data.dta, clear

drop if missing(NUMUP)

gen value_updated = 0

foreach v of varlist VALUE1-VALUE7 {
       replace value_updated = 1 if `v' != `v'[_n-1]
}



gen updated_f = 1 if (NUMUP != 0) | (NUMDOWN != 0)

replace updated_f = 0 if missing(updated_f)

pwcorr value_updated updated_f, sig

gen both_update = (updated_f == 1 & value_updated == 1)

* updated_f == 1 & value_updated == 1 → 両方更新された行をカウント
count if both_update == 1
local num_both = r(N)

* updated_f == 1 の行をカウント（予測が更新された行数）
count if updated_f == 1
local total_update = r(N)

* 割合を表示
display "ratio: " 100 * `num_both' / `total_update'


gen value_updated_lag1 = .
bysort TICKER eym (sym): replace value_updated_lag1 = value_updated[_n-1]

gen both_update_lag = (updated_f == 1 & value_updated_lag1 == 1)
count if both_update_lag == 1
local num_both_lag = r(N)

count if updated_f == 1
local total_update = r(N)

display "1ヶ月ラグ込みの割合: " 100 * `num_both_lag' / `total_update'

* 即時反応
gen reacted_immediate = (value_updated == 1 & updated_f == 1)

* 1か月ラグの予測更新を取り出す
gen updated_f_lead1 = .
bysort TICKER (eym): replace updated_f_lead1 = updated_f[_n+1]

* ラグ反応
gen reacted_lagged = (value_updated == 1 & updated_f_lead1 == 1)

* どちらかで反応していればOK
gen reacted_either = reacted_immediate | reacted_lagged


* 集計：月別で数える
collapse (sum) value_updated reacted_immediate, by(eym)

* 割合を計算（%）
gen update_ratio = 100 * reacted_immediate / value_updated


twoway line update_ratio eym, ///
    title("VALUEと予測が両方更新された割合（時系列）") ///
    ylabel(0(10)100) ///
    xtitle("年月（eym）") ///
    ytitle("割合（%）") ///
    lwidth(medium) lcolor(blue) ///
    graphregion(color(white)) legend(off)







