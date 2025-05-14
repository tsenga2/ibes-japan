global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/merged_data.dta, clear

gen horizon = eym- sym

egen VALUE = rowtotal(VALUE1-VALUE7)
replace VALUE = . if VALUE1 == .

* まず、グループ内で horizon が最小の行にフラグを立てる
gen byte min_horizon_flag = 0
bysort TICKER eym (horizon): replace min_horizon_flag = 1 if _n == 1



* standardizing VALUE
* min_horizon_flag == 1 の行だけカウントし、他は欠損にする
egen VALUE_count = rownonmiss(VALUE*) if min_horizon_flag == 1
	
gen mean_VALUE = VALUE/VALUE_count

* 欠損をグループ内で補完（前方補完 → 後方補完）
bysort TICKER eym (horizon): replace mean_VALUE = mean_VALUE[_n-1] if missing(mean_VALUE)

* グループごとに平均と標準偏差を計算
foreach var of varlist VALUE1-VALUE7 {
    gen d_`var' = .
    replace d_`var' = (`var' - mean_VALUE)^2 if !missing(`var') & !missing(mean_VALUE)
}
egen d_VALUE = rowtotal(d_VALUE1-d_VALUE7)
gen sd_VALUE =( d_VALUE)^(1/2)/VALUE_count
bysort TICKER eym (horizon): replace sd_VALUE = sd_VALUE[_n-1] if missing(sd_VALUE)

foreach var of varlist VALUE1-VALUE7 {
    gen z_`var' = .
    replace z_`var' = (`var' - mean_VALUE) / sd_VALUE if sd_VALUE > 0
}

egen z_VALUE = rowtotal(z_VALUE*)
replace z_VALUE = . if VALUE1 == .

* standardizing forecast
egen mean_forecast = mean(STDEV), by(TICKER eym)
egen sd_forecast = sd(STDEV), by(TICKER eym)
gen d_forecast = STDEV - mean_forecast
gen z_m_forecast = (STDEV - mean_forecast)/sd_forecast if sd_forecast > 0.01

* plot 
preserve
winsor2 z_m_forecast, cuts(1 99)
keep if horizon <= 10 & horizon >= -2 
collapse (mean) c_f = z_m_forecast c_v = z_VALUE, by(horizon)
twoway ///
    (line c_f horizon, lpattern(solid) lwidth(medthick)) ///
    (line c_v horizon, lpattern(dash)  lwidth(medthick)), ///
    legend(order(1 "mean x" 2 "mean y") pos(6) col(1)) ///
    ytitle("Average value") ///
    xtitle("horizon") ///
    title("Average of x and y by horizon")
restore

*
gen CHENEST = (NUMUP + NUMDOWN)
gen R_CHENEST = CHENEST/NUMEST

bysort TICKER eym (horizon): ///
    gen growth = (VALUE) / VALUE[_n-1]


preserve

* 外れ値処理（growth の winsor化）
winsor2 growth, suffix(_w) cuts(1 99)

* horizon 絞り込み
keep if inrange(horizon, -2, 10)

* 平均を計算
collapse (mean) c_f = R_CHENEST c_v = growth_w stdev = STDEV, by(horizon)

* グラフ（stdev は右側の y 軸へ）
twoway ///
    (line c_f horizon, lpattern(solid) lwidth(medthick)) ///
    (line c_v horizon, lpattern(dash) lwidth(medthick)) ///
    (line stdev horizon, lpattern(dot) lwidth(medthick) axis(2)), ///
    legend(order(1 "mean R_CHENEST" 2 "mean growth" 3 "mean STDEV") pos(6) col(1)) ///
    ytitle("R_CHENEST / Growth") ///
    ytitle("STDEV", axis(2)) ///
    xtitle("Horizon") ///
    title("Growth & Forecast (left) vs. STDEV (right)")

restore


preserve

* 外れ値処理（winsor）
winsor2 growth STDEV, suffix(_w) cuts(1 99)

* horizon を制限
keep if inrange(horizon, -2, 10)

* 平均値をグループごとに計算
collapse (mean) c_f = R_CHENEST c_v = growth_w stdev = STDEV_w, by(horizon)

* グラフ作成：stdev は右軸（yaxis(2)）
twoway ///
    (line c_f horizon, lpattern(solid) lwidth(medthick)) ///
    (line c_v horizon, lpattern(dash) lwidth(medthick)) ///
    (line stdev horizon, lpattern(dot) lwidth(medthick) yaxis(2)), ///
    legend(order(1 "mean R_CHENEST" 2 "mean growth" 3 "mean STDEV") pos(6) col(1)) ///
    ytitle("R_CHENEST / Growth (Left Axis)") ///
    ytitle("STDEV (Right Axis)", axis(2)) ///
    xtitle("Horizon") ///
    title("Growth & Forecast vs. STDEV (Dual Axis)")

restore

 
s
