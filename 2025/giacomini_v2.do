/*********************************************************************
* 0. 初期設定
*********************************************************************/

clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
// global mypath "/Users/tsenga/ibes-japan/IBES/international"

use $mypath/merged_data.dta, clear

/*********************************************************************
* 1. 基本フィルタと派生変数
*********************************************************************/

keep if inlist(CURR_ACT,"USD","JPY","EUR","CAD","CNY","BPN")
gen horizon = eym - sym          // 0–10 を想定

/*********************************************************************
* 2. サブルーチン定義
*********************************************************************/

// ── 2-1. 年×horizon を横並びにする軸 ──
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

// ── 2-2. xlabel マクロを返す ──
capture program drop build_xlabel
program define build_xlabel, rclass
    local lab
    levelsof syear, local(yrs)
    foreach y of local yrs {
        quietly summarize xpos if syear==`y' & horizon==5
        local mid = r(mean)
        local lab `lab' `mid' "`y'"
    }
    return local xlabel "`lab'"
end

/*********************************************************************
* 3. 通貨ループ：Disagreement & RMSE（All vs Updated）
*********************************************************************/

local curlist USD JPY EUR CAD CNY BPN
local graphsA ""          // ← 空文字で初期化
local graphsB ""

foreach cur of local curlist {

    preserve
    keep if CURR_ACT=="`cur'" & inrange(syear,2001,2024) & inrange(horizon,0,10)

    /*─ 3-1. 行方向で集計（reshape せず） ─*/
    gen double sum_all     = 0
    gen double count_all   = 0
    gen double sumsqs_all  = 0
    gen double sqerr_all   = 0

    gen double sum_upd     = 0
    gen double count_upd   = 0
    gen double sumsqs_upd  = 0
    gen double sqerr_upd   = 0

    forvalues i = 1/112 {

        /* 全 forecaster */
        quietly replace sum_all     = sum_all   + forecaster`i' ///
            if !missing(forecaster`i')
        quietly replace count_all   = count_all + 1 ///
            if !missing(forecaster`i')
        quietly replace sumsqs_all  = sumsqs_all+ forecaster`i'^2 ///
            if !missing(forecaster`i')
        quietly replace sqerr_all   = sqerr_all + ///
            ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
            if !missing(forecaster`i')

        /* 更新 forecaster だけ */
        quietly replace sum_upd     = sum_upd   + forecaster`i' ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace count_upd   = count_upd + 1 ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sumsqs_upd  = sumsqs_upd+ forecaster`i'^2 ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sqerr_upd   = sqerr_upd + ///
            ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
    }

    /*─ 3-2. 行ごとの Disagreement / RMSE を作成 ─*/
    gen stdev_all = sqrt((sumsqs_all - (sum_all^2)/count_all)/(count_all-1)) ///
        if count_all >= 2
    gen stdev_upd = sqrt((sumsqs_upd - (sum_upd^2)/count_upd)/(count_upd-1)) ///
        if count_upd >= 2

    gen rmse_all  = sqrt(sqerr_all / count_all) if count_all >= 2
    gen rmse_upd  = sqrt(sqerr_upd / count_upd) if count_upd >= 2

    /*─ 3-3. Winsorize → 年×horizon 平均 ─*/
    winsor2 stdev_all stdev_upd rmse_all rmse_upd, suffix(_w) cuts(10 90)

    collapse (mean) stdev_all_w stdev_upd_w rmse_all_w rmse_upd_w, ///
        by(syear horizon)

    rename (stdev_all_w stdev_upd_w rmse_all_w rmse_upd_w) ///
           (stdev_all  stdev_upd  rmse_all  rmse_upd)

    /*─ 3-4. 横軸生成 & xlabel ─*/
    make_xpos
    quietly build_xlabel
    local xlabel "`r(xlabel)'"

    /*─ 3-5. 年ごとに線を分けるコマンドを構築 ─*/
    local cmd_stdev
    local cmd_rmse
    levelsof syear, local(yrs)

    foreach y of local yrs {
        local cmd_stdev `cmd_stdev' ///
            (line stdev_all xpos if syear==`y', ///
                  sort lcolor(black) lwidth(med)) ///
            (line stdev_upd xpos if syear==`y', ///
                  sort lcolor(red)   lwidth(med) lpattern(dash))

        local cmd_rmse  `cmd_rmse'  ///
            (line rmse_all xpos if syear==`y', ///
                  sort lcolor(black) lwidth(med)) ///
            (line rmse_upd xpos if syear==`y', ///
                  sort lcolor(red)   lwidth(med) lpattern(dash))
    }

    /*─ 3-6. グラフ作成 ─*/
    twoway `cmd_stdev',                                           ///
        xlabel(`xlabel') xtitle("Year")                           ///
        ytitle("Disagreement (stdev)")                            ///
        legend(order(1 2) label(1 "All forecasts") label(2 "Updated forecasts")) ///
        title("`cur'") name(gA_`cur', replace)

    local graphsA "`graphsA' gA_`cur'"

    twoway `cmd_rmse',                                            ///
        xlabel(`xlabel') xtitle("Year")                           ///
        ytitle("RMSE (percent)")                                  ///
        legend(order(1 2) label(1 "All forecasts") label(2 "Updated forecasts")) ///
        title("`cur'") name(gB_`cur', replace)

    local graphsB "`graphsB' gB_`cur'"
    restore
}

/*********************************************************************
* 4. 出力：グラフ結合 & 書き出し
*********************************************************************/

graph combine `graphsA', cols(3) imargin(vtiny) ///
    title("Panel A: Disagreement (All vs Updated, 2001–2024)")
graph export "panelA_disagreement_overlay.png", width(2400) replace

graph combine `graphsB', cols(3) imargin(vtiny) ///
    title("Panel B: RMSE (All vs Updated, 2001–2024)")
graph export "panelB_rmse_overlay.png", width(2400) replace
