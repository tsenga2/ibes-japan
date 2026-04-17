clear
set more off
set graphics off

*--- 0) パス設定
global mypath "~/Library/CloudStorage/Dropbox/IBES"
global outdir "$mypath/graphs" 


use $mypath/Both/sum_history.dta, clear
capture mkdir "$outdir"

merge m:m TICKER using $mypath/Both/ibes_summary_identif.dta 


gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

* 例：ANNDATS（日付）が同じなら ANNTIMS（時刻）の遅いものを残す
gsort +ANNDATS -ANNTIMS   // 日付は昇順、時刻は降順
duplicates drop eym sym TICKER CURR_ACT, force

gen horizon = eym-sym

keep if FISCALP == "ANN" & horizon >=0 & horizon <= 10 & eyear >= 200 & eyear <=2024

* 念のため数値化
destring STDEV, replace ignore(" ")

* まずソート
sort COUNTRY eyear

* group-wise percentile
*bys COUNTRY eyear: egen p1  = pctile(STDEV), p(0)
bys COUNTRY eyear: egen p99 = pctile(STDEV), p(90)
gen STDEV_w = STDEV
*replace STDEV_w = p1  if STDEV_w < p1
replace STDEV_w = p99 if STDEV_w > p99
drop p99


* horizon が文字なら数値化
destring horizon, replace ignore(" ")

collapse (mean) STDEV_w, by(COUNTRY eyear eym horizon)

sort COUNTRY eym -horizon
* eymごとに horizon が 10→0 の順で並ぶ前提
bys COUNTRY (eym -horizon): gen long seq = _n
bys COUNTRY (seq): gen byte cut_here = eyear != eyear[_n-1]

gen STDEV_plot = STDEV_w
replace STDEV_plot = . if cut_here
preserve
keep COUNTRY eyear seq

* eyear はその年の最初の seq のみ残す
bys COUNTRY eyear (seq): keep if _n == 1

save eyear_axis_labels, replace
restore
levelsof COUNTRY, local(c_list)

foreach c of local c_list {

    * 軸ラベル作成
    preserve
    use eyear_axis_labels, clear
    keep if COUNTRY == "`c'"
    levelsof seq, local(xpos)
    levelsof eyear, local(xlabs)

    local xlabelspec
    local i = 1
    foreach x of local xpos {
        local lab : word `i' of `xlabs'
        local xlabelspec `xlabelspec' `x' "`lab'"
        local ++i
    }
    restore

    * 本体描画
twoway ///
  (line STDEV_plot seq if COUNTRY == "`c'", ///
     sort lcolor(black) lwidth(medium)) ///
  (scatter STDEV_w seq if COUNTRY == "`c'", ///
     mcolor(black) msymbol(O)) ///
  , ///
    legend(off) /// ← 凡例を消す
    xsize(10) ysize(3) /// ← グラフを横長に（適当に調整してみてください）
    xtitle("eyear") ///
    ytitle("mean STDEV (winsorized)") ///
    xlabel(`xlabelspec', angle(vertical)) ///
    title("`c': STDEV（eymごとの horizon 10→0 の推移が連なる）") ///
    name(g_`c', replace)

quietly graph export "$outdir/STDEV_`c'.png", replace
graph drop g_`c'

}


s

use $mypath/Both/ibes_summary_identif.dta, clear

*OFTICも使ってやる場合と結果異なるか
