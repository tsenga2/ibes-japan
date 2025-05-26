clear
global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/merged_data.dta, clear

**************************************************************
* 0. 前提：6通貨だけに絞る（USD JPY EUR CAD CNY BPN）
**************************************************************
keep if inlist(CURR_ACT, "USD", "JPY", "EUR", "CAD", "CNY", "BPN")
gen horizon = eym - sym
**************************************************************
* 1. 処理する通貨リストをローカルに
**************************************************************
local curlist USD JPY EUR CAD CNY BPN

**************************************************************
* 2. 通貨ループ
**************************************************************
foreach cur of local curlist {

    preserve                               // 元データ保存

    * --- 2-1. 通貨と範囲をフィルタ ---
    keep if CURR_ACT == "`cur'"           ///
        & inrange(syear, 2014, 2024)      ///
        & inrange(horizon, 0, 10)

    * --- 2-2. winsorize & 平均化 ---
    winsor2 STDEV, suffix(_w) cuts(10 90)
    collapse (mean) stdev = STDEV_w, by(syear horizon)

    * --- 2-3. xpos の生成（horizon 10→0 を年ごとに並べる） ---
    gen xpos = .
    local base = 1
    levelsof syear, local(years)
    foreach y of local years {
        replace xpos = `base' + (10 - horizon) if syear == `y'
        local base = `base' + 11
    }

    * --- 2-4. 線・点・凡例コマンドを構築 ---
    levelsof syear, local(years)      // その通貨だけの年リスト
    local cmd_lines
    local cmd_dots
    local legend
    local i = 1

    foreach y of local years {
        local cmd_lines `cmd_lines' ///
            (line stdev xpos if syear==`y', sort lcolor(black) lpattern(solid))
        local cmd_dots  `cmd_dots'  ///
            (scatter stdev xpos if syear==`y', mcolor(black) msymbol(circle))
        local legend `legend' `i' "`y'"
        local i = `i' + 1
    }

    * --- 2-5. x軸ラベル（各年の horizon==5 の位置に年を表示） ---
    local xlabelspec
    foreach y of local years {
        quietly summarize xpos if syear == `y' & horizon == 5
        local xpos = r(mean)
        local xlabelspec `xlabelspec' `xpos' "`y'"
    }

    * --- 2-6. グラフを描画して保存 ---
    twoway `cmd_lines' `cmd_dots',                           ///
        xlabel(`xlabelspec', labsize(small) angle(0))       ///
        xtitle("Year") ytitle("Disagreement (stdev)")       ///
        legend(order(`legend'))                             ///
        title("`cur'", size(medium))                        ///
        graphregion(color(white)) plotregion(style(none))   ///
        name(g_`cur', replace)                              // ← グラフ名を g_USD などに

    restore                                // 元データに戻る
}

**************************************************************
* 3. 6枚のグラフを 2×3 レイアウトで結合
**************************************************************
graph combine g_USD g_JPY g_EUR g_CAD g_CNY g_BPN, ///
    cols(3) title("Panel A: Disagreement by Horizon and Year (2014–2024)")

**************************************************************
* 4. （任意）PNG 書き出し
**************************************************************
graph export "panelA_disagreement.png", width(2400) replace
