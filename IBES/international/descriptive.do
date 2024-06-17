use "/Users/kawabatahatsu/Desktop/ra/IBES/international/ibes-summary-international.dta", clear

keep if CURCODE == "JPY"
gen FE = abs(ACTUAL/MEDEST -1)

keep CNAME CUSIP NUMEST FE ACTUAL MEDEST
save summary.dta, replace
use "/Users/kawabatahatsu/Desktop/ra/IBES/international/summary.dta", clear

egen min_numest = min(NUMEST), by(CUSIP)
egen max_numest = max(NUMEST), by(CUSIP)
egen mean_numest = mean(NUMEST), by(CUSIP)
egen sd_numest = sd(NUMEST), by(CUSIP)
egen min_FE = min(FE), by(CUSIP)
egen max_FE = max(FE), by(CUSIP)
egen mean_FE = mean(FE), by(CUSIP)
egen sd_FE = sd(FE), by(CUSIP)
*duplicates drop CUSIP, force

summarize

use "/Users/kawabatahatsu/Desktop/ra/IBES/international/ibes-detail-international.dta", clear

keep if CURR == "JPY"
gen FE = abs(ACTUAL/VALUE -1)

keep CNAME ANNDATS VALUE FE
save detail.dta, replace

use "/Users/kawabatahatsu/Desktop/ra/IBES/international/detail.dta", clear

sort CNAME ANNDATS FE


by CNAME ANNDATS:egen min_FE = min(FE)
by CNAME ANNDATS:egen max_FE = max(FE)
by CNAME ANNDATS:egen mean_FE = mean(FE)
by CNAME ANNDATS:egen sd_FE = sd(FE)
duplicates drop ANNDATS, force

summarize

egen count = count(CNAME), by(STATPERS)
gen year=year(statpers)
gen m=month(statpers)
gen ym = ym(year, m)
format ym %tm
