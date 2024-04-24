cls
clear all
set graph off

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

preserve
winsor2 Fdis_CV, replace cuts(1 99) trim

collapse (mean) month mean_ACTUAL = ACTUAL mean_MEDEST = MEDEST mean_STDEV = STDEV mean_Fdis_CV = Fdis_CV mean_FE_log = FE_log mean_FE_pct = FE_pct (sd) sd_ACTUAL = ACTUAL sd_MEDEST = MEDEST sd_STDEV = STDEV sd_Fdis_CV = Fdis_CV sd_FE_log = FE_log sd_FE_pct = FE_pct, by(sym)

set graph on
local startyear 1987
local endyear 2024
local labels ""
local label_years ""

forval year = `startyear'/`endyear' {
    if mod(`year', 5) == 0 { // Only for years divisible by 5
        local m = ym(`year', 1) // January of each year
        local labels `labels' `m'
        local label_years `label_years' "`m'"
    }
}

twoway (line mean_Fdis_CV sym, lwidth(thick) sort), ///
xtitle("") ytitle("") /// 
xlabel(`labels', format(%tm) labsize(small)) ///
text(0.41 467 "Banking crisis / Asian Financial Crisis", place(north) size(small)) ///
text(0.39 400 "The discount rate cut to 1.00", place(north) size(small)) ///
text(0.38 520 "9/11 Terrorist Attacks", place(north) size(small)) ///
text(0.39 602 "Global financial crisis", place(north) size(small)) ///
text(0.33 725 "COVID-19 Pandemic", place(north) size(small)) ///
name(mean_Fdis_CV, replace)
graph export "$mypath/graph/meanfdiscv_m_winsor.png", replace

export delimited using "$mypath/ibes-summary-japan-tseries.csv", replace
save "$mypath/ibes-summary-japan-tseries.dta", replace
restore

collapse (mean) mean_ACTUAL = ACTUAL mean_MEDEST = MEDEST mean_STDEV = STDEV mean_Fdis_CV = Fdis_CV mean_FE_log = FE_log mean_FE_pct = FE_pct (sd) sd_ACTUAL = ACTUAL sd_MEDEST = MEDEST sd_STDEV = STDEV sd_Fdis_CV = Fdis_CV sd_FE_log = FE_log sd_FE_pct = FE_pct, by(sym)

set graph on
local startyear 1987
local endyear 2024
local labels ""
local label_years ""

forval year = `startyear'/`endyear' {
    if mod(`year', 5) == 0 { // Only for years divisible by 5
        local m = ym(`year', 1) // January of each year
        local labels `labels' `m'
        local label_years `label_years' "`m'"
    }
}

twoway (line mean_Fdis_CV sym, lwidth(thick) sort), ///
xtitle("") ytitle("") /// 
xlabel(`labels', format(%tm) labsize(small)) ///
text(0.95 400 "The discount rate cut to 1.00%", place(north) size(small)) ///
text(1.25 424 "Banking crisis / Asian Financial Crisis", place(north) size(small)) ///
text(1.45 469 "9/11 Terrorist Attacks", place(north) size(small)) ///
text(1.89 510 "Iraq War begins (March 2003)", place(north) size(small)) ///
text(1.81 585 "Resona Bank bailout (May 2003)", place(north) size(small)) ///
text(0.85 574 "Global Financial Crisis", place(north) size(small)) ///
text(1.12 614 "Tohoku Earthquake and Tsunami", place(north) size(small)) ///
text(1.9 720 "COVID-19 Pandemic", place(north) size(small)) ///
name(mean_Fdis_CV, replace)
graph export "$mypath/graph/meanfdiscv_m.png", replace

export delimited using "$mypath/ibes-summary-japan-tseries.csv", replace
save "$mypath/ibes-summary-japan-tseries.dta", replace

import fred NIKKEI225 JPNPRMNTO01GYSAM JPNPROMANMISMEI JPNPRMNTO01GPSAM JPNPRMNTO01IXOBM GEPUCURRENT GEPUPPP JPNEPUINDXM, daterange(1987-01-01 2023-07-01) aggregate(monthly) clear
gen sym = ym(year(daten), month(daten))
format sym %tm

keep NIKKEI225 JPNPRMNTO01GYSAM JPNPROMANMISMEI JPNPRMNTO01GPSAM JPNPRMNTO01IXOBM GEPUCURRENT GEPUPPP JPNEPUINDXM sym
save "$mypath/japan-tseries.dta", replace



* Import the daily Nikkei 225 index data from FRED
import fred NIKKEI225, clear

gen syear=year(daten)
gen sm=month(daten)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

* Calculate daily returns
generate returns = ln(NIKKEI225 / NIKKEI225[_n-1])

* Collapse data to monthly frequency and calculate volatility
collapse (sd) volatility=returns, by(sym)

save "$mypath/nikkei_volatility.dta", replace

use "$mypath/ibes-summary-japan-tseries.dta", clear
merge 1:1 sym using "$mypath/japan-tseries.dta", nogenerate keep(match)
merge 1:1 sym using "$mypath/nikkei_volatility.dta", nogenerate keep(match)


tsset sym
tssmooth ma JPNEPUINDXM_MA = JPNEPUINDXM, window(6 1 0)


twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline JPNEPUINDXM_MA, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "EPU (moving average)") position(inside)) ///
       name(mean_Fdis_CV_JPNEPUINDXM, replace)
       graph export "$mypath/graph/mean_Fdis_CV_JPNEPUINDXM.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline JPNPRMNTO01GYSAM, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "IIP") position(inside)) ///
       name(mean_Fdis_CV_JPNPRMNTO01GYSAM, replace)
       graph export "$mypath/graph/mean_Fdis_CV_JPNPRMNTO01GYSAM.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline NIKKEI225, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "NIKKEI 225") position(inside)) ///
       name(mean_Fdis_CV_NIKKEI225, replace)
       graph export "$mypath/graph/mean_Fdis_CV_NIKKEI225.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline volatility, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "NIKKEI 225 Volatility") position(inside)) ///
       name(mean_Fdis_CV_NIKKEI225, replace)
       graph export "$mypath/graph/mean_Fdis_CV_NIKKEI225_vol.png", replace

// Save the variable names in a local macro
local variables mean_Fdis_CV JPNEPUINDXM JPNEPUINDXM_MA JPNPRMNTO01GYSAM NIKKEI225 volatility

// Open a LaTeX file for writing
file open mylatexfile using "$mypath/table/cross_correlation.tex", write replace

// Write the LaTeX table header
file write mylatexfile "\begin{tabular}{l*{`=wordcount("`variables'")'}{{r}}}" _n
file write mylatexfile "Variable & `=subinstr("`variables'", " ", " & ", .)' \\" _n
file write mylatexfile "\hline" _n

// Loop through each variable and calculate the correlation with other variables
foreach var in `variables' {
    file write mylatexfile "`var'"
    foreach with in `variables' {
        if "`var'" != "`with'" { // Ensure we don't correlate a variable with itself
            qui corr `var' `with'
            local corr: display %9.3f r(rho)
            file write mylatexfile " & `corr'"
        }
        else {
            file write mylatexfile " & 1.000"
        }
    }
    file write mylatexfile " \\" _n
}

// Write the LaTeX table footer
file write mylatexfile "\end{tabular}"

// Close the LaTeX file
file close mylatexfile
