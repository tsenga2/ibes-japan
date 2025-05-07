global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/Both"
use "$mypath/merged_data.dta", clear

/******************************************************************
*  前提：銘柄 × 年月（月次）の時系列
*  - TICKER : 銘柄コード
*  - sym    : 月次日付 (Stata の %tm フォーマット推奨)
******************************************************************/
keep if TICKER == "@XJ9"

keep if eym == ym(2015, 8)

gen horizon = eym - sym     // 任意：予測ホライズン
tsset sym, monthly   // ここは "銘柄×月" を指定

/******************************************************************
* 1.「前月から値が変わったか」を列ごとに検出 → 累積変化回数 cum_
******************************************************************/
sort sym
foreach v of varlist forecaster1-forecaster27 {
    gen byte chg_`v' = (`v' != L.`v') & !missing(`v')
    gen int cum_`v' = sum(chg_`v')
}

/******************************************************************
* 2. 好きな窓幅をここで指定（例：1,2,3 か月）
******************************************************************/
local wins "1 2 3 4 5 6 7 8 9 10 11 12"

/******************************************************************
* 3. 各窓幅 w について：
*    - 直近 w か月以内に変化があった列だけ残す
*    - 行方向 SD を sd`w' に格納
******************************************************************/
foreach w of local wins {

    /* 一時変数をまとめて作り、そのリストを tvars に保持 */
    local tvars ""
    foreach v of varlist forecaster1-forecaster27 {
        gen double tmp_`v'_`w' = cond( cum_`v' - L`w'.cum_`v' > 0, ///
                                       `v', . )
        local tvars "`tvars' tmp_`v'_`w'"
    }

    /* 行方向 SD */
    egen sd`w' = rowsd(`tvars')

    /* 掃除：不要なら一時変数を削除 */
    *drop `tvars'
}
preserve
/******************************************************************
* 4. （任意）ホライズン別に集計して可視化
******************************************************************/
collapse (first) sd* , by(horizon)
*------------------------------------------------------------
* 例：sd1～sd10 を horizon ごとに一枚のグラフに
*------------------------------------------------------------

* 1) プロットするウィンドウ長をリスト化
local wins 1 2 3 4 5 6 7 8 9 10 11 12

* 2) twoway の各 connected 文を組み立て
local plotcmd ""
local n = wordcount("`wins'")
local i = 1
foreach w of local wins {
    * 各線の描画文
    local plotcmd "`plotcmd' connected sd`w' horizon"

    * msymbol と lpattern をお好みで付けたい場合はここで上書き可
    * 例：`local plotcmd "`plotcmd', msymbol(o) lpattern(solid)"'`

    * パイプ（||）の追加は最後以外
    if `i' < `n' {
        local plotcmd "`plotcmd' ||"
    }
    local ++i
}

* 3) 凡例ラベルを自動生成
local legopt ""
local i = 1
foreach w of local wins {
    local legopt "`legopt' label(`i' \"window=`w'\")"
    local ++i
}

* 4) 実行
twoway `plotcmd', ///
    legend(`legopt' ring(0) pos(3))      ///
    title("SD(VALUE) for windows 1–10") ///
    xtitle("Horizon (months)")           ///
    ytitle("SD of VALUE")               ///
    xlabel(0(1)6)                        ///
    ylabel(, angle(0))
	
replace
