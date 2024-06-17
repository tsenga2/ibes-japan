cls
clear all
set more off
set graphics on




use "/Users/kawabatahatsu/Desktop/ra/IBES/international/ibes-summary-international.dta", clear
keep if CURCODE == "JPY"

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

gen horizon = eym - sym

gen FE = abs(ACTUAL - MEDEST)


********************************************************************************
****************************************************************** First retairing

keep if TICKER=="@XJ9"

univar *

egen FE_yave = mean(FE), by(eym)
egen STDEV_yave = mean(STDEV), by(eym)

egen fst_month = min(sym), by(eym)
gen FE_fst = . 
replace FE_fst = FE if sym == fst_month
replace FE_fst = FE_fst[_n-1] if missing(FE_fst)


gen STDEV_fst = . 
replace STDEV_fst = STDEV if sym == fst_month
replace STDEV_fst = STDEV_fst[_n-1] if missing(STDEV_fst)


keep if eym>= ym(2016,4)
keep if eym<= ym(2022, 3)
	   
twoway (connected ACTUAL sym, yaxis(1) msize(vsmall) msymbol(square) lpattern(solid)) ///
	   (connected HIGHEST sym, yaxis(1)  msize(tiny)  msymbol(diamond) lpattern(dash)) ///
	   (connected MEANEST sym, yaxis(1)  msize(small) msymbol(none) lpattern(solid)) ///
	   (connected LOWEST  sym, yaxis(1)  msize(tiny)  msymbol(lgx) lpattern(dash)), ///
	   title(" ") xtitle(" ") ytitle(" ")  note(" ") graphregion(color(white)) ///
	   legend(pos(5) ring(0) col(1) order(1 "actual" 2 "high" 3 "mean" 4 "low") ///
	   ) name(alcoa_example_1, replace)	   


*numestの軸をつける。

set graphics on
graph combine alcoa_example_1, graphregion(color(white)) name(alcoa_example, replace)
*graph export FigureTable/ford_example_ponch.png, as(png) replace
set graphics off

twoway (connected FE sym, yaxis(1) msize(small) msymbol(lgx) lpattern(solid)) ///
	   (connected STDEV sym, yaxis(1) msize(small) msymbol(lgx) lpattern(dash)), ///
	   title(" ") xtitle(" ") ytitle(" ") note(" ") graphregion(color(white)) ///
	   legend(pos(2) ring(0) col(1) order(1 "forecast error (FE)" 2 "forecast dispersion (Fdis)") ///
	   ) name(alcoa_example_2, replace)	   

set graphics on
graph combine alcoa_example_1 alcoa_example_2, cols(1) xcommon imargin(zero) graphregion(color(white)) name(alcoa_example_fe, replace)
*graph export FigureTable/ford_example_fefdis.png, as(png) replace
*set graphics off


twoway (connected FE sym, yaxis(1) msize(small) msymbol(lgx) lpattern(solid)) ///
	   (scatter FE_fst sym, yaxis(1) msize(small) msymbol(lgx) lpattern(dash)) ///
	   (scatter FE_yave sym, yaxis(1) msize(small) msymbol(triangle) lpattern(dash)) ///
	   ,title(" ") xtitle(" ") ytitle(" ") note(" ") graphregion(color(white)) ///
	   legend(on order(1 "forecast error (FE)" 2 "1st-month FE" 3 "year-average FE") ///
	   ) name(alcoa_example_fe, replace)	
	   


set graphics on
graph combine alcoa_example_fe, graphregion(color(white)) name(alcoa_example_fe, replace)
*graph export FigureTable/ford_example_fe.png, as(png) replace
*set graphics off


twoway (connected STDEV sym, yaxis(1) msize(small) msymbol(lgx) lpattern(solid)) ///
	   (scatter STDEV_fst sym, yaxis(1) msize(small) msymbol(lgx) lpattern(dash)) ///
	   (scatter STDEV_yave sym, yaxis(1) msize(small) msymbol(triangle) lpattern(dash)), ///
	   title(" ") xtitle(" ") ytitle(" ") note(" ") graphregion(color(white)) ///
	   legend(on order(1 "forecast dispersion (Fdis)" 2 "year-ahead Fdis" 3 "year-average Fdis" 4 "year-ahead Fdis (extraporated)") ///
	   ) name(alcoa_example_fdis, replace)	   

set graphics on
graph combine alcoa_example_fdis, graphregion(color(white)) name(alcoa_example_fdis, replace)
*graph export FigureTable/ford_example_fdis.png, as(png) replace
*set graphics off
a	   
restore


 *table 10 horizonから企業のデータが出てきてからの年数(年でアヴェレージとって時系列グラフ)
 *numest analyst coverage
 *topix 日経平均　調べる
********************************************************************************
*************************************************************** pattern analysis
preserve
collapse (sum) obs = id (mean) numest stdev_tr ferr1_tr,  by(toward)
twoway (dropline obs      toward if toward>-2 & toward<13), ytitle("") xtitle("horizon") xlabel(#11) title("observation")  graphregion(color(white)) tlabel(-1(1)12) name(obs_mean_tow, replace)
twoway (dropline numest   toward if toward>-2 & toward<13), ytitle("") xtitle("horizon") xlabel(#11) title("analyst coverage")  graphregion(color(white)) tlabel(-1(1)12) name(numest_mean_tow, replace)
twoway (dropline stdev_tr toward if toward>-2 & toward<13), ytitle("") xtitle("horizon") xlabel(#11) title("forecast dispersion")  graphregion(color(white)) tlabel(-1(1)12) name(stdev_tr_mean_tow, replace)
twoway (dropline ferr1_tr toward if toward>-2 & toward<13), ytitle("") xtitle("horizon") xlabel(#11) title("forecast error")  graphregion(color(white)) tlabel(-1(1)12) name(ferr1_tr_mean_tow, replace)
set graphics on
graph combine obs_mean_tow stdev_tr_mean_tow numest_mean_tow ferr1_tr_mean_tow, graphregion(color(white)) name(box_tow, replace)
graph export FigureTable/box_tow.png, as(png) replace
set graphics off
restore

preserve
collapse (sum) obs = id (mean) numest stdev_tr ferr1_tr if fm==12,  by(m)
twoway (dropline obs      m), ytitle("") xlabel(#11) title("observation")  graphregion(color(white)) name(obs_mean_m_12, replace)
twoway (dropline numest   m), ytitle("") xlabel(#11) title("analyst coverage")  graphregion(color(white)) name(numest_mean_m_12, replace)
twoway (dropline stdev_tr m), ytitle("") xlabel(#11) title("forecast dispersion")  graphregion(color(white)) name(stdev_tr_mean_m_12, replace)
twoway (dropline ferr1_tr m), ytitle("") xlabel(#11) title("forecast error")  graphregion(color(white)) name(ferr1_tr_mean_m_12, replace)
set graphics on
graph combine obs_mean_m_12 stdev_tr_mean_m_12 numest_mean_m_12 ferr1_tr_mean_m_12, graphregion(color(white)) name(box_m_12, replace)
graph export FigureTable/box_m_12.png, as(png) replace
set graphics off
restore


preserve
collapse (sum) obs = id (mean) numest stdev_tr ferr1_tr if fm==9,  by(m)
twoway (dropline obs      m), ytitle("") xlabel(#11) title("observation")  graphregion(color(white)) name(obs_mean_m_9, replace)
twoway (dropline numest   m), ytitle("") xlabel(#11) title("analyst coverage")  graphregion(color(white)) name(numest_mean_m_9, replace)
twoway (dropline stdev_tr m), ytitle("") xlabel(#11) title("forecast dispersion")  graphregion(color(white)) name(stdev_tr_mean_m_9, replace)
twoway (dropline ferr1_tr m), ytitle("") xlabel(#11) title("forecast error")  graphregion(color(white)) name(ferr1_tr_mean_m_9, replace)
set graphics on
graph combine obs_mean_m_9 stdev_tr_mean_m_9 numest_mean_m_9 ferr1_tr_mean_m_9, graphregion(color(white)) name(box_m_9, replace)
graph export FigureTable/box_m_9.png, as(png) replace
set graphics off
restore


preserve
collapse (sum) obs = id (mean) numest stdev_tr ferr1_tr if fm==6,  by(m)
twoway (dropline obs      m), ytitle("") xlabel(#11) title("observation")  graphregion(color(white)) name(obs_mean_m_6, replace)
twoway (dropline numest   m), ytitle("") xlabel(#11) title("analyst coverage")  graphregion(color(white)) name(numest_mean_m_6, replace)
twoway (dropline stdev_tr m), ytitle("") xlabel(#11) title("forecast dispersion")  graphregion(color(white)) name(stdev_tr_mean_m_6, replace)
twoway (dropline ferr1_tr m), ytitle("") xlabel(#11) title("forecast error")  graphregion(color(white)) name(ferr1_tr_mean_m_6, replace)
set graphics on
graph combine obs_mean_m_6 stdev_tr_mean_m_6 numest_mean_m_6 ferr1_tr_mean_m_6, graphregion(color(white)) name(box_m_6, replace)
graph export FigureTable/box_m_6.png, as(png) replace
set graphics off
restore


preserve
collapse (sum) obs = id (mean) numest stdev_tr ferr1_tr if fm==3,  by(m)
twoway (dropline obs      m), ytitle("") xlabel(#11) title("observation")  graphregion(color(white)) name(obs_mean_m_3, replace)
twoway (dropline numest   m), ytitle("") xlabel(#11) title("analyst coverage")  graphregion(color(white)) name(numest_mean_m_3, replace)
twoway (dropline stdev_tr m), ytitle("") xlabel(#11) title("forecast dispersion")  graphregion(color(white)) name(stdev_tr_mean_m_3, replace)
twoway (dropline ferr1_tr m), ytitle("") xlabel(#11) title("forecast error")  graphregion(color(white)) name(ferr1_tr_mean_m_3, replace)
set graphics on
graph combine obs_mean_m_3 stdev_tr_mean_m_3 numest_mean_m_3 ferr1_tr_mean_m_3, graphregion(color(white)) name(box_m_3, replace)
graph export FigureTable/box_m_3.png, as(png) replace
set graphics off
restore




*if you need something below go back 20:49 17/05/2018 version of this
