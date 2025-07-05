/*********************************************************************
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

*****************************************************
* 0. 並べ替え                                               
sort TICKER eym sym   // 「時間順」になる変数を最後に置いておく

*****************************************************
* 1. ブロック内で VALUE1 が出現したかを判定
by TICKER eym: gen byte started = !missing(VALUE1)     // 非欠損なら 1
by TICKER eym: replace  started = sum(started)         // 累積和 → 0/1/2…

/* started == 0   : VALUE1 がまだ欠損（フラグはすべて .）
   started == 1   : VALUE1 が初めて入った行（flag_VALUE1 だけ 1）
   started >= 2   : 2 行目以降（通常の変化フラグを立てる）            */

*****************************************************
* 2. VALUE* の変化フラグを作成（started ≥ 1 の行だけ）
foreach v of varlist VALUE* {
    gen flag_`v' = cond(started, (`v' != `v'[_n-1]), .)
}

*****************************************************
* 3. 「VALUE1 が初めて入った行」の特別処理
by TICKER eym: gen byte firstrow = started==1 & (_n==1 | started[_n-1]==0)

replace flag_VALUE1 = 1 if firstrow          // その行だけ 1
foreach v of varlist VALUE* {
    if "`v'" != "VALUE1" {
        replace flag_`v' = 0 if firstrow     // ほかは 0
    }
}

*****************************************************
* 4. 仕上げ（不要なら削除）
drop started firstrow




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

/*─ 2-2. xlabel マクロを返す ─*/
capture program drop build_xlabel
program define build_xlabel, rclass
    local lab
    levelsof syear, local(yrs)
    foreach y of local yrs {
        quietly summarize xpos if syear==`y'
        if r(N)>0 {
            local lab `lab' `=r(mean)' "`y'"
        }
    }
    return local xlabel "`lab'"
end

/*********************************************************************
* 3. 通貨ループ：Disagreement & RMSE
*    ・All forecasts
*    ・Updated ≥1 (手計算)
*    ・Updated ≥3
*********************************************************************/

local curlist USD JPY EUR CAD CNY BPN
local graphsA ""
local graphsB ""

foreach cur of local curlist {

    preserve
    keep if CURR_ACT=="`cur'" & inrange(syear,2014,2024) & inrange(horizon,0,10)

    /* 3-1. 行単位で集計 */
    gen double sum_a     = 0
    gen double count_a   = 0
    gen double sumsqs_a  = 0
    gen double sqerr_a   = 0

    gen double sum_u1    = 0      // Updated ≥1
    gen double count_u1  = 0
    gen double sumsqs_u1 = 0
    gen double sqerr_u1  = 0

    gen double sum_u3    = 0      // Updated ≥3
    gen double count_u3  = 0
    gen double sumsqs_u3 = 0
    gen double sqerr_u3  = 0

    forvalues i = 1/112 {

        /*--- All forecasts ---*/
        quietly replace sum_a     = sum_a   + forecaster`i' ///
            if !missing(forecaster`i')
        quietly replace count_a   = count_a + 1 ///
            if !missing(forecaster`i')
        quietly replace sumsqs_a  = sumsqs_a + forecaster`i'^2 ///
            if !missing(forecaster`i')
        quietly replace sqerr_a   = sqerr_a + ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
            if !missing(forecaster`i')

        /*--- Updated ≥1 ---*/
        quietly replace count_u1  = count_u1 + 1 ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sum_u1    = sum_u1   + forecaster`i' ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sumsqs_u1 = sumsqs_u1 + forecaster`i'^2 ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')
        quietly replace sqerr_u1  = sqerr_u1 + ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
            if flag_forecaster`i'==1 & !missing(forecaster`i')

        /*--- Updated ≥3 ---*/
        quietly replace count_u3  = count_u3 + 1 ///
            if flag_u3_`i' & !missing(forecaster`i')
        quietly replace sum_u3    = sum_u3   + forecaster`i' ///
            if flag_u3_`i' & !missing(forecaster`i')
        quietly replace sumsqs_u3 = sumsqs_u3 + forecaster`i'^2 ///
            if flag_u3_`i' & !missing(forecaster`i')
        quietly replace sqerr_u3  = sqerr_u3 + ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
            if flag_u3_`i' & !missing(forecaster`i')
    }

    /* 3-2. Disagreement（stdev）と RMSE */
    gen stdev_all = sqrt((sumsqs_a  - (sum_a^2) / count_a ) /(count_a -1)) if count_a >=2
    gen rmse_all  = sqrt(sqerr_a  / count_a)                                if count_a >=2

    gen stdev_u1  = sqrt((sumsqs_u1 - (sum_u1^2)/count_u1)/(count_u1-1))   if count_u1>=2
    gen rmse_u1   = sqrt(sqerr_u1 / count_u1)                              if count_u1>=2

    gen stdev_u3  = sqrt((sumsqs_u3 - (sum_u3^2)/count_u3)/(count_u3-1))   if count_u3>=2
    gen rmse_u3   = sqrt(sqerr_u3 / count_u3)                              if count_u3>=2

    /* 3-3. Winsorize → 年×horizon 平均 */
    winsor2 stdev_all stdev_u1 stdev_u3 rmse_all rmse_u1 rmse_u3, suffix(_w) cuts(10 90)
    collapse (mean) ///
        stdev_all = stdev_all_w ///
        stdev_u1  = stdev_u1_w  ///
        stdev_u3  = stdev_u3_w  ///
        rmse_all  = rmse_all_w  ///
        rmse_u1   = rmse_u1_w   ///
        rmse_u3   = rmse_u3_w, by(syear horizon)

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
            (line stdev_all xpos if syear==`y', sort lcolor(black) lwidth(med)) ///
            (line stdev_u1  xpos if syear==`y', sort lcolor(red)   lwidth(med)) ///
            (line stdev_u3  xpos if syear==`y', sort lcolor(blue)  lwidth(med) lpattern(dash))
        local cmd_rmse  `cmd_rmse' ///
            (line rmse_all xpos if syear==`y', sort lcolor(black) lwidth(med)) ///
            (line rmse_u1  xpos if syear==`y', sort lcolor(red)   lwidth(med)) ///
            (line rmse_u3  xpos if syear==`y', sort lcolor(blue)  lwidth(med) lpattern(dash))
    }

    /* 3-6. Panel A（Disagreement）*/
    twoway `cmd_stdev', xlabel(`xlabel') xtitle("Year") ///
        ytitle("Disagreement (stdev)") legend(off) ///
        title("`cur'") name(gA_`cur', replace)
    local graphsA "`graphsA' gA_`cur'"

    /* 3-7. Panel B（RMSE）*/
    twoway `cmd_rmse',  xlabel(`xlabel') xtitle("Year") ///
        ytitle("RMSE (percent)") legend(off) ///
        title("`cur'") name(gB_`cur', replace)
    local graphsB "`graphsB' gB_`cur'"

    restore
}

/*********************************************************************
* 4. Panel A 結合（レジェンドなし）＋小レジェンド作成
*********************************************************************/

graph combine `graphsA', cols(3) imargin(vtiny) ///
    title("Panel A: Disagreement (All vs Updated ≥1 vs ≥3, 2014–2024)") ///
    name(panelA_main, replace)
graph export "panelA_disagreement_overlay.png", width(2400) replace

/* 共通レジェンドだけの小さなグラフ */
clear
set obs 3
gen x = _n
gen
