cls
clear all
set graph on

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/det_history.dta, clear

keep if CURR == "JPY"
drop CURR
drop if missing(ACTUAL)

egen analyst_id = group(ESTIMATOR ANALYS)
*egen id = group(analyst_id TICKER ANNDATS ANNTIMS FPEDATS)
gen rownum = _n

destring FPI, replace force
drop if missing(FPI)
reshape wide VALUE ACTUAL, i(rownum) j(FPI)



foreach v in VALUE1 VALUE6 VALUE7 VALUE8 VALUE9 ACTUAL1 ACTUAL6 ACTUAL7 ACTUAL8 ACTUAL9{
    bysort TICKER analyst_id ANNDATS FPEDATS (`v'): replace `v' = `v'[_n-1] if missing(`v')
}

drop rownum
duplicates drop analyst_id FPEDATS ANNDATS TICKER, force

order TICKER CNAME analyst_id ANNDATS FPEDATS VALUE6 ACTUAL6 VALUE7 ACTUAL7 VALUE8 ACTUAL8 VALUE9 ACTUAL9 VALUE1 ACTUAL1
sort TICKER FPEDATS analyst_id
stop
