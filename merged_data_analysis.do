global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
*global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/Both"
use "$mypath/merged_data.dta", clear

keep if TICKER == "@XJ9"
keep if eyear == 2015 
gen horizon = eym - sym
keep if horizon >= 0

sort horizon
twoway ///
    (line forecaster1 horizon, lcolor(black)) ///
    (line forecaster2 horizon, lcolor(red)) ///
    (line forecaster3 horizon, lcolor(blue)) ///
    (line forecaster4 horizon, lcolor(green)) ///
    (line forecaster5 horizon, lcolor(orange)) ///
    (line forecaster6 horizon, lcolor(brown)) ///
    (line forecaster7 horizon, lcolor(gs10)) ///
    (line forecaster8 horizon, lcolor(gs12)) ///
    (line forecaster9 horizon, lcolor(gs14)) ///
    (line forecaster10 horizon, lcolor(gs16)) ///
    (line forecaster11 horizon, lcolor(gs18)) ///
    (line forecaster12 horizon, lcolor(gs20)) ///
    (line forecaster13 horizon, lcolor(maroon)) ///
    (line forecaster14 horizon, lcolor(navy)) ///
    (line forecaster15 horizon, lcolor(teal)) ///
    (line forecaster16 horizon, lcolor(olive)) ///
    (line forecaster17 horizon, lcolor(purple)) ///
    (line forecaster18 horizon, lcolor(ltblue)) ///
    (line forecaster19 horizon, lcolor(pink)) ///
    (line forecaster20 horizon, lcolor(cyan)) ///
    (line forecaster21 horizon, lcolor(magenta)), ///
    title("Forecasts by Horizon") ///
    xtitle("Horizon") ///
    ytitle("Forecast Value") ///
    legend(off)

