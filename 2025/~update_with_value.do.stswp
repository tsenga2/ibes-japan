/*********************************************************************
* 0. 初期設定
*********************************************************************/

clear
set more off
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
/* winsor2 が未導入なら：
   ssc install winsor2, replace                                */

use $mypath/merged_data.dta, clear


/*********************************************************************
* 1. 基本フィルタと派生変数
*********************************************************************/

keep if inlist(CURR_ACT,"USD","JPY","EUR","CAD","CNY","BPN")
gen horizon = eym - sym                                        // 0–10 を想定

/*------------------------------------------------------------------*
 | VALUE1 が初めて入る行まではフラグを欠損 . にし、                 |
 | その行では flag_VALUE1=1, 他の flag_VALUE*=0                    |
 | 以降は前行と値が違えば 1, 同じなら 0                            |
 *------------------------------------------------------------------*/

sort TICKER eym sym

*【1】ブロック内で VALUE1 出現をトレース
by TICKER eym: gen byte started = !missing(VALUE1)
by TICKER eym: replace  started = sum(started)     // 0→1→2→…

*【2】VALUE* の変化フラグ
foreach v of varlist VALUE* {
    gen flag_`v' = cond(started, (`v' != `v'[_n-1]), .)
}

*【3】VALUE1 が初めて入った行の特別処理
by TICKER eym: gen byte firstrow = started==1 & (_n==1 | started[_n-1]==0)
replace flag_VALUE1 = 1 if firstrow
foreach v of varlist VALUE* {
    if "`v'" != "VALUE1" replace flag_`v' = 0 if firstrow
}

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
        if r(N)>0 local lab `lab' `=r(mean)' "`y'"
    }
    return local xlabel "`lab'"
end


/*********************************************************************
* 3. 通貨ループ：Disagreement & RMSE
*      – All forecasts
*      – Updated ≥1
*      – Updated ＆ VALUE change (flag_forecaster*=1 かつ flag_VALUE*=1)
*********************************************************************/

local curlist USD JPY EUR CAD CNY BPN
local graphsA ""
local graphsB ""

foreach cur of local curlist {

    preserve
    keep if CURR_ACT=="`cur'" & inrange(syear,2014,2024) & inrange(horizon,0,10)

    /*--------------------------------------------------------------*
     | 3-1. 行フラグ：どれかの VALUE* が変化したか                   |
     *--------------------------------------------------------------*/
    gen byte flag_valchg = 0
    foreach v of varlist flag_VALUE* {
        replace flag_valchg = 1 if flag_valchg==0 & `v'==1   // ← 修正箇所
    }

    /*--------------------------------------------------------------*
     | 3-2. 集計用変数を初期化                                       |
     *--------------------------------------------------------------*/
    foreach g in a u1 uv {
        gen double sum_`g'     = 0
        gen double count_`g'   = 0
        gen double sumsqs_`g'  = 0
        gen double sqerr_`g'   = 0
    }

    /*--------------------------------------------------------------*
     | 3-3. forecaster1–112 をループ                                 |
     *--------------------------------------------------------------*/
    forvalues i = 1/112 {

        /*--- All forecasts ---*/
        quietly replace sum_a     = sum_a     + forecaster`i' ///
            if !missing(forecaster`i')
        quietly replace count_a   = count_a   + 1 ///
            if !missing(forecaster`i')
        quietly replace sumsqs_a  = sumsqs_a  + forecaster`i'^2 ///
            if !missing(forecaster`i')
        quietly replace sqerr_a   = sqerr_a   + ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
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

        /*--- Updated & VALUE change (uv) ---*/
        quietly replace count_uv  = count_uv + 1 ///
            if flag_forecaster`i'==1 & flag_valchg==1 & !missing(forecaster`i')
        quietly replace sum_uv    = sum_uv   + forecaster`i' ///
            if flag_forecaster`i'==1 & flag_valchg==1 & !missing(forecaster`i')
        quietly replace sumsqs_uv = sumsqs_uv + forecaster`i'^2 ///
            if flag_forecaster`i'==1 & flag_valchg==1 & !missing(forecaster`i')
        quietly replace sqerr_uv  = sqerr_uv + ((forecaster`i'-ACTUAL)/ACTUAL)^2 ///
            if flag_forecaster`i'==1 & flag_valchg==1 & !missing(forecaster`i')
    }

    /*--------------------------------------------------------------*
     | 3-4. Disagreement（stdev）と RMSE                            |
     *--------------------------------------------------------------*/
    foreach g in a u1 uv {
        gen stdev_`g' = sqrt((sumsqs_`g' - (sum_`g'^2)/count_`g')/(count_`g'-1)) ///
            if count_`g' >= 2
        gen rmse_`g'  = sqrt(sqerr_`g' / count_`g') if count_`g' >= 2
    }

    /*--------------------------------------------------------------*
     | 3-5. Winsorize → 年×horizon 平均                             |
     *--------------------------------------------------------------*/
    winsor2 stdev_a stdev_u1 stdev_uv rmse_a rmse_u1 rmse_uv, ///
        suffix(_w) cuts(10 90)

    collapse (mean) ///
        stdev_all = stdev_a_w   ///
        stdev_u1  = stdev_u1_w  ///
        stdev_uv  = stdev_uv_w  ///
        rmse_all  = rmse_a_w    ///
        rmse_u1   = rmse_u1_w   ///
        rmse_uv   = rmse_uv_w,  ///
        by(syear horizon)

    /*--------------------------------------------------------------*
     | 3-6. 横軸生成 & xlabel                                       |
     *--------------------------------------------------------------*/
    make_xpos
    quietly build_xlabel
    local xlabel "`r(xlabel)'"

    /*--------------------------------------------------------------*
     | 3-7. twoway コマンド                                         |
     *--------------------------------------------------------------*/
    local cmd_stdev ""
    local cmd_rmse  ""
    levelsof syear, local(yrs)
    foreach y of local yrs {
        local cmd_stdev `cmd_stdev' ///
            (line stdev_all xpos if syear==`y', sort lcolor(black) lwidth(med)) ///
            (line stdev_u1  xpos if syear==`y', sort lcolor(red)   lwidth(med)) ///
            (line stdev_uv  xpos if syear==`y', sort lcolor(blue)  lwidth(med) lpattern(dash))
        local cmd_rmse  `cmd_rmse' ///
            (line rmse_all xpos if syear==`y', sort lcolor(black) lwidth(med)) ///
            (line rmse_u1  xpos if syear==`y', sort lcolor(red)   lwidth(med)) ///
            (line rmse_uv  xpos if syear==`y', sort lcolor(blue)  lwidth(med) lpattern(dash))
    }

    * Panel A: Disagreement
    twoway `cmd_stdev', xlabel(`xlabel') xtitle("Year") ///
        ytitle("Disagreement (stdev)") legend(off) ///
        title("`cur'") name(gA_`cur', replace)
    local graphsA "`graphsA' gA_`cur'"

    * Panel B: RMSE
    twoway `cmd_rmse',  xlabel(`xlabel') xtitle("Year") ///
        ytitle("RMSE (percent)") legend(off) ///
        title("`cur'") name(gB_`cur', replace)
    local graphsB "`graphsB' gB_`cur'"

    restore
}


/*********************************************************************
* 4. グラフの結合・書き出し
*********************************************************************/

* Panel A
graph combine `graphsA', cols(3) imargin(vtiny) ///
    title("Panel A: Disagreement (All vs Updated ≥1 vs VALUE change, 2014–2024)") ///
    name(panelA_main, replace)
graph export "panelA_disagreement_overlay.png", width(2400) replace

* Panel B
graph combine `graphsB', cols(3) imargin(vtiny) ///
    title("Panel B: RMSE (All vs Updated ≥1 vs VALUE change, 2014–2024)") ///
    name(panelB_main, replace)
graph export "panelB_rmse_overlay.png", width(2400) replace
