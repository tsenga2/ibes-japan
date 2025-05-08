clear all

*global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/Both"

***********************************
* PART 1: DETAIL DATA ANALYSIS
***********************************
use "$mypath/merged_data.dta", clear

* Drop the variables if they already exist
cap drop dis
cap drop num_forecasts
cap drop dis_w
cap drop year_from_eym
cap drop year_from_sym

* Calculate standard deviation across all 34 forecasters
egen dis = rowsd(forecaster1-forecaster32)

* Calculate number of non-missing forecasts
egen num_forecasts = rownonmiss(forecaster1-forecaster32)

* Order variables
order TICKER eym sym dis num_forecasts

* Create histogram for dispersion
histogram dis, title("Distribution of Forecast Dispersion") ///
    xlabel(, angle(45)) ///
    ylabel(, angle(0)) ///
    note("") ///
    bin(50)
graph export "$mypath/dispersion_histogram.png", replace

* Create histogram for number of forecasts
histogram num_forecasts, title("Distribution of Number of Forecasts") ///
    xlabel(, angle(45)) ///
    ylabel(, angle(0)) ///
    discrete ///
    note("") 
graph export "$mypath/num_forecasts_histogram.png", replace

* Create winsorized version of dispersion
winsor2 dis, suffix(_w) cuts(1 99)

* Compare original and winsorized dispersion
histogram dis, name(orig, replace) title("Original Dispersion") bin(50)
histogram dis_w, name(wins, replace) title("Winsorized Dispersion") bin(50)
graph combine orig wins
graph export "$mypath/dispersion_comparison.png", replace

* Calculate horizon and year variables
gen horizon = eym - sym
gen year_from_eym = year(dofm(eym))
gen year_from_sym = year(dofm(sym))

* Calculate averages by firm and horizon
bysort TICKER horizon: egen avg_dis_w = mean(dis_w)
bysort TICKER horizon: egen avg_num_forecasts = mean(num_forecasts)

* Plot dispersion for selected firms
twoway (connected avg_dis_w horizon if TICKER == "@SUZ", msymbol(O) msize(small)) ///
       (connected avg_dis_w horizon if TICKER == "@NOX", msymbol(D) msize(small)) ///
       (connected avg_dis_w horizon if TICKER == "@M58", msymbol(T) msize(small)) ///
       (connected avg_dis_w horizon if TICKER == "@HIT", msymbol(S) msize(small)) ///
       (connected avg_dis_w horizon if TICKER == "@SET", msymbol(+) msize(small)), ///
       title("IBES Detail") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Average Dispersion") ///
       xlabel(, angle(45)) ///
       ylabel(, angle(0)) ///
       name(detail_disp, replace) ///
       legend(off)

* Plot dispersion for Fast Retailing
twoway (connected avg_dis_w horizon if TICKER == "@XJ9", msymbol(O) msize(small)), ///
       title("Average Forecast Dispersion by Horizon") ///
       subtitle("Fast Retailing") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Average Dispersion") ///
       xlabel(, angle(45)) ///
       ylabel(, angle(0)) ///
       legend(label(1 "FAST RETAILING"))
graph export "$mypath/fast_retailing_dispersion.png", replace

* Plot number of forecasts for selected firms
twoway (connected avg_num_forecasts horizon if TICKER == "@SUZ", msymbol(O) msize(small)) ///
       (connected avg_num_forecasts horizon if TICKER == "@NOX", msymbol(D) msize(small)) ///
       (connected avg_num_forecasts horizon if TICKER == "@M58", msymbol(T) msize(small)) ///
       (connected avg_num_forecasts horizon if TICKER == "@HIT", msymbol(S) msize(small)) ///
       (connected avg_num_forecasts horizon if TICKER == "@SET", msymbol(+) msize(small)), ///
       title("IBES Detail") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Average Number of Forecasts") ///
       xlabel(, angle(45)) ///
       ylabel(, angle(0)) ///
       name(detail_numf_all, replace) ///
       legend(off)

* Summary statistics
summarize avg_dis_w horizon if inlist(TICKER, "@SUZ", "@NOX", "@M58", "@HIT", "@SET"), detail
summarize avg_dis_w horizon if TICKER == "@XJ9", detail
tabulate horizon if TICKER == "@XJ9" & !missing(avg_dis_w)
summarize avg_num_forecasts horizon if inlist(TICKER, "@SUZ", "@NOX", "@M58", "@HIT", "@SET"), detail
summarize avg_num_forecasts horizon if TICKER == "@XJ9", detail

***********************************
* PART 2: SUMMARY DATA ANALYSIS
***********************************
use "$mypath/sum_history.dta", clear

* Drop quarterly forecasts
drop if FISCALP == "QTR"

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)

* Calculate horizon and year
gen horizon = eym - sym

* Calculate average STDEV for each horizon
bysort TICKER horizon: egen avg_STDEV = mean(STDEV)
bysort TICKER horizon: egen avg_numest = mean(NUMEST)

* Plot for selected firms
twoway (connected avg_STDEV horizon if TICKER == "@SUZ", msymbol(O) msize(small)) ///
       (connected avg_STDEV horizon if TICKER == "@NOX", msymbol(D) msize(small)) ///
       (connected avg_STDEV horizon if TICKER == "@M58", msymbol(T) msize(small)) ///
       (connected avg_STDEV horizon if TICKER == "@HIT", msymbol(S) msize(small)) ///
       (connected avg_STDEV horizon if TICKER == "@SET", msymbol(+) msize(small)), ///
       title("IBES Summary") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Average Standard Deviation") ///
       xlabel(, angle(45)) ///
       ylabel(, angle(0)) ///
       name(summary_disp, replace) ///
       legend(off)

* Plot number of forecasts for selected firms (Summary)
twoway (connected avg_numest horizon if TICKER == "@SUZ", msymbol(O) msize(small)) ///
       (connected avg_numest horizon if TICKER == "@NOX", msymbol(D) msize(small)) ///
       (connected avg_numest horizon if TICKER == "@M58", msymbol(T) msize(small)) ///
       (connected avg_numest horizon if TICKER == "@HIT", msymbol(S) msize(small)) ///
       (connected avg_numest horizon if TICKER == "@SET", msymbol(+) msize(small)), ///
       title("IBES Summary") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Average Number of Estimates") ///
       xlabel(, angle(45)) ///
       ylabel(, angle(0)) ///
       name(summary_numf_all, replace) ///
       legend(off)

* Combine detail and summary plots
graph combine detail_disp summary_disp, ///
       title("Comparison of Forecast Dispersion by Horizon") ///
       subtitle("IBES Detail vs Summary") ///
       rows(1) ///
       commonscheme ///
       note("SUZUKI MOTOR (O)   NOX CORPORATION (D)   MARUI GROUP (T)   HITACHI (S)   SEGA SAMMY HOLDINGS (+)", size(small))
graph export "$mypath/avg_dispersion_comparison.png", replace

* Combine detail and summary plots for number of forecasts
graph combine detail_numf_all summary_numf_all, ///
       title("Comparison of Number of Forecasts by Horizon") ///
       subtitle("IBES Detail vs Summary") ///
       rows(1) ///
       commonscheme ///
       note("SUZUKI MOTOR (O)   NOX CORPORATION (D)   MARUI GROUP (T)   HITACHI (S)   SEGA SAMMY HOLDINGS (+)", size(small))
graph export "$mypath/avg_num_forecasts_comparison.png", replace

***********************************
* PART 3: 2015 COMPARISON
***********************************
* Detail data for 2015
use "$mypath/merged_data.dta", clear

* Drop variables if they exist
cap drop dis
cap drop dis_w
cap drop avg_dis_w
cap drop num_forecasts
cap drop avg_num_f
cap drop horizon
cap drop year_from_eym
cap drop year_from_sym

gen horizon = eym - sym
gen year_from_eym = year(dofm(eym))
gen year_from_sym = year(dofm(sym))

* Calculate dispersion
egen dis = rowsd(forecaster1-forecaster32)
winsor2 dis, suffix(_w) cuts(1 99)
bysort TICKER horizon: egen avg_dis_w = mean(dis_w)

* Plot 2015 detail data
twoway (connected avg_dis_w horizon if TICKER == "@XJ9" & horizon >= 0 & horizon <= 10 & year_from_eym == 2015, msymbol(O) msize(small)), ///
       title("IBES Detail") ///
       subtitle("Fast Retailing (2015)") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Dispersion") ///
       xlabel(0(1)10, angle(45)) ///
       ylabel(15(5)45, angle(0)) ///
       name(detail_disp, replace) ///
       legend(off)

* Summary data for 2015
use "$mypath/sum_history.dta", clear
drop if FISCALP == "QTR"

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)

gen horizon = eym - sym

* Plot 2015 summary data
twoway (connected STDEV horizon if TICKER == "@XJ9" & horizon >= 0 & horizon <= 10 & eyear == 2015, ///
       msymbol(O) msize(small)), ///
       title("IBES Summary") ///
       subtitle("Fast Retailing (2015)") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Standard Deviation") ///
       xlabel(0(1)10, angle(45)) ///
       ylabel(15(5)45) ///
       name(summary_disp, replace) ///
       legend(off)

* Combine 2015 plots
graph combine detail_disp summary_disp, ///
       title("Comparison of Forecast Dispersion by Horizon") ///
       subtitle("Fast Retailing: IBES Detail vs Summary (2015)") ///
       rows(1)
graph export "$mypath/fast_retailing_comparison_2015.png", replace

* Number of forecasts comparison for 2015
use "$mypath/merged_data.dta", clear

* Drop variables if they exist
cap drop horizon
cap drop year_from_eym
cap drop year_from_sym
cap drop num_forecasts
cap drop avg_num_f

gen horizon = eym - sym
gen year_from_eym = year(dofm(eym))
gen year_from_sym = year(dofm(sym))
egen num_forecasts = rownonmiss(forecaster1-forecaster32)

* Plot 2015 detail forecasts
twoway (connected num_forecasts horizon if TICKER == "@XJ9" & horizon >= 0 & horizon <= 10 & year_from_eym == 2015, msymbol(O) msize(small)), ///
       title("IBES Detail") ///
       subtitle("Fast Retailing (2015)") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Number of Forecasts") ///
       xlabel(0(1)10, angle(45)) ///
       ylabel(10(4)25, angle(0)) ///
       name(detail_numf, replace) ///
       legend(off)

* Summary data forecasts for 2015
use "$mypath/sum_history.dta", clear
drop if FISCALP == "QTR"

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
gen horizon = eym - sym


* Plot 2015 summary forecasts
twoway (connected NUMEST horizon if TICKER == "@XJ9" & horizon >= 0 & horizon <= 10 & eyear == 2015, msymbol(O) msize(small)), ///
       title("IBES Summary") ///
       subtitle("Fast Retailing (2015)") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Number of Estimates") ///
       xlabel(0(1)10, angle(45)) ///
       ylabel(10(4)25, angle(0)) ///
       name(summary_numf, replace) ///
       legend(off)


* Combine 2015 forecast plots
graph combine detail_disp summary_disp detail_numf summary_numf, ///
       title("Comparison of Number of Forecasts by Horizon") ///
       subtitle("Fast Retailing: IBES Detail vs Summary (2015)") ///
       rows(2) cols(2)
graph export "$mypath/fast_retailing_comparison_2015_full.png", replace