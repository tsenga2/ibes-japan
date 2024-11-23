********************************************************************************
******************************************************************  example

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan"
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



keep if CURCODE == "JPY"

preserve
keep if TICKER=="@XJ9"


drop TICKER CUSIP OFTIC CNAME MEASURE FPI CURCODE FPEDATS

sort period

keep if syear >= 2015

forvalues i = 660/732 {
    local y = year(dofm(`i'))
    local m = month(dofm(`i'))
	label define sym_lbl `i' "`y'年`m'月", add
	
}

label values sym sym_lbl
	  
twoway (connected ACTUAL sym, yaxis(1) msize(vsmall) msymbol(square) lpattern(solid)) ///
	   (connected HIGHEST sym, yaxis(1)  msize(tiny)  msymbol(diamond) lpattern(dash)) ///
	   (connected MEANEST sym, yaxis(1)  msize(small) msymbol(none) lpattern(solid)) ///
	   (connected LOWEST  sym, yaxis(1)  msize(tiny)  msymbol(lgx) lpattern(dash)), ///
	   title(" ") xtitle(" ") ytitle(" ")  note(" ") graphregion(color(white)) ///
	   legend(ring(0) pos(11) order(1 "実現値" 2 "予測(最高値)" 3 "予測平均" 4 "予測（最低値）")) ///
	   xlabel(668(12)728, valuelabel angle(90) labsize(*0.7)) name(alcoa_example_1, replace)	   

set graphics on
graph combine alcoa_example_1, graphregion(color(white)) name(alcoa_example, replace)
graph export "$mypath/graph/UNIQLO_1.png", replace
set graphics off

twoway (connected FE_log sym, yaxis(1) msize(small) msymbol(lgx) lpattern(solid)) ///
	   (connected Fdis_CV sym, yaxis(1) msize(small) msymbol(lgx) lpattern(dash)) ///
	   (connected openingprice sym, yaxis(2) msize(small) msymbol(none) lpattern(dash)), ///
	   title(" ") xtitle(" ") ytitle(" ") ytitle("", axis(2)) note(" ") graphregion(color(white)) ///
	   legend(ring(0) pos(12) order(1 "予測誤差(FE)" 2 "予測分散(Fdis)" 3 "株価") ///
	   ) xlabel(668(12)728, valuelabel angle(90) labsize(*0.7)) name(alcoa_example_2, replace)	   

set graphics on
graph combine alcoa_example_1 alcoa_example_2, graphregion(color(white)) name(alcoa_example_fe, replace)
graph export "$mypath/graph/UNIQLO_2.png", replace




