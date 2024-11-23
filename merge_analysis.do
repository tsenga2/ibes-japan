cls
clear all
set graph off

*global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan"
global mypath "/Users/tsenga/ibes-japan/ibes-japan"
use $mypath/merged.dta, clear

capture mkdir $mypath/graph 
capture mkdir $mypath/table 

gen oftic = OFTIC
generate period = sym
format period %tm

preserve
import delimited "$mypath/combined_data.csv", clear
duplicates drop oftic period, force

gen period_float = monthly(period, "YM")
format period_float %tm
drop period
rename period_float period
save "$mypath/combined_data.dta", replace
restore

rename _merge _merge_dbj
sort oftic period sym
order oftic period sym

keep if _merge_dbj == 3
drop _merge_dbj
sort oftic period

gen str7 period_str = string(period, "%tm")
sort oftic period_str
merge 1:1 oftic period using "$mypath/combined_data.dta", generate(_merge_nikkei)

keep if _merge_nikkei == 3
drop _merge_nikkei

gen highlow = highprice - lowprice
replace highlow = highlow / openingprice
gen abshighlow = abs(highlow)

gen horizon = eym - sym

gen Fdis_CV =  STDEV/abs(MEDEST)
gen FE_log = abs(log(ACTUAL/MEDEST))
gen FE_pct = abs(ACTUAL/MEDEST -1)

bysort CNAME: egen first_year = min(eyear)
bysort CNAME: egen Age = max(eyear - first_year)

order OFTIC STATPERS syear eyear MEDEST ACTUAL sale ni
sort OFTIC STATPERS syear eyear

preserve
collapse (mean) abshighlow ACTUAL sale ni NUMEST Fdis_CV FE_log FE_pct MEDEST, by(OFTIC eyear)

gen stockvol = abshighlow
by OFTIC (eyear): gen ACTUAL_growth = (ACTUAL - ACTUAL[_n-1]) / ACTUAL[_n-1]
by OFTIC (eyear): gen SD_ACTUAL_growth = sqrt((sum((ACTUAL_growth - ACTUAL_growth[_n-1])/ACTUAL_growth[_n-1])^2)/(_N-1))

keep OFTIC eyear SD_ACTUAL_growth stockvol
save "$mypath/sd_growth.dta", replace
restore

merge m:1 OFTIC eyear using "$mypath/sd_growth.dta"
drop _merge


preserve
keep OFTIC eyear ACTUAL sale ni NUMEST Fdis_CV FE_log FE_pct MEDEST SD_ACTUAL_growth Age stockvol
winsor2 *, replace cuts(1 99) trim
collapse (mean) ACTUAL sale ni NUMEST Fdis_CV FE_log FE_pct MEDEST SD_ACTUAL_growth Age stockvol, by(OFTIC eyear)

xtset OFTIC eyear

eststo clear


gen ln_sale = log(sale)
gen ln_age = log(Age)

reg Fdis_CV NUMEST 
estadd local YearFE = "N" 
estadd local FirmFE = "N"
est store Fdis_CV_NN

areg Fdis_CV NUMEST i.eyear, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store Fdis_CV_YY

areg Fdis_CV NUMEST i.eyear ln_sale ln_age, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store Fdis_CV_YY_A

areg Fdis_CV NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store Fdis_CV_YY_B

areg Fdis_CV NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>2, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store Fdis_CV_YY_C

areg Fdis_CV NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>5, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store Fdis_CV_YY_D

areg Fdis_CV NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>10, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store Fdis_CV_YY_E

esttab Fdis_CV_NN Fdis_CV_YY Fdis_CV_YY_A Fdis_CV_YY_B Fdis_CV_YY_C Fdis_CV_YY_D  ///
using $mypath/table/reg_T01.tex, replace ///
beta(%6.3f) tex nomti nodepvars ///
star(* 0.10 ** 0.05 *** 0.01) nogaps ///
label stats(YearFE FirmFE N r2 , fmt(%9.0g %9.0g %9.0g %8.3f) ///
labels("Year FE" "Firm FE" Observations R^2 )) t noconstant ///
keep(NUMEST ln_sale ln_age SD_ACTUAL_growth stockvol) ///
noomitted ///


reg FE_log NUMEST 
estadd local YearFE = "N" 
estadd local FirmFE = "N"
est store FE_log_NN

areg FE_log NUMEST i.eyear, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store FE_log_YY

areg FE_log NUMEST i.eyear ln_sale ln_age, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store FE_log_YY_A

areg FE_log NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store FE_log_YY_B

areg FE_log NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>2, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store FE_log_YY_C

areg FE_log NUMEST i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>5, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store FE_log_YY_D

esttab FE_log_NN FE_log_YY FE_log_YY_A FE_log_YY_B FE_log_YY_C  FE_log_YY_D  ///
using $mypath/table/reg_T02.tex, replace ///
beta(%6.3f) tex nomti nodepvars ///
star(* 0.10 ** 0.05 *** 0.01) nogaps ///
label stats(YearFE FirmFE N r2 , fmt(%9.0g %9.0g %9.0g %8.3f) ///
labels("Year FE" "Firm FE" Observations R^2 )) t noconstant ///
keep(NUMEST ln_sale ln_age SD_ACTUAL_growth stockvol) ///
noomitted ///


reg NUMEST ACTUAL 
estadd local YearFE = "N" 
estadd local FirmFE = "N"
est store NUMEST_NN

areg NUMEST ACTUAL i.eyear, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store NUMEST_YY

areg NUMEST ACTUAL i.eyear ln_sale ln_age, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store NUMEST_YY_A

areg NUMEST ACTUAL i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store NUMEST_YY_B

areg NUMEST ACTUAL i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>2, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store NUMEST_YY_C

areg NUMEST ACTUAL i.eyear ln_sale ln_age SD_ACTUAL_growth stockvol if NUMEST>5, absorb(OFTIC) vce(robust)
estadd local YearFE = "Y" 
estadd local FirmFE = "Y"
est store NUMEST_YY_D


esttab NUMEST_NN NUMEST_YY NUMEST_YY_A NUMEST_YY_B NUMEST_YY_C NUMEST_YY_D  ///
using $mypath/table/reg_T03.tex, replace ///
beta(%6.3f) tex nomti nodepvars ///
star(* 0.10 ** 0.05 *** 0.01) nogaps ///
label stats(YearFE FirmFE N r2 , fmt(%9.0g %9.0g %9.0g %8.3f) ///
labels("Year FE" "Firm FE" Observations R^2 )) t noconstant ///
keep(ACTUAL ln_sale ln_age SD_ACTUAL_growth stockvol) ///
noomitted ///

restore


levelsof eyear, local(levels)
foreach l of local levels{
	preserve
	keep if eyear == `l'
	duplicates drop TICKER, force
	egen num_firms = count(TICKER)
	keep eyear num_firms
	duplicates drop num_firms, force
	tempfile `l'
	save `l',replace
	restore
}
preserve


local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save "$mypath/num_firms.dta", replace

restore


levelsof eyear, local(levels)
foreach l of local levels{
	preserve
	keep if eyear == `l'
	keep NUMEST Fdis_CV FE_log FE_pct
	winsor2 *, replace cuts(1 99) trim
	egen mean_NUMEST = mean(NUMEST)
	egen mean_Fdis_CV = mean(Fdis_CV)
	egen mean_FE_log = mean(FE_log)
	egen mean_FE_pct = mean(FE_pct)
	gen eyear = `l'
	drop NUMEST Fdis_CV FE_log FE_pct
	duplicates drop mean_NUMEST, force
	tempfile `l'
	save `l',replace
	
	restore 
}

preserve

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save "$mypath/sum_year.dta", replace

restore

levelsof eyear, local(levels)
foreach l of local levels{
	preserve
	keep if eyear == `l'
	keep sale ta
	duplicates drop	*, force
	winsor2 *, replace cuts(1 99) trim
	egen mean_sale = mean(sale)
	egen mean_ta = mean(ta)
	gen mean_sale_log = log(mean_sale)
	gen mean_ta_log = log(mean_ta)
	gen eyear = `l'
	drop sale ta
	duplicates drop mean_sale, force
	tempfile `l'
	save `l',replace	
	restore 
}

preserve

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save "$mypath/sum_renketsu.dta", replace


merge 1:1 eyear using "$mypath/num_firms.dta"

save sum, replace
drop _merge 

merge 1:1 eyear using "$mypath/sum_year.dta"

save sum, replace
drop _merge
order eyear, first

outsheet using "$mypath/sum_year.tex", replace

set graph on

twoway (line num_firms eyear,lwidth(thick) sort), xtitle("") ytitle("Number of Firms") xlabel(1985(6)2021) legend(label(1 "Number of firms")) name(num_firms, replace)
graph export "$mypath/graph/numfirm_y.png", replace
twoway (line mean_sale eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of sales") xlabel(1985(6)2021)  legend(label(1 "mean of sales")) name(mean_sale, replace)
graph export "$mypath/graph/meansale_y.png", replace
twoway (line mean_ta eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of total assets") xlabel(1985(6)2021)  legend(label(1 "mean of total assets")) name(mean_ta, replace)
graph export "$mypath/graph/meanta_y.png", replace
twoway (line mean_sale_log eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of sales (log)") xlabel(1985(6)2021)  legend(label(1 "mean_sale log")) name(mean_sale_log, replace)
graph export "$mypath/graph/meansale_log_y.png", replace
twoway (line mean_ta_log eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of assets (log)") xlabel(1985(6)2021)  legend(label(1 "mean_ta log")) name(mean_ta_log, replace)
graph export "$mypath/graph/meanta_log_y.png", replace
twoway (line mean_NUMEST eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of number of estimator") xlabel(1985(6)2021)  legend(label(1 "mean of Number of estimator")) name(mean_NUMEST, replace)
graph export "$mypath/graph/meannamest_y.png", replace
twoway (line mean_Fdis_CV eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of Fdis CV") xlabel(1985(6)2021)  legend(label(1 "mean_Fdis_CV")) name(mean_Fdis_CV, replace)
graph export "$mypath/graph/meanfdiscv_y.png", replace
twoway (line mean_FE_log eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of FE log") xlabel(1985(6)2021)  legend(label(1 "mean_FE_log")) name(mean_FE_log, replace)
graph export "$mypath/graph/meanfelog_y.png", replace
twoway (line mean_FE_pct eyear,lwidth(thick) sort), xtitle("") ytitle("Mean of FE pct") xlabel(1985(6)2021)  legend(label(1 "mean_FE_pct")) name(mean_FE_pct, replace)
graph export "$mypath/graph/meanfepct_y.png", replace

graph combine num_firms mean_sale mean_ta mean_sale_log mean_ta_log mean_NUMEST mean_Fdis_CV mean_FE_log mean_FE_pct, title("") graphregion(color(white)) name(combo, replace)
graph export "$mypath/graph/combo_y.png", replace
set graph off


foreach l of local levels {
	erase "`l'.dta"
}


restore

$month


levelsof sym, local(levels)
foreach l of local levels{
	preserve
	keep if sym == `l'
	keep Fdis_CV FE_log FE_pct
	winsor2 *, replace cuts(1 99) trim
	egen mean_Fdis_CV = mean(Fdis_CV)
	egen mean_FE_log = mean(FE_log)
	egen mean_FE_pct = mean(FE_pct)
	gen sym = `l'
	drop Fdis_CV FE_log FE_pct
	duplicates drop mean_Fdis_CV, force
	tempfile `l'
	save `l',replace
	
	restore 
}

preserve

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save "$mypath/sum_month.dta", replace


foreach l of local levels {
	erase "`l'.dta"
}

set graph on
twoway (line mean_Fdis_CV sym, lwidth(thick) sort), ///
xtitle("") ytitle("Mean of Fdis CV") xlabel(, format(%tm)) /// 
text(0.25 308 "Plaza Accord", place(north) size(small)) ///
text(0.52 359 "Asset Bubble Peak", place(north) size(small)) ///
text(0.6 420 "Great Hanshin Earthquake", place(north) size(small)) ///
text(0.52 454 "Asian Financial Crisis", place(north) size(small)) ///
text(0.55 584 "Financial cisis", place(north) size(small)) ///
text(0.25 614 "Tohoku Earthquake and Tsunami", place(north) size(small)) ///
text(0.5 672 "Negative Interest Rate Policy", place(north) size(small)) ///
text(1 717 "Consumption Tax Hike", place(north) size(small)) ///
text(1.5 720 "COVID-19 Pandemic", place(north) size(small)) ///
name(mean_Fdis_CV, replace)
graph export "$mypath/graph/meanfdiscv_m.png", replace
twoway (line mean_FE_log sym,lwidth(thick) sort), xtitle("") ytitle("Mean of FE log") xlabel(, format(%tm)) /// 
text(0.25 308 "Plaza Accord", place(north) size(small)) ///
text(0.52 359 "Asset Bubble Peak", place(north) size(small)) ///
text(0.6 420 "Great Hanshin Earthquake", place(north) size(small)) ///
text(0.52 454 "Asian Financial Crisis", place(north) size(small)) ///
text(0.55 584 "Financial cisis", place(north) size(small)) ///
text(0.25 614 "Tohoku Earthquake and Tsunami", place(north) size(small)) ///
text(0.5 672 "Negative Interest Rate Policy", place(north) size(small)) ///
text(1 717 "Consumption Tax Hike", place(north) size(small)) ///
text(1.5 720 "COVID-19 Pandemic", place(north) size(small)) ///
name(mean_FE_log, replace)
graph export "$mypath/graph/meanfelog_m.png", replace
twoway (line mean_FE_pct sym,lwidth(thick) sort), xtitle("") ytitle("Mean of FE pct") xlabel(, format(%tm)) /// 
text(0.25 308 "Plaza Accord", place(north) size(small)) ///
text(0.52 359 "Asset Bubble Peak", place(north) size(small)) ///
text(0.6 420 "Great Hanshin Earthquake", place(north) size(small)) ///
text(0.52 454 "Asian Financial Crisis", place(north) size(small)) ///
text(0.55 584 "Financial cisis", place(north) size(small)) ///
text(0.25 614 "Tohoku Earthquake and Tsunami", place(north) size(small)) ///
text(0.5 672 "Negative Interest Rate Policy", place(north) size(small)) ///
text(1 717 "Consumption Tax Hike", place(north) size(small)) ///
text(1.5 720 "COVID-19 Pandemic", place(north) size(small)) ///
name(mean_FE_pct, replace)
graph export "$mypath/graph/meanfepct_m.png", replace
graph combine mean_Fdis_CV mean_FE_log mean_FE_pct, title("") graphregion(color(white)) name(combo, replace)
graph export "$mypath/graph/combo_m.png", replace
set graph off

$horizon

restore

keep if horizon >= 0

levelsof horizon, local(levels)
foreach l of local levels{
	preserve
	keep if horizon == `l'
	duplicates drop TICKER, force
	egen num_firms = count(TICKER)
	keep horizon num_firms
	duplicates drop num_firms, force
	tempfile `l'
	save `l',replace
	restore
}

preserve


local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save "$mypath/num_firms.dta", replace

restore


levelsof horizon, local(levels)
foreach l of local levels{
	preserve
	keep if horizon == `l'
	keep NUMEST Fdis_CV FE_log FE_pct
	winsor2 NUMEST Fdis_CV FE_log FE_pct, replace cuts(1 99) trim
	egen mean_NUMEST = mean(NUMEST)
	egen mean_Fdis_CV = mean(Fdis_CV)
	egen mean_FE_log = mean(FE_log)
	egen mean_FE_pct = mean(FE_pct)
	gen horizon = `l'
	drop NUMEST Fdis_CV FE_log FE_pct
	duplicates drop mean_NUMEST, force
	tempfile `l'
	save `l',replace
	
	restore 
}

preserve

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save "$mypath/sum_horizon.dta", replace

restore

levelsof horizon, local(levels)
foreach l of local levels{
	preserve
	keep if horizon == `l'
	keep sale ta
	duplicates drop	*, force
	winsor2 *, replace cuts(1 99) trim
	egen mean_sale = mean(sale)
	egen mean_ta = mean(ta)
	gen mean_sale_log = log(mean_sale)
	gen mean_ta_log = log(mean_ta)
	gen horizon = `l'
	drop sale ta
	duplicates drop mean_sale, force
	tempfile `l'
	save `l',replace	
	restore 
}

preserve

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}

save "$mypath/sum_renketsu.dta", replace


merge 1:1 horizon using "$mypath/num_firms.dta"

save sum, replace
drop _merge 

merge 1:1 horizon using "$mypath/sum_horizon.dta"

save sum, replace
drop _merge
order horizon, first

outsheet using "$mypath/sum_horizon.tex", replace


save "$mypath/sum_renketsu.dta", replace

set graph on

twoway (line num_firms horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Number of firms") legend(label(1 "num_firms")) name(num_firms, replace)
graph export "$mypath/graph/numfirm_h.png", replace
twoway (line mean_sale horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of sales") legend(label(1 "mean_sale")) name(mean_sale, replace)
graph export "$mypath/graph/meansale_h.png", replace
twoway (line mean_ta horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of total assets") legend(label(1 "mean_ta")) name(mean_ta, replace)
graph export "$mypath/graph/meanta_h.png", replace
twoway (line mean_sale_log horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of sales (log)") legend(label(1 "mean_sale")) name(mean_sale_log, replace)
graph export "$mypath/graph/meansalelog_h.png", replace
twoway (line mean_ta_log horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of total assets (log)") legend(label(1 "mean_ta")) name(mean_ta_log, replace)
graph export "$mypath/graph/meantalog_h.png", replace
twoway (line mean_NUMEST horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of number of estimator") legend(label(1 "mean_NUMEST")) name(mean_NUMEST, replace)
graph export "$mypath/graph/meannumest_h.png", replace
twoway (line mean_Fdis_CV horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of Fdis CV") legend(label(1 "mean_Fdis_CV")) name(mean_Fdis_CV, replace)
graph export "$mypath/graph/meanfdis_h.png", replace
twoway (line mean_FE_log horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of FE log") legend(label(1 "mean_FE_log")) name(mean_FE_log, replace)
graph export "$mypath/graph/meanFElog_h.png", replace
twoway (line mean_FE_pct horizon,lwidth(thick) sort), xlabel(0(1)12) ytitle("Mean of FE pct") legend(label(1 "mean_FE_pct")) name(mean_FE_pct, replace)
graph export "$mypath/graph/meanFEpct_h.png", replace


graph combine num_firms mean_sale mean_ta mean_sale_log mean_ta_log mean_NUMEST mean_Fdis_CV mean_FE_log mean_FE_pct, title("") graphregion(color(white)) name(combo1, replace)
graph export "$mypath/graph/combo_h.png", replace
set graph off

outsheet using "$mypath/sum_horizon.tex", replace

restore


describe
winsor2 Fdis_CV NUMEST ACTUAL STDEV SD_ACTUAL_growth stockvol, replace cuts(1 99) trim

set graph on

binscatter Fdis_CV NUMEST, ytitle("予測分散") xtitle("アナリスト数（人）") name(stnm, replace)
graph export "$mypath/graph/FdisCVnumest.png", replace
binscatter Fdis_CV horizon, ytitle("Fdis CV") name(stho, replace)
graph export "$mypath/graph/FdisCVhorizon.png", replace
binscatter NUMEST horizon, ytitle("アナリスト数（人）")  name(nmho, replace)
graph export "$mypath/graph/Numesthorizon.png", replace
binscatter ACTUAL NUMEST, ytitle("EPS実現値（円）") xtitle("アナリスト数（人）") name(acnm, replace)
graph export "$mypath/graph/ActualNmest.png", replace
binscatter ACTUAL Fdis_CV, ytitle("Actual") xtitle("Fdis CV") name(acst, replace)
graph export "$mypath/graph/ActualFdisCV.png", replace
binscatter ACTUAL horizon, ytitle("Actual") name(acho, replace)
graph export "$mypath/graph/Actualhorizon.png", replace
binscatter ACTUAL MEDEST, ytitle("Actual") xtitle("Medisan of estimation") name(aaa, replace)
graph export "$mypath/graph/ActuslMedest.png", replace
binscatter STDEV NUMEST, ytitle("予測標準偏差") xtitle("アナリスト数（人）") name(bbb, replace)
graph export "$mypath/graph/StdevNumest.png", replace
binscatter FE_log NUMEST, ytitle("予測誤差（対数）") xtitle("アナリスト数（人）") name(ccc, replace)
graph export "$mypath/graph/FElogNumest.png", replace
binscatter FE_pct NUMEST, ytitle("FE pct") xtitle("アナリスト数（人）") name(ddd, replace)
graph export "$mypath/graph/FepctNumest.png", replace
binscatter FE_log horizon, ytitle("FE log") name(eee, replace)
graph export "$mypath/graph/FElogHorizon.png", replace
binscatter FE_pct horizon, ytitle("FE pct") name(fff, replace)
graph export "$mypath/graph/FepctHorizon.png", replace
binscatter SD_ACTUAL_growth NUMEST, ytitle("Volatility of EPS growth") name(ggg, replace)
graph export "$mypath/graph/SdactualgrowthNumest.png", replace
binscatter SD_ACTUAL_growth Fdis_CV, ytitle("Volatility of EPS growth") name(hhh, replace)
graph export "$mypath/graph/SdactualgrowthFdisCV.png", replace
binscatter SD_ACTUAL_growth ACTUAL, ytitle("Volatility of EPS growth") name(iii, replace)
graph export "$mypath/graph/SdactualgrowthActual.png", replace
binscatter stockvol NUMEST, ytitle("Volatility of stock price") name(jjj, replace)
graph export "$mypath/graph/StockvolNumest.png", replace
binscatter stockvol Fdis_CV, ytitle("Volatility of stock price") name(kkk, replace)
graph export "$mypath/graph/StockvolFdisCV.png", replace
binscatter stockvol ACTUAL, ytitle("Volatility of stock price") name(lll, replace)
graph export "$mypath/graph/StockvolActual.png", replace

graph combine stnm bbb stho nmho acnm acst acho aaa ccc ddd eee fff hhh iii jjj kkk lll, title("") graphregion(color(white)) name(combo2, replace)
graph export "$mypath/graph/combo_binscatter.png", replace
set graph off


foreach l of local levels {
	erase "`l'.dta"
}
