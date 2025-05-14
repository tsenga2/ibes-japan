global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/international"
use $mypath/det_history.dta, clear

keep if TICKER == "@XJ9"　& FPI == "1" & PDF == "P"
drop if ANALYS == 0
gen syear=year(ANNDATS)
gen sm=month(ANNDATS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm
gen rownum = _n

gen horizon = eym - sym

keep if syear == 2015 

preserve
collapse (sd) VALUE, by(horizon)
twoway (connected VALUE horizon if horizon >= 0 & horizon <= 10, msymbol(O) msize(small)), ///
       title("IBES Detail") ///
       subtitle("Fast Retailing (2015)") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Forecast Disperion") ///
       xlabel(0(1)10, angle(45)) ///
       ylabel(, angle(0)) ///
       legend(off)
restore

gen change_flag = 0
bysort TICKER FPEDATS ANALYS (ANNDATS ANNTIMS): ///
    replace change_flag = 1 if ANNDATS == ANNDATS[1]
	
bysort TICKER FPEDATS (ANNDATS ANNTIMS): gen F = sum(change_flag)


rename VALUE forecaster
reshape wide forecaster, i(rownum) j(F)

foreach v of varlist forecaster1-forecaster24 {
    bysort TICKER FPEDATS (ANNDATS ANNTIMS): ///
        replace `v' = `v'[_n-1] if missing(`v')
}

foreach v of varlist forecaster1-forecaster24 {
	bysort sym eym TICKER: egen `v'_1 = mean(`v')
	replace `v'= `v'_1
	drop `v'_1
}

duplicates drop forecaster1-forecaster24 TICKER FPEDATS, force


* Summary data for 2015
use "$mypath/sum_history.dta", clear
drop if FISCALP == "QTR"
gen horizon = (FPEDATS - STATPERS)/(365.25/12)
gen horizon_round = round(horizon)
gen year = year(FPEDATS)

bysort TICKER horizon_round: egen avg_STDEV = mean(STDEV)

* Plot 2015 summary data
twoway (connected STDEV horizon_round if TICKER == "@XJ9" & horizon_round >= 0 & horizon_round <= 10 & year == 2015, msymbol(O) msize(small)), ///
       title("IBES Summary") ///
       subtitle("Fast Retailing (2015)") ///
       xtitle("Forecast Horizon (months)") ///
       ytitle("Average Standard Deviation") ///
       xlabel(0(1)10, angle(45)) ///
       ylabel(0(5)35) ///
       name(summary, replace) ///
       legend(off)
