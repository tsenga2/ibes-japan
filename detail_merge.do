cls
clear all
set graph on

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/det_history.dta, clear

keep if CURR == "JPY"
keep if FPI == "1"
drop CURR
drop if missing(ACTUAL)
destring FPI, replace force
drop if missing(FPI)
s

gen syear=year(ANNDATS)
gen sm=month(ANNDATS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

egen analyst_id = group(ESTIMATOR ANALYS)
gen rownum = _n

egen global_combo = group(ESTIMATOR ANALYS TICKER analyst_id)
bysort TICKER FPEDATS (global_combo): gen change_flag = (global_combo != global_combo[_n-1]) if _n>1
bysort TICKER FPEDATS (global_combo): replace change_flag = 1 if _n==1
by TICKER FPEDATS: gen F = sum(change_flag)

rename VALUE forecaster
reshape wide forecaster, i(rownum) j(F)
drop analyst_id

foreach v of varlist forecaster1-forecaster33 {
    bysort TICKER month FPEDATS (`v'): ///
        replace `v' = `v'[_n-1] if missing(`v')
}

duplicates drop forecaster1-forecaster33 TICKER FPEDATS, force
foreach v of varlist forecaster1-forecaster33 {
	bysort sym eym TICKER: egen `v'_1 = mean(`v')
	replace `v'= `v'_1
	drop `v'_1
}
duplicates drop forecaster1-forecaster33 TICKER FPEDATS, force

duplicates tag TICKER sym eym, gen(dupvar)
keep if dupvar == 1
sort TICKER sym
s

order CNAME sym eym ACTUAL forecaster1-forecaster33
tempfile data
save `data', replace

*summary
use $mypath/sum_history.dta, clear
keep if CURR_ACT == "JPY"
keep if FPI == "1"
drop FPI

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

merge 1:1 TICKER sym eym using `data'

stop
