/*==============================================================================
    Comprehensive Scatter Plots: Stock Market Development (UPDATED)
    
    Creates:
    - Figure 1: 2x2 panel with LOG scale (includes HKG)
    - Figure 2: 2x2 panel excluding HKG (levels)
==============================================================================*/

clear all
set more off

* Load data
use "stock_market_panel_complete.dta", clear

/*------------------------------------------------------------------------------
    STEP 1: Create country-level averages (2000-2019)
------------------------------------------------------------------------------*/

keep if year >= 2000 & year <= 2019

collapse (mean) mktcap_gdp mktcap_usd volatility turnover traded_gdp listed_firms, ///
    by(countrycode country_name)

/*------------------------------------------------------------------------------
    STEP 2: Create region variable for coloring
------------------------------------------------------------------------------*/

gen region = ""

* East Asia & Pacific
replace region = "East Asia & Pacific" if countrycode == "AUS" | countrycode == "CHN" | countrycode == "HKG" | countrycode == "IDN" | countrycode == "JPN"
replace region = "East Asia & Pacific" if countrycode == "KOR" | countrycode == "MYS" | countrycode == "NZL" | countrycode == "PHL" | countrycode == "SGP" | countrycode == "THA"

* Europe
replace region = "Europe" if countrycode == "AUT" | countrycode == "BEL" | countrycode == "CHE" | countrycode == "DEU" | countrycode == "DNK"
replace region = "Europe" if countrycode == "ESP" | countrycode == "FIN" | countrycode == "FRA" | countrycode == "GBR" | countrycode == "GRC"
replace region = "Europe" if countrycode == "HUN" | countrycode == "IRL" | countrycode == "ITA" | countrycode == "NLD" | countrycode == "NOR"
replace region = "Europe" if countrycode == "POL" | countrycode == "PRT" | countrycode == "SWE"

* Americas
replace region = "Americas" if countrycode == "BRA" | countrycode == "CAN" | countrycode == "CHL" | countrycode == "COL" | countrycode == "MEX" | countrycode == "USA"

* Other
replace region = "Other" if countrycode == "IND" | countrycode == "ISR" | countrycode == "TUR" | countrycode == "ZAF"

encode region, gen(region_num)

/*------------------------------------------------------------------------------
    STEP 3: Create log variables
------------------------------------------------------------------------------*/

gen ln_mktcap_gdp = ln(mktcap_gdp)
gen ln_traded_gdp = ln(traded_gdp)
gen ln_turnover = ln(turnover)
gen ln_volatility = ln(volatility)

/*------------------------------------------------------------------------------
    FIGURE 1: 2x2 Panel with LOG SCALE (includes all countries)
------------------------------------------------------------------------------*/

* Figure 1a: Market Cap vs Volatility (log)
twoway (scatter ln_volatility ln_mktcap_gdp [w=traded_gdp], msymbol(circle) mcolor(navy%50)) ///
       (lfitci ln_volatility ln_mktcap_gdp, fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter ln_volatility ln_mktcap_gdp, msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(a) Market Cap vs Volatility", size(small)) ///
    xtitle("Log Market Cap (% GDP)", size(vsmall)) ytitle("Log Volatility", size(vsmall)) ///
    legend(off) name(g1_log, replace) nodraw

* Figure 1b: Market Cap vs Turnover (log)
twoway (scatter ln_turnover ln_mktcap_gdp [w=listed_firms], msymbol(circle) mcolor(forest_green%50)) ///
       (lfitci ln_turnover ln_mktcap_gdp, fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter ln_turnover ln_mktcap_gdp, msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(b) Market Cap vs Turnover", size(small)) ///
    xtitle("Log Market Cap (% GDP)", size(vsmall)) ytitle("Log Turnover", size(vsmall)) ///
    legend(off) name(g2_log, replace) nodraw

* Figure 1c: Turnover vs Volatility (log)
twoway (scatter ln_volatility ln_turnover [w=mktcap_gdp], msymbol(circle) mcolor(dkorange%50)) ///
       (lfitci ln_volatility ln_turnover, fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter ln_volatility ln_turnover, msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(c) Turnover vs Volatility", size(small)) ///
    xtitle("Log Turnover", size(vsmall)) ytitle("Log Volatility", size(vsmall)) ///
    legend(off) name(g3_log, replace) nodraw

* Figure 1d: Value Traded vs Volatility (log)
twoway (scatter ln_volatility ln_traded_gdp [w=mktcap_gdp], msymbol(circle) mcolor(purple%50)) ///
       (lfitci ln_volatility ln_traded_gdp, fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter ln_volatility ln_traded_gdp, msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(d) Value Traded vs Volatility", size(small)) ///
    xtitle("Log Value Traded (% GDP)", size(vsmall)) ytitle("Log Volatility", size(vsmall)) ///
    legend(off) name(g4_log, replace) nodraw

* Combine into 2x2 panel
graph combine g1_log g2_log g3_log g4_log, ///
    title("Stock Market Development Indicators (Log Scale)", size(medium)) ///
    subtitle("Country Averages 2000-2019, N=39", size(small)) ///
    note("Bubble sizes vary by related indicator. Lines show linear fit with 95% CI.", size(vsmall)) ///
    graphregion(color(white)) ///
    rows(2) cols(2)

graph export "scatter_panel_log.png", replace width(1600)


/*------------------------------------------------------------------------------
    FIGURE 2: 2x2 Panel EXCLUDING HKG (levels, not log)
------------------------------------------------------------------------------*/

* Figure 2a: Market Cap vs Volatility (excl HKG)
twoway (scatter volatility mktcap_gdp [w=traded_gdp] if countrycode != "HKG", msymbol(circle) mcolor(navy%50)) ///
       (lfitci volatility mktcap_gdp if countrycode != "HKG", fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter volatility mktcap_gdp if countrycode != "HKG", msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(a) Market Cap vs Volatility", size(small)) ///
    xtitle("Market Cap (% GDP)", size(vsmall)) ytitle("Volatility (%)", size(vsmall)) ///
    legend(off) name(g1_nohkg, replace) nodraw

* Figure 2b: Market Cap vs Turnover (excl HKG)
twoway (scatter turnover mktcap_gdp [w=listed_firms] if countrycode != "HKG", msymbol(circle) mcolor(forest_green%50)) ///
       (lfitci turnover mktcap_gdp if countrycode != "HKG", fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter turnover mktcap_gdp if countrycode != "HKG", msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(b) Market Cap vs Turnover", size(small)) ///
    xtitle("Market Cap (% GDP)", size(vsmall)) ytitle("Turnover (%)", size(vsmall)) ///
    legend(off) name(g2_nohkg, replace) nodraw

* Figure 2c: Turnover vs Volatility (excl HKG)
twoway (scatter volatility turnover [w=mktcap_gdp] if countrycode != "HKG", msymbol(circle) mcolor(dkorange%50)) ///
       (lfitci volatility turnover if countrycode != "HKG", fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter volatility turnover if countrycode != "HKG", msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(c) Turnover vs Volatility", size(small)) ///
    xtitle("Turnover (%)", size(vsmall)) ytitle("Volatility (%)", size(vsmall)) ///
    legend(off) name(g3_nohkg, replace) nodraw

* Figure 2d: Value Traded vs Volatility (excl HKG)
twoway (scatter volatility traded_gdp [w=mktcap_gdp] if countrycode != "HKG", msymbol(circle) mcolor(purple%50)) ///
       (lfitci volatility traded_gdp if countrycode != "HKG", fcolor(gs12%30) lcolor(cranberry) lwidth(medium)) ///
       (scatter volatility traded_gdp if countrycode != "HKG", msymbol(none) mlabel(countrycode) mlabsize(tiny) mlabcolor(black)), ///
    title("(d) Value Traded vs Volatility", size(small)) ///
    xtitle("Value Traded (% GDP)", size(vsmall)) ytitle("Volatility (%)", size(vsmall)) ///
    legend(off) name(g4_nohkg, replace) nodraw

* Combine into 2x2 panel
graph combine g1_nohkg g2_nohkg g3_nohkg g4_nohkg, ///
    title("Stock Market Development Indicators", size(medium)) ///
    subtitle("Country Averages 2000-2019, Excluding Hong Kong (N=38)", size(small)) ///
    note("Bubble sizes vary by related indicator. Lines show linear fit with 95% CI.", size(vsmall)) ///
    graphregion(color(white)) ///
    rows(2) cols(2)

graph export "scatter_panel_no_hkg.png", replace width(1600)


/*------------------------------------------------------------------------------
    Save dataset
------------------------------------------------------------------------------*/

save "stock_market_country_averages.dta", replace

di _n "============================================"
di "Figures saved:"
di "  - scatter_panel_log.png      (log scale, all 39 countries)"
di "  - scatter_panel_no_hkg.png   (levels, excluding HKG, N=38)"
di "============================================"

/*==============================================================================
    END
==============================================================================*/
