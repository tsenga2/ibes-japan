これで作ってるdisagreement(=stdev)、genじゃなくて、元々データセットにSTDEV列あるからそれを使うように書き換えて：/*********************************************************************
* 0. 初期設定
*********************************************************************/

clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
// global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"

/* winsor2 が未導入なら：  ssc install winsor2, replace */

use $mypath/merged_data.dta, clear

/*********************************************************************
* 1. 基本フィルタと派生変数
*********************************************************************/

keep if inlist(CURR_ACT,"USD","JPY","EUR","CAD","CNY","BPN")
gen horizon = eym - sym          // 0–10 を想定

/*********************************************************************
* 2. サブルーチン定義
*********************************************************************/

/*─ 2-1. 年×horizon を横並びにする横軸 ─*/
capture program drop make_xpos
program define make_xpos
    gen double xpos = .
    local base = 1
    levelsof syear, local(yrs)
    foreach y of local yrs {
        replace xpos = `base' + (10 - horizon) if syear == `y'
        local base  = `base' + 11
    }
end

/*─ 2-2. xlabel マクロを返す（欠損値 "." を除く） ─*/
capture program drop build_xlabel
program define build_xlabel, rclass
    local lab
    levelsof syear, local(yrs)
    foreach y of local yrs {
        quietly summarize xpos if syear==`y'
        if r(N)>0 {                       // データがある年だけ
            local lab `lab' `=r(mean)' "`y'"
        }
    }
    return local xlabel "`lab'"
end

/*********************************************************************
* 3. 通貨ループ：Disagreement & RMSE（Updated 定義で統一）
*********************************************************************/

local curlist USD JPY EUR CAD CNY BPN
local graphsA ""
local graphsB ""

foreach cur of local curlist {

    preserve
    keep if CURR_ACT=="`cur'" & inrange(syear,2014,2024) & inrange(horizon,0,10)

    /* 3-1. 行単位で Updated 予測だけ集計 */
    gen double sum_u     = 0
    gen double count_u   = 0
    gen double sumsqs_u  = 0
    gen double sqerr_u   = 0        // ← RMSE 用

    forvalues i = 1/112 {
        quietly replace sum_u     = sum_u   + forecaster`i'            ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace count_u   = count_u + 1                        ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sumsqs_u  = sumsqs_u+ forecaster`i'^2          ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sqerr_u   = sqerr_u +                          ///
            ((forecaster`i'-ACTUAL)/ACTUAL)^2                          ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
    }

    /* 3-2. "Disagreement"=Updated 予測だけの stdev */
    gen stdev = sqrt((sumsqs_u - (sum_u^2)/count_u)/(count_u-1)) if count_u>=2
    gen rmse  = sqrt(sqerr_u / count_u)                           if count_u>=2

    /* 3-3. Winsorize → 年×horizon 平均 */
    winsor2 stdev rmse, suffix(_w) cuts(10 90)
    collapse (mean) stdev = stdev_w rmse = rmse_w, by(syear horizon)

    /* 3-4. 横軸生成 & xlabel */
    make_xpos
    quietly build_xlabel
    local xlabel "`r(xlabel)'"

    /* 3-5. twoway コマンド */
    local cmd_stdev ""
    local cmd_rmse  ""
    levelsof syear, local(yrs)
    foreach y of local yrs {
        local cmd_stdev `cmd_stdev' ///
            (line stdev xpos if syear==`y', sort lcolor(black) lwidth(med))
        local cmd_rmse  `cmd_rmse'  ///
            (line rmse  xpos if syear==`y', sort lcolor(black) lwidth(med))
    }

    /* 3-6. Panel A（Disagreement）*/
    twoway `cmd_stdev', xlabel(`xlabel') xtitle("Year") ///
        ytitle("Disagreement (stdev, updated)") legend(off) ///
        title("`cur'") name(gA_`cur', replace)
    local graphsA "`graphsA' gA_`cur'"

    /* 3-7. Panel B（RMSE）*/
    twoway `cmd_rmse',  xlabel(`xlabel') xtitle("Year") ///
        ytitle("RMSE (percent, updated)") legend(off) ///
        title("`cur'") name(gB_`cur', replace)
    local graphsB "`graphsB' gB_`cur'"

    restore
}


/*********************************************************************
* 4. Panel A 結合（レジェンドなし）＋小レジェンド作成
*********************************************************************/

graph combine `graphsA', cols(3) imargin(vtiny) ///
    title("Panel A: Disagreement (All vs Updated, 2001–2024)") ///
    name(panelA_main, replace)
graph export "panelA_disagreement_overlay.png", width(2400) replace

/* 共通レジェンドだけの小さなグラフ */
clear
set obs 2
gen x = _n
gen y = x

twoway ///
    (line y x if x==1, lcolor(black) lwidth(med)) ///
    (line y x if x==2, lcolor(red)   lwidth(med) lpattern(dash)), ///
    legend(order(1 "All forecasts" 2 "Updated forecasts") ///
           size(small) row(1)) ///
    xtitle("") ytitle("") xlabel("") ylabel("") title("") ///
    plotregion(margin(zero)) graphregion(color(white)) ///
    name(panelA_legend, replace)
graph export "panelA_disagreement_legend.png", width(800) replace

/*********************************************************************
* 5. Panel B 結合（レジェンド付き）
*********************************************************************/

graph combine `graphsB', cols(3) imargin(vtiny) ///
    title("Panel B: RMSE (All vs Updated, 2001–2024)") ///
    name(panelB_main, replace)
graph export "panelB_rmse_overlay.png", width(2400) replace
