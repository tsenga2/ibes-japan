cls
clear all
set graph on

*global mypath "/Users/kawabatahatsu/Desktop/ra/IBES/international"
global mypath "/Users/tsenga/ibes-japan/ibes-japan"
use $mypath/IBES/international/ibes-summary-international.dta, clear

capture mkdir $mypath/graph 
capture mkdir $mypath/table 

keep if CURCODE == "JPY"

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

destring OFTIC, replace force

gen Fdis_CV =  STDEV/abs(MEDEST)
gen FE_log = abs(log(ACTUAL/MEDEST))
gen FE_pct = abs(ACTUAL/MEDEST -1)

sort OFTIC sym eym 
order OFTIC sym eym NUMEST ACTUAL MEDEST STDEV HIGHEST LOWEST Fdis_CV FE_log FE_pct

gen oftic = OFTIC
generate period = sym
format period %tm

drop if oftic == .
duplicates drop oftic period, force

preserve
import delimited "$mypath/combined_data.csv", clear
duplicates drop oftic period, force

gen period_float = monthly(period, "YM")
format period_float %tm
drop period
rename period_float period
xtset oftic period
xtsum oftic
save "$mypath/combined_data.dta", replace
restore

gen str7 period_str = string(period, "%tm")
sort oftic period_str

xtset oftic period
xtsum oftic


merge 1:1 oftic period using "$mypath/combined_data.dta", generate(_merge_nikkei)

gen flag = 1
foreach var of varlist actualearningspershare-issuedsharesrightsoffbase {
    replace flag = 0 if !mi(`var')
}
drop if flag == 1
drop flag


* Count the number of samples where _merge_nikkei == 3 and _merge_nikkei == 2
gen count_merge_3 = (_merge_nikkei == 3)
gen count_merge_2 = (_merge_nikkei == 2)

preserve
* Collapse data to get the number of each type per period
collapse (sum) count_merge_3 count_merge_2, by(period)

* Generate a bar chart with the number of samples for each merge type by period
* Adjust the x-axis to make it less dense by displaying fewer period labels
local num_periods = _N
local step = ceil(`num_periods'/10)  // Display approximately one label every 10 periods


gen count_sum = count_merge_2 + count_merge_3

<<<<<<< HEAD
twoway (bar count_sum period, barwidth(0.4) color(maroon)) ///
       (bar count_merge_3 period, barwidth(0.4) color(navy)), ///
       ytitle("") ///
       graphregion(color(white)) plotregion(color(white)) legend(off)

graph export "$mypath/graph/merge_nikkei_counts.png", as(png) replace
=======
graph export "$mypath/graph/merge_nikkei_counts.png", as(png) replace

restore

keep if _merge_nikkei==3


label variable ACTUAL "\textbf{Realised EPS}"
label variable MEDEST "\textbf{Median Estimated EPS}"
label variable MEANEST "\textbf{Mean Estimated EPS}"
label variable NUMEST "\textbf{Number of Estimates}"
label variable Fdis_CV "\textbf{Forecast Dispersion}"
label variable FE_log "\textbf{Forecast Error Log}"
label variable FE_pct "\textbf{Forecast Error Percentage}"

preserve
winsor2 ACTUAL MEDEST NUMEST Fdis_CV FE_log FE_pct, replace cuts(1 99) 

estpost sum ACTUAL MEDEST NUMEST Fdis_CV FE_log FE_pct, d
est store all
esttab all ///
using $mypath/table/desc_stats_a.tex, replace ///
legend noabbrev style(tex) ///
cells("mean(fmt(1)) sd(fmt(1)) p5(fmt(1)) p25(fmt(1)) p50(fmt(1)) p75(fmt(1)) p95(fmt(1))") ///
lines parentheses ///
label nonumber noobs nogaps ///
stats(N, fmt(%9.0fc) labels("Observations"))
restore


merge m:1 OFTIC eym using "$mypath/renketsu1.dta", generate(_merge_renketsu)
keep if _merge_renketsu == 3

winsor2 ACTUAL MEDEST NUMEST Fdis_CV FE_log FE_pct marketcapitalizationbasedonissue sale, replace cuts(1 99) 

label variable marketcapitalizationbasedonissue "\textbf{Market Capitalization (YEN)}"
label variable sale "\textbf{Sales (Mil. YEN)}"

estpost sum ACTUAL MEDEST NUMEST Fdis_CV FE_log FE_pct marketcapitalizationbasedonissue sale, d
est store all
esttab all ///
using $mypath/table/desc_stats_b.tex, replace ///
legend noabbrev style(tex) ///
cells("mean(fmt(1)) sd(fmt(1)) p5(fmt(1)) p25(fmt(1)) p50(fmt(1)) p75(fmt(1)) p95(fmt(1))") ///
lines parentheses ///
label nonumber noobs nogaps ///
stats(N, fmt(%9.0fc) labels("Observations"))

>>>>>>> 35260a74db089c077386a40c1df99c1e83dbec67

