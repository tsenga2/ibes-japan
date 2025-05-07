global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/merged_data.dta, clear
s
* ソートに使う日時変数が sym でなければ適宜変更してください
sort TICKER eym sym

foreach i of numlist 1/7 {
    * 前行と異なれば1、同じなら0
    by TICKER eym: gen byte val_change`i' = (VALUE`i' != VALUE`i'[_n-1])
    * グループ先頭は必ず0
    replace val_change`i' = 0 if _n==1
}

foreach i of numlist 1/34 {
    * 前行と異なれば1、同じなら0
    by TICKER eym: gen byte f_change`i' = (forecaster`i' != forecaster`i'[_n-1])
    * グループ先頭は必ず0
    replace f_change`i' = 0 if _n==1
}

* 例：VALUE1–VALUE7 が対象の場合

egen n_f_change = rowtotal(f_change1-f_change34)
gen byte d_f_change = 0
replace d_f_change = 1 if n_f_change > 0


* 1) パネル宣言（必要なら）
* xtset TICKER eym

* 2) モデル名リスト用のローカルマクロを初期化
local mlist

* 3) ループで logit → estimates store → mlist に追加
forvalues i = 1/4 {
    di as txt "==== val_change`i' モデル ===="
    quietly logit d_f_change val_change`i', vce(cluster TICKER)
    estimates store m`i'
    local mlist "`mlist' m`i'"
}

* 4) 保存されたモデル名を確認（オプション）
estimates dir

* 5) 一括テーブル表示
estimates table `mlist', b(3) se(%9.3f) stats(N ll)

* 1) coefplot がなければインストール
cap which coefplot
if _rc ssc install coefplot, replace

* 2) _cons を除き、val_change1–val_change7 の係数をプロット
coefplot m1 m2 m3 m4, ///
    drop(_cons) /// 定数項は表示しない
    keep(val_change1 val_change2 val_change3 val_change4) /// 変化ダミーだけ
    xline(0) /// 0 の縦線
    vertical /// 垂直プロット（変数名が y 軸）
    xlabel(-2(1)24) /// 必要に応じて調整
    legend(on order(1 "VALUE1" 2 "VALUE2" 3 "VALUE3" 4 "VALUE4")) ///
    title("Change Dummy のロジット係数と95%CI") ///
    ytitle("変数") xtitle("係数 (log-odds)")


stop
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







