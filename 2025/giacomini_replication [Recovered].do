**************************************************************
* 0. データ読み込みと前処理
**************************************************************
clear
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/merged_data.dta, clear

**************************************************************
* 1. 通貨・horizon の事前処理
**************************************************************
keep if inlist(CURR_ACT, "USD", "JPY", "EUR", "CAD", "CNY", "BPN")
gen horizon = eym - sym

**************************************************************
* 2. 通貨ごとのループ：Panel A（stdev） & Panel B（rmse_pct）
**************************************************************
local curlist USD JPY EUR CAD CNY BPN

foreach cur of local curlist {
    
    preserve
    
    * --- 2-1. データ絞り込み ---
    keep if CURR_ACT == "`cur'" ///
        & inrange(syear, 2001, 2024) ///
        & inrange(horizon, 0, 10)

    * --- 2-2. Panel A 用：STDEV（Disagreement） ---
    tempvar stdev_w
    winsor2 STDEV, suffix(_w) cuts(10 90)
    collapse (mean) stdev = STDEV_w, by(syear horizon)
    tempfile panelA_`cur'
    save `panelA_`cur'', replace

    restore
    preserve

    * --- 2-3. Panel B 用：RMSE%（Forecast Error） ---
    keep if CURR_ACT == "`cur'" ///
        & inrange(syear, 2001, 2024) ///
        & inrange(horizon, 0, 10)

    gen sq_sum = 0
    gen count_nonmiss = 0

    forvalues i = 1/112 {
        quietly gen err`i' = ((forecaster`i' - ACTUAL)/ACTUAL)^2 if !missing(forecaster`i')
        quietly replace sq_sum = sq_sum + err`i' if !missing(forecaster`i')
        quietly replace count_nonmiss = count_nonmiss + 1 if !missing(forecaster`i')
    }

    gen rmse = sqrt(sq_sum / count_nonmiss) if count_nonmiss >= 2
    drop err*

    winsor2 rmse, suffix(_w) cuts(10 90)
    collapse (mean) rmse = rmse_w, by(syear horizon)
    tempfile panelB_`cur'
    save `panelB_`cur'', replace

    restore
}

**************************************************************
* 3. 各通貨ごとのグラフ作成（AとB 両方）
**************************************************************

foreach cur of local curlist {
    
    * --- 3-1. Panel A ---
    use `panelA_`cur'', clear
    gen xpos = .
    local base = 1
    levelsof syear, local(years)
    foreach y of local years {
        replace xpos = `base' + (10 - horizon) if syear == `y'
        local base = `base' + 11
    }

    local cmd_lines
    local cmd_dots
    local legend
    local xlabelspec
    local i = 1

    foreach y of local years {
        local cmd_lines `cmd_lines' (line stdev xpos if syear==`y', sort lcolor(black))
        local cmd_dots  `cmd_dots'  (scatter stdev xpos if syear==`y', mcolor(black))
        quietly summarize xpos if syear == `y' & horizon == 5
        local xpos = r(mean)
        local xlabelspec `xlabelspec' `xpos' "`y'"
        local legend `legend' `i' "`y'"
        local i = `i' + 1
    }

    twoway `cmd_lines' `cmd_dots', ///
        xlabel(`xlabelspec', labsize(small) angle(0)) ///
        xtitle("Year") ///
        ytitle("Disagreement (stdev)") ///
        legend(order(`legend')) ///
        title("`cur'", size(medium)) ///
        graphregion(color(white)) plotregion(style(none)) ///
        name(gA_`cur', replace)

    * --- 3-2. Panel B ---
    use `panelB_`cur'', clear
    gen xpos = .
    local base = 1
    levelsof syear, local(years)
    foreach y of local years {
        replace xpos = `base' + (10 - horizon) if syear == `y'
        local base = `base' + 11
    }

    local cmd_lines
    local cmd_dots
    local legend
    local xlabelspec
    local i = 1

    foreach y of local years {
        local cmd_lines `cmd_lines' (line rmse xpos if syear==`y', sort lcolor(black))
        local cmd_dots  `cmd_dots'  (scatter rmse xpos if syear==`y', mcolor(black))
        quietly summarize xpos if syear == `y' & horizon == 5
        local xpos = r(mean)
        local xlabelspec `xlabelspec' `xpos' "`y'"
        local legend `legend' `i' "`y'"
        local i = `i' + 1
    }

    twoway `cmd_lines' `cmd_dots', ///
        xlabel(`xlabelspec', labsize(small) angle(0)) ///
        xtitle("Year") ///
        ytitle("RMSE (percent)") ///
        legend(order(`legend')) ///
        title("`cur'", size(medium)) ///
        graphregion(color(white)) plotregion(style(none)) ///
        name(gB_`cur', replace)
}

**************************************************************
* 4. Panel A & B を組み合わせて描画・保存
**************************************************************
graph combine gA_USD gA_JPY gA_EUR gA_CAD gA_CNY gA_BPN, ///
    cols(3) title("Panel A: Disagreement by Horizon and Year (2008–2024)")
graph export "panelA_disagreement.png", width(2400) replace

graph combine gB_USD gB_JPY gB_EUR gB_CAD gB_CNY gB_BPN, ///
    cols(3) title("Panel B: Forecast Error (RMSE%) by Horizon and Year (2008–2024)")
graph export "panelB_rmse.png", width(2400) replace

    /**********************************************************
    * --- 2-4. Panel C 用：平均 Forecast（All vs Updated） ---
    **********************************************************/
	use $mypath/merged_data.dta, clear
gen horizon = eym - sym
    preserve
    
    * ---- データ絞り込み（通貨・年・horizon） ----
    keep if CURR_ACT == "`cur'" ///
        & inrange(syear, 2001, 2024) ///
        & inrange(horizon, 0, 10)
    
    * ---- wide → long へ変換 ----
    gen long rowid = _n
    reshape long forecaster flag_forecaster, i(rowid) j(num)  // ← 112×長くなる
    
    * ---- 全体平均とアップデート平均を計算 ----
    * （1）全体
    collapse (mean) mean_all = forecaster, by(syear horizon eym)      // 一度保存
    tempfile _all
    save "`_all'", replace

    * （2）アップデート済みだけ
    keep if flag_forecaster == 1
    collapse (mean) mean_upd = forecaster, by(syear horizon eym)

    * ---- 2 本の系列を merge ----
    merge 1:1 syear horizon eym using "`_all'", nogen
    
    * ---- Panel C 用の xpos（横軸） ----
    gen xpos = .
    local base = 1
    levelsof syear, local(years)   // 2001‐2024 に存在する年だけ
    foreach y of local years {
        replace xpos = `base' + (10 - horizon) if syear == `y'
        local base = `base' + 11
    }
    
    * ---- xlabel と legend 用のローカル ----
    local xlabelspec
    foreach y of local years {
        * 年ごとの真ん中（horizon==5）の xpos を拾う
        quietly summarize xpos if syear == `y' & horizon == 5
        local xpos_mid = r(mean)
        local xlabelspec `xlabelspec' `xpos_mid' "`y'"
    }
    
    * ---- グラフ描画 ----
    twoway                                                       ///
        (line mean_all xpos, sort lcolor(black)   lwidth(med))   ///
        (line mean_upd xpos, sort lcolor(red)     lwidth(med) lpattern(dash)), ///
        xlabel(`xlabelspec', labsize(small) angle(0))            ///
        xtitle("Year") ytitle("Average forecast")                ///
        legend(order(1 "All forecasts" 2 "Updated forecasts"))   ///
        title("`cur'", size(medium))                             ///
        graphregion(color(white)) plotregion(style(none))        ///
        name(gC_`cur', replace)

    restore

graph combine gC_USD gC_JPY gC_EUR gC_CAD gC_CNY gC_BPN, ///
    cols(3) title("Panel C: Average Forecast (All vs Updated, 2001–2024)")
graph export "panelC_avgforecast.png", width(2400) replace

