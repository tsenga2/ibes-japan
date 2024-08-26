cls
clear all
set graph off

*global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan"
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
    if mod(`year', 3) == 0 { // Only for years divisible by 5
        local m = ym(`year', 1) // January of each year
        local labels `labels' `m'
        local label_years `label_years' "`m'"
    }
}

forvalues i = 330/759 {
    local y = year(dofm(`i'))
    local m = month(dofm(`i'))
    label define sym_lbl `i' "`y'年`m'月", add
}

label values sym sym_lbl

twoway (line mean_Fdis_CV sym, lwidth(thick) sort), ///
xlabel(330(30)759, valuelabel angle(90) labsize(*0.7)) ///
xtitle("") ytitle("") ///
text(0.97 403 "ドル・円100円突破", place(north) size(small)) ///
text(1.31 453 "銀行危機/", place(north) size(small)) ///
text(1.24 469 "アジア金融危機", place(north) size(small)) ///
text(1.46 477 "米国同時多発テロ", place(north) size(small)) ///
text(1.39 501 "|", place(north) size(small)) ///
text(1.34 501 "|", place(north) size(small)) ///
text(1.29 501 "|", place(north) size(small)) ///
text(1.24 501 "|", place(north) size(small)) ///
text(1.19 501 "|", place(north) size(small)) ///
text(1.14 501 "|", place(north) size(small)) ///
text(1.09 501 "|", place(north) size(small)) ///
text(1.04 501 "|", place(north) size(small)) ///
text(1.01 500.7 "\/", place(north) size(small)) ///
text(1.89 510 "イラク戦争勃発", place(north) size(small)) ///
text(1.81 585 "りそな銀行への公的資金注入決定", place(north) size(small)) ///
text(0.88 574 "グローバル金融危機", place(north) size(small)) ///
text(1.13 615 "ドル/円戦後最高値", place(north) size(small)) ///
text(1.92 710 "新型コロナウイルスパンデミック", place(north) size(small)) ///
name(mean_Fdis_CV, replace)
graph export "$mypath/graph/meanfdiscv_m.png", replace

export delimited using "$mypath/ibes-summary-japan-tseries.csv", replace
save "$mypath/ibes-summary-japan-tseries.dta", replace

twoway (line mean_FE_pct sym, lwidth(thick) sort), ///
xtitle("") ytitle("") /// 
xlabel(`labels', format(%tm) labsize(small)) ///
name(mean_FE_pct, replace)
graph export "$mypath/graph/mean_FE_pct_m.png", replace

export delimited using "$mypath/ibes-summary-japan-tseries.csv", replace
save "$mypath/ibes-summary-japan-tseries.dta", replace


import fred NIKKEI225 JPNPRMNTO01GYSAM JPNPROMANMISMEI JPNPRMNTO01GPSAM JPNPRMNTO01IXOBM GEPUCURRENT GEPUPPP, daterange(1987-01-01 2023-07-01) aggregate(monthly) clear
gen sym = ym(year(daten), month(daten))
format sym %tm

keep NIKKEI225 JPNPRMNTO01GYSAM JPNPROMANMISMEI JPNPRMNTO01GPSAM JPNPRMNTO01IXOBM GEPUCURRENT GEPUPPP sym
save "$mypath/japan-tseries.dta", replace


import delimited "/Users/tsenga/ibes-japan/ibes-japan/japan_political_uncertainty_data.csv", varnames(2) clear 
gen sym = ym(year, month)
format sym %tm
drop year
drop month
save "$mypath/japan-epu.dta", replace

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
merge 1:1 sym using "$mypath/japan-epu.dta", nogenerate keep(match)
merge 1:1 sym using "$mypath/nikkei_volatility.dta", nogenerate keep(match)


tsset sym
tssmooth ma aenrop_MA = aenrop, window(6 1 0)
tssmooth ma mean_Fdis_CV_MA = mean_Fdis_CV, window(6 1 6)
tssmooth ma mean_FE_pct_MA = mean_FE_pct, window(6 1 6)


label drop sym_lbl

levelsof sym, local(syms)
foreach s of local syms {
    local y = year(dofm(`s'))
    local m = month(dofm(`s'))
    label define sym_lbl `s' "`y'年`m'月", add
}

label values sym sym_lbl


twoway (tsline mean_Fdis_CV_MA, yaxis(1) lwidth(thick)) ///
       (tsline mean_Fdis_CV, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       xlabel(324(30)761, valuelabel angle(90) labsize(vsmall)) ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "予測分散 (移動平均)" 2 "予測分散(原データ))") position(inside)) ///
       name(mean_Fdis_CV_MA, replace)
       graph export "$mypath/graph/mean_Fdis_CV_MA.png", replace

twoway (tsline mean_FE_pct_MA, yaxis(1) lwidth(thick)) ///
       (tsline mean_FE_pct, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       xlabel(324(30)761, valuelabel angle(90) labsize(vsmall)) ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Error (moving average)" 2 "Mean Forecast Error") position(inside)) ///
       name(mean_FE_pct_MA, replace)
       graph export "$mypath/graph/mean_FE_pct_MA.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline aenrop, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       xlabel(324(30)761, valuelabel angle(90) labsize(vsmall)) ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "予測分散" 2 "政策不確実性指数") position(inside)) ///
       name(mean_Fdis_CV_aenrop, replace)
       graph export "$mypath/graph/mean_Fdis_CV_aenrop.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline JPNPRMNTO01GYSAM, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       xlabel(324(30)761, valuelabel angle(90) labsize(vsmall)) ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "IIP") position(inside)) ///
       name(mean_Fdis_CV_JPNPRMNTO01GYSAM, replace)
       graph export "$mypath/graph/mean_Fdis_CV_JPNPRMNTO01GYSAM.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline NIKKEI225, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       xlabel(324(30)761, valuelabel angle(90) labsize(vsmall)) ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "NIKKEI 225") position(inside)) ///
       name(mean_Fdis_CV_NIKKEI225, replace)
       graph export "$mypath/graph/mean_Fdis_CV_NIKKEI225.png", replace

twoway (tsline mean_Fdis_CV, yaxis(1) lwidth(thick)) ///
       (tsline volatility, yaxis(2) lwidth(medthick) lpattern(dash)), ///
       xlabel(324(30)761, valuelabel angle(90) labsize(vsmall)) ///
       ytitle("", axis(1)) ///
       ytitle("", axis(2)) ///
       xtitle("") ///
       legend(order(1 "Mean Forecast Dispersion" 2 "NIKKEI 225 Volatility") position(inside)) ///
       name(mean_Fdis_CV_NIKKEI225, replace)
       graph export "$mypath/graph/mean_Fdis_CV_NIKKEI225_vol.png", replace


********************************************************************************
************************** "Uncertainy is higher during recessions" regression
eststo clear 
rename JPNPRMNTO01GPSAM IIP
rename mean_Fdis_CV Fdis
rename mean_FE_pct FE
rename aenrop EPU
rename volatility vol
rename NIKKEI225 nikkei

// Loop over the dependent variables
local depvars Fdis FE EPU vol

// Loop over the independent variables
local indvars IIP nikkei

label variable Fdis "\textbf{Forecast dispersion}"
label variable FE "\textbf{Forecast error}"
label variable EPU "\textbf{EPU}"
label variable vol "\textbf{Volatility}"
label variable IIP "\textbf{IIP}"
label variable nikkei "\textbf{NIKKEI 225}"


gen month = mod(sym, 12)
gen year = floor(sym / 12) + 1960


// Run the regressions and store the results
foreach y of local depvars {
    foreach x of local indvars {
        quietly reg `y' `x'
        eststo `y'_`x'
    }
}

// Run the regressions and store the results
foreach y of local depvars {
    foreach x of local indvars {
        quietly reg `y' `x' i.month
        eststo `y'_`x'_month
    }
}


// Run the regressions and store the results
foreach y of local depvars {
    foreach x of local indvars {
        quietly reg `y' `x' i.year
        eststo `y'_`x'_year
    }
}

// Create the table of regression results
esttab EPU_nikkei EPU_nikkei_month EPU_nikkei_year ///
       vol_nikkei vol_nikkei_month vol_nikkei_year ///
       using $mypath/table/reg_ts_1.tex, replace ///
    star(* 0.10 ** 0.05 *** 0.01) nogaps ///
    nodepvars beta(%6.3f) tex ///
    stats(N r2 , fmt(%9.0g %5.0g) ///
    labels(Observations R^2 )) t noconstant ///
    title("Regression Results") ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    keep(nikkei) ///
    addnotes("Dependent variables: mean_Fdis_CV, aenrop, volatility" ///
             "Independent variables: JPNPRMNTO01GPSAM, NIKKEI225") ///
    prehead(\begin{tabular}{l*{@M}{c}}\tabularnewline \hline & \multicolumn{3}{c}{\textbf{EPU} }& \multicolumn{3}{c}{\textbf{Stock volatility}}\\\) ///
    posthead("\hline") prefoot("\hline") ///
    postfoot("\hline \end{tabular}") ///
    noomitted

esttab Fdis_nikkei Fdis_nikkei_month Fdis_nikkei_year ///
       FE_nikkei FE_nikkei_month FE_nikkei_year ///
       using $mypath/table/reg_ts_2.tex, replace ///
    star(* 0.10 ** 0.05 *** 0.01) nogaps ///
    nodepvars beta(%6.3f) tex ///
    stats(N r2 , fmt(%9.0g %5.0g) ///
    labels(Observations R^2 )) t noconstant ///
    title("Regression Results") ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    keep(nikkei) ///
    addnotes("Dependent variables: mean_Fdis_CV, mean_FE_pct" ///
             "Independent variables: NIKKEI225") ///
    prehead(\begin{tabular}{l*{@M}{c}}\tabularnewline \hline & \multicolumn{3}{c}{\textbf{Forecast dispersion} }& \multicolumn{3}{c}{\textbf{Forecast error}}\\\) ///
    posthead("\hline") prefoot("\hline") ///
    postfoot("\hline \end{tabular}") ///
    noomitted

*******************************************************************************
*************************************************************correlation matrix

// Save the variable names in a local macro
local variables Fdis EPU vol IIP nikkei

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
