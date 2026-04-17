/*==============================================================================
    Comprehensive Scatter Plots
    FINAL – CLEAN & STATA-SAFE
    Layout: Left = x1, Right = x2
==============================================================================*/

clear all
set more off

*------------------------------------------------------------------------------
* Load data
*------------------------------------------------------------------------------
global mypath "~/Library/CloudStorage/Dropbox/IBES"
use "$mypath/outputs/shrinkage_all_specs_FDI_pwt_stock.dta", clear

*------------------------------------------------------------------------------
* STEP 1: Country averages (2000–2019)
*------------------------------------------------------------------------------
keep if year >= 2000 & year <= 2019

gen gdp_per_capita = rgdpe / pop
gen log_gdp = log(rgdpe)
gen log_gdp_per_capita = log(gdp_per_capita)

collapse (mean) ///
    STDEV_6to11_vs_0to5 STDEV_6to11_vs_0 STDEV_5_vs_0 Mean_log_STDEV_change ///
    CV_10_vs_0 CV_5_vs_0 ///
    FE_6to11_vs_0to5 FE_6to11_vs_0 FE_5_vs_0 Mean_log_FE_change ///
    FE_MEAN_all FE_MEDIAN_all ///
    FDI rgdpe rgdpo pop emp avh hc ///
    ccon cda cgdpe cgdpo cn ck ctfp cwtfp ///
    rgdpna rconna rdana rnna rkna rtfpna rwtfpna ///
    labsh irr delta xr ///
    pl_con pl_da pl_gdpo ///
    i_cig i_xm i_xr i_outlier i_irr ///
    cor_exp statcap ///
    csh_c csh_i csh_g csh_x csh_m csh_r ///
    mktcap_gdp mktcap_usd traded_gdp turnover listed_firms volatility ///
    gdp_per_capita log_gdp log_gdp_per_capita dev_group ///
    , by(countrycode country_name)

*------------------------------------------------------------------------------
* STEP 2: Y variables
*------------------------------------------------------------------------------
local y_vars ///
    STDEV_6to11_vs_0to5 STDEV_6to11_vs_0 STDEV_5_vs_0 Mean_log_STDEV_change ///
    CV_10_vs_0 CV_5_vs_0 ///
    FE_6to11_vs_0to5 FE_6to11_vs_0 FE_5_vs_0 Mean_log_FE_change ///
    FE_MEAN_all FE_MEDIAN_all

*------------------------------------------------------------------------------
* STEP 3: X variables (ORDER MATTERS)
*------------------------------------------------------------------------------
local x_vars ///
    FDI rgdpe rgdpo pop emp avh hc ///
    ccon cda cgdpe cgdpo cn ck ctfp cwtfp ///
    rgdpna rconna rdana rnna rkna rtfpna rwtfpna ///
    labsh irr delta xr ///
    pl_con pl_da pl_gdpo ///
    i_cig i_xm i_xr i_outlier i_irr ///
    cor_exp statcap ///
    csh_c csh_i csh_g csh_x csh_m csh_r ///
    mktcap_gdp mktcap_usd traded_gdp turnover listed_firms volatility ///
    gdp_per_capita log_gdp log_gdp_per_capita

*------------------------------------------------------------------------------
* STEP 4: Exclusion condition
*------------------------------------------------------------------------------
local ifcond countrycode != "HKG"

*------------------------------------------------------------------------------
* Helper: label resolver
*------------------------------------------------------------------------------
capture program drop _getlbl
program define _getlbl, rclass
    syntax, VAR(string) PREFIX(string)
    local cand "`prefix'_`var'"
    capture confirm local `cand'
    if _rc==0 {
        return local lbl "``cand''"
    }
    else {
        return local lbl "`var'"
    }
end

*------------------------------------------------------------------------------
* STEP 5A: LINEAR (by dev_group)
*------------------------------------------------------------------------------
* x の本数
local nx : word count `x_vars'

foreach y of local y_vars {

    local ysafe = strtoname("`y'")
    local ytag  = substr("`ysafe'", 1, 16)

    forvalues ix = 1/`nx' {
        local x : word `ix' of `x_vars'

        * 32文字以内＆一意（ixで識別）
        local gname = "gL_`ytag'_`=string(`ix', "%03.0f")'"

        twoway ///
            (scatter `y' `x' if `ifcond' & dev_group==1 [w=gdp_per_capita], mcolor(navy%40)  mlabel(countrycode)) ///
            (scatter `y' `x' if `ifcond' & dev_group!=1 [w=gdp_per_capita], mcolor(maroon%40) mlabel(countrycode))  ///
            (lfit `y' `x' if `ifcond' & dev_group==1, lcolor(navy)) ///
            (lfit `y' `x' if `ifcond' & dev_group!=1, lcolor(maroon)) ///
            , legend(off) name(`gname', replace)

        graph save "`gname'.gph", replace
        graph drop `gname'
    }
}


*------------------------------------------------------------------------------
* STEP 5B: QUADRATIC (pooled)
*------------------------------------------------------------------------------
local nx : word count `x_vars'

foreach y of local y_vars {

    local ysafe = strtoname("`y'")
    local ytag  = substr("`ysafe'", 1, 16)

    forvalues ix = 1/`nx' {
        local x : word `ix' of `x_vars'

        local gname = "gQ_`ytag'_`=string(`ix', "%03.0f")'"

        twoway ///
            (scatter `y' `x' if `ifcond' [w=gdp_per_capita], mcolor(navy%40) mlabel(countrycode)) ///
            (qfit `y' `x' if `ifcond', lcolor(cranberry)) ///
            , legend(off) name(`gname', replace)

        graph save "`gname'.gph", replace
        graph drop `gname'
    }
}



*------------------------------------------------------------------------------
* STEP 6: COMBINE — ALL X (2 per page)
*------------------------------------------------------------------------------
foreach y of local y_vars {

    local ysafe = strtoname("`y'")
    local ytag  = substr("`ysafe'", 1, 16)

    local page  = 1
    local nx    = wordcount("`x_vars'")

    forvalues k = 1(2)`nx' {

        local x1 : word `k' of `x_vars'
        local x2 : word `=`k'+1' of `x_vars'
        if "`x2'" == "" continue

        * 保存名を「順番」で決め打ち（Step5と完全一致）
        local gL1 = "gL_`ytag'_`=string(`k', "%03.0f")'"
        local gL2 = "gL_`ytag'_`=string(`k'+1, "%03.0f")'"
        local gQ1 = "gQ_`ytag'_`=string(`k', "%03.0f")'"
        local gQ2 = "gQ_`ytag'_`=string(`k'+1, "%03.0f")'"

        graph combine ///
            "`gL1'.gph" "`gL2'.gph" ///
            "`gQ1'.gph" "`gQ2'.gph", ///
            rows(2) cols(2) ///
            title("`y' (Page `page')", size(medium)) ///
            subtitle("Left: `x1' | Right: `x2'", size(small))

        graph export ///
            "~/ibes-japan/2026/summary_analysis/graph/scatter_`ysafe'_page`page'.png", ///
            replace width(1600)

        local ++page
    }
}



di "============================================"
di "ALL X VARIABLES COMBINED SUCCESSFULLY"
di " - Left = x1 | Right = x2"
di " - One page per X pair"
di "============================================"
