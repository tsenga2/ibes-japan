cls
clear all
set more off
set graphics on

use "/Users/kawabatahatsu/Desktop/ra/IBES/international/ibes-summary-international.dta", clear

keep if CURCODE == "JPY"

gen FE = abs(ACTUAL/MEDEST -1)

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

gen horizon = eym - sym

drop TICKER CUSIP OFTIC CNAME STATPERS MEASURE FPI CURCODE FPEDATS syear sm sym eyear em eym

keep if horizon >= 0

winsor2 *, replace cuts(1 99) trim
univar *


* horizonのユニークな値ごとにサブセットを作成
levelsof horizon, local(levels)
save old_dataset, replace

foreach l of local levels {
    use old_dataset, clear
    keep if horizon == `l'
    save "horizon_`l'_dataset.dta", replace
}


foreach l of local levels {
    * サブセットのデータセットを読み込む
    use "horizon_`l'_dataset.dta", clear
    drop horizon
    * 記述統計を表示
    summarize
    
    * 必要に応じて、記述統計をファイルに保存
    * 例: ファイル名を horizon_`l'_summary.txt とする
    summarize, detail
    outsheet using "horizon_`l'_summary.txt", replace
}

use "/Users/kawabatahatsu/Desktop/ra/IBES/international/old_dataset.dta", clear

* 新しい変数に各グループの平均値を格納
bysort horizon: egen mean_NUMEST = mean(NUMEST)
bysort horizon: egen mean_MEDEST = mean(MEDEST)
bysort horizon: egen mean_MEANEST = mean(MEANEST)
bysort horizon: egen mean_STDEV = mean(STDEV)
bysort horizon: egen mean_HIGHEST = mean(HIGHEST)
bysort horizon: egen mean_LOWEST = mean(LOWEST)
bysort horizon: egen mean_ACTUAL = mean(ACTUAL)
bysort horizon: egen mean_FE = mean(FE)
egen sample_size = count(horizon), by(horizon)




* グラフを作成
twoway (line mean_NUMEST horizon, sort), legend(label(1 "mean_NUMEST")) name(mean_NUMEST, replace)
twoway (line mean_MEDEST horizon, sort), legend(label(1 "mean_MEDEST")) name(mean_MEDEST, replace)
twoway (line mean_MEANEST horizon, sort), legend(label(1 "mean_MEANEST")) name(mean_MEANEST, replace)
twoway (line mean_STDEV horizon, sort), legend(label(1 "mean_STDEV")) name(mean_STDEV, replace)
twoway (line mean_HIGHEST horizon, sort), legend(label(1 "mean_HIGHEST")) name(mean_HIGHEST, replace)
twoway (line mean_ACTUAL horizon, sort), legend(label(1 "mean_ACTUAL")) name(mean_ACTUAL, replace)
twoway (line mean_FE  horizon, sort), legend(label(1 "mean_FE")) name(mean_FE, replace)
twoway (line sample_size horizon, sort), legend(label(1 "sample size")) name(size, replace)

twoway (line mean_MEDEST horizon, sort) (line mean_MEANEST horizon, sort) (line mean_HIGHEST horizon, sort) (line mean_ACTUAL horizon, sort), legend(order(1 "mean_MEDEST" 2 "mean_MEANEST" 3 "mean_HIGHEST" 4 "mean_ACTUAL")) xscale(range(0 12))

graph combine mean_NUMEST mean_MEDEST mean_MEANEST mean_STDEV mean_HIGHEST mean_ACTUAL mean_FE size, title("") graphregion(color(white)) name(combo, replace)

replace STDEV = STDEV/ACTUAL

binscatter STDEV NUMEST, name(stnm, replace)
binscatter STDEV horizon, name(stho, replace)
binscatter NUMEST horizon, name(nmho, replace)
binscatter ACTUAL NUMEST, name(acnm, replace)
binscatter ACTUAL STDEV, name(acst, replace)
binscatter ACTUAL horizon, name(acho, replace)
graph combine stnm stho nmho acnm acst acho, title("") graphregion(color(white)) name(combo1, replace)


