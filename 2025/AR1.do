/*********************************************************************
* 0. 初期設定
*********************************************************************/

clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
// global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/merged_data.dta, clear
/*********************************************************************
* 1. 基本フィルタと派生変数
*********************************************************************/
gen horizon = eym - sym
keep if horizon == 0
keep if eyear >= 2000
keep COUNTRY TICKER ACTUAL eyear

* TICKER と COUNTRY を結合して企業識別子を作る
gen str firmid_str = TICKER + "_" + COUNTRY

* 数値IDに変換（encode）
encode firmid_str, gen(firmid)

bysort firmid eyear: gen dup = _N   // 同じ組み合わせの件数
drop if dup > 1                      // 重複があるグループは全削除
* パネル時系列設定
xtset firmid eyear                   // パネル時系列の設定

* 各 firmid ごとに AR(1) 回帰
gen ar1_coef = .
gen ar1_se   = .

gen L_ACTUAL = L.ACTUAL   // 先に全体でラグを作っておく
levelsof firmid, local(firms)
foreach f of local firms {
    quietly count if firmid == `f' & !missing(ACTUAL, L_ACTUAL)
    if r(N) >= 2 {
        quietly reg ACTUAL L_ACTUAL if firmid == `f'
        replace ar1_coef = _b[L_ACTUAL] if firmid == `f'
        replace ar1_se   = e(rmse)      if firmid == `f'
    }
}


drop eyear   // もう不要なら削除

duplicates drop

export delimited using "$mypath/ar.csv", replace
