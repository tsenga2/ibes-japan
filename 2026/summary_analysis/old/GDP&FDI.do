clear all
set more off
set graphics off

global mypath "/Users/hatsu/ibes-japan/ibes-japan/IBES"

*============================================================*
* shrinkage（GDP 版方式）を一度だけ作るループ
*============================================================*

foreach shrink_spec in ///
    "STDEV_6to11_vs_0to5" ///
    "STDEV_6to11_vs_0" ///
    "STDEV_5_vs_0" ///
    "Mean_log_STDEV_change" ///
    "CV_10_vs_0" ///
    "CV_5_vs_0" {

    di as text "===== Running shrinkage spec: `shrink_spec' ====="

*---------------------------------------------------------------------*
* 1) 生データ読み込み・CV作成（GDP 版） 
*---------------------------------------------------------------------*

    use "$mypath/Both/sum_history.dta", clear
    merge m:m TICKER using "$mypath/Both/ibes_summary_identif.dta"

    gen pred_year = year(STATPERS)
    gen eyear     = year(FPEDATS)

    keep if inrange(pred_year,2000,2019)
    keep if eyear != 2008
    keep if FISCALP == "ANN"
	keep if NUMEST >= 3

    gen sym = ym(year(STATPERS), month(STATPERS))
    gen eym = ym(year(FPEDATS), month(FPEDATS))
    gen horizon = eym - sym
    keep if inrange(horizon,0,11)

    gen CV = STDEV / abs(MEANEST)
    sort COUNTRY eyear horizon
    by COUNTRY eyear horizon: egen p5 = pctile(STDEV), p(5)
    by COUNTRY eyear horizon: egen p95 = pctile(STDEV), p(95)
    drop if STDEV < p5 | STDEV > p95

    collapse (mean) STDEV CV, by(TICKER pred_year COUNTRY horizon)

    reshape wide STDEV CV, i(TICKER pred_year COUNTRY) j(horizon)

*---------------------------------------------------------------------*
* 2) shrinkage 指標作成
*---------------------------------------------------------------------*

    gen STDEV_long  = (STDEV6 + STDEV7 + STDEV8 + STDEV9 + STDEV10 + STDEV11)/6
    gen STDEV_short = (STDEV0 + STDEV1 + STDEV2 + STDEV3 + STDEV4 + STDEV5)/6

    gen shrink_1 = 100*(STDEV_long - STDEV_short)/STDEV_long
    gen shrink_2 = 100*(STDEV_long - STDEV0)/STDEV_long
    gen shrink_3 = 100*(STDEV5 - STDEV0)/STDEV5

    forvalues h = 1/11 {
        gen d`h' = ln(STDEV`h') - ln(STDEV`=`h'-1')
    }

    gen shrink_4 = 100*(d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8 + d9 + d10 + d11)/11
    gen shrink_5 = CV10 - CV0
    gen shrink_6 = CV5  - CV0

    gen shrinkage_pct = .
    if "`shrink_spec'" == "STDEV_6to11_vs_0to5"    replace shrinkage_pct = shrink_1
    if "`shrink_spec'" == "STDEV_6to11_vs_0"       replace shrinkage_pct = shrink_2
    if "`shrink_spec'" == "STDEV_5_vs_0"           replace shrinkage_pct = shrink_3
    if "`shrink_spec'" == "Mean_log_STDEV_change"  replace shrinkage_pct = shrink_4
    if "`shrink_spec'" == "CV_10_vs_0"             replace shrinkage_pct = shrink_5
    if "`shrink_spec'" == "CV_5_vs_0"              replace shrinkage_pct = shrink_6

*---------------------------------------------------------------------*
* 3) 年別トリミング（p10〜p90）
*---------------------------------------------------------------------*

*    sort pred_year horizon
*    by pred_year horizon: egen p5 = pctile(STDEV), p(5)
*    by pred_year horizon: egen p95 = pctile(STDEV), p(95)
*    drop if shrinkage_pct < p5 | shrinkage_pct > p95

*---------------------------------------------------------------------*
* 4) 国年レベルへ集計
*---------------------------------------------------------------------*

    collapse (mean) shrinkage_pct, by(pred_year COUNTRY)
    rename pred_year year
    save "shrinkage_year_country.dta", replace

*---------------------------------------------------------------------*
* 5) dev_group merge
*---------------------------------------------------------------------*

    use "shrinkage_year_country.dta", clear
    merge m:1 COUNTRY using "country_map.dta"
    keep if _merge == 3
    drop _merge
    save "shrinkage_year_country2.dta", replace


*---------------------------------------------------------------------*
* 6) GDP の binscatter（Advanced / Others）
*---------------------------------------------------------------------*

    use "$mypath/Both/pwt1001.dta", clear
    keep if year >= 2000
    sort countrycode year

    gen log_gdp    = log(rgdpe)
    gen gdp_pc     = rgdpo/pop if pop > 0
    gen gdp_pw     = rgdpo/emp if emp > 0
    gen log_gdp_pc = log(gdp_pc) if gdp_pc > 0
    gen log_gdp_pw = log(gdp_pw) if gdp_pw > 0

    merge m:1 countrycode year using "shrinkage_year_country2.dta"
    keep if _merge == 3
    drop _merge

    local outdir_gdp "$mypath/graphs/`shrink_spec'_GDP_group_binscatter"
    capture mkdir "`outdir_gdp'"

    foreach grp in 1 2 {

        preserve
            if `grp' == 1 {
                keep if dev_group == 1
                local gname "Advanced"
            }
            else {
                keep if inlist(dev_group, 2, 3)
                local gname "Others"
            }

        *-------------------*
        * log GDP per capita
        *-------------------*
            quietly count if !missing(shrinkage_pct, log_gdp_pc)
            local N = r(N)

            if `N' >= 2 {

                local nbins = `N'
                if `nbins' > 50 local nbins = 50

                xtile bin = log_gdp_pc, nq(`nbins')
                collapse (mean) shrinkage_pct log_gdp_pc, by(bin)

                rename log_gdp_pc xbin
                rename shrinkage_pct ybin

                twoway ///
                    (scatter ybin xbin, mcolor(blue) msymbol(O)) ///
                    (lfit ybin xbin, lcolor(red) lwidth(medthick) legend(label(2 "`gname'"))) ///
                    , ///
                    xtitle("log(GDP per capita)") ///
                    ytitle("Shrinkage (%)") ///
                    title("Shrinkage (`shrink_spec') vs log(GDP per capita)") ///
                    legend(order(2) ring(0) position(5) region(lcolor(none)))

                graph export "`outdir_gdp'/binscatter_log_gdp_pc_`gname'.png", replace
            }
        restore

        preserve
        *-------------------*
        * log GDP per worker
        *-------------------*
            if `grp' == 1 {
                keep if dev_group == 1
                local gname "Advanced"
            }
            else {
                keep if inlist(dev_group, 2, 3)
                local gname "Others"
            }

            quietly count if !missing(shrinkage_pct, log_gdp_pw)
            local N = r(N)

            if `N' >= 2 {

                local nbins = `N'
                if `nbins' > 50 local nbins = 50

                xtile bin = log_gdp_pw, nq(`nbins')
                collapse (mean) shrinkage_pct log_gdp_pw, by(bin)
                rename log_gdp_pw xbin
                rename shrinkage_pct ybin

                twoway ///
                    (scatter ybin xbin, mcolor(blue) msymbol(O)) ///
                    (lfit ybin xbin, lcolor(red) lwidth(medthick) legend(label(2 "`gname'"))) ///
                    , ///
                    xtitle("log(GDP per worker)") ///
                    ytitle("Shrinkage (%)") ///
                    title("Shrinkage (`shrink_spec') vs log(GDP per worker)") ///
                    legend(order(2) ring(0) position(5) region(lcolor(none)))

                graph export "`outdir_gdp'/binscatter_log_gdp_pw_`gname'.png", replace
            }

        restore
    }


*---------------------------------------------------------------------*
* 7) FDI × shrinkage（Advanced / Others）
*---------------------------------------------------------------------*

    use "$mypath/Both/FDI.dta", clear

    capture confirm numeric variable FDI
    if _rc {
        replace FDI = subinstr(FDI, ",", "", .)
        replace FDI = "" if inlist(FDI,"..","NA","na","N/A")
        destring FDI, replace force
    }

    merge m:1 countrycode year using "shrinkage_year_country2.dta"
    keep if _merge == 3
    drop _merge

    local outdir_fdi "$mypath/graphs/`shrink_spec'_FDI_group_binscatter"
    capture mkdir "`outdir_fdi'"

    foreach grp in 1 2 {

        preserve
            if `grp' == 1 {
                keep if dev_group == 1
                local gname "Advanced"
            }
            else {
                keep if inlist(dev_group, 2, 3)
                local gname "Others"
            }

            quietly count if !missing(FDI, shrinkage_pct)
            local N = r(N)

            if `N' >= 2 {

                local nbins = `N'
                if `nbins' > 50 local nbins = 50

                xtile bin = FDI, nq(`nbins')
                collapse (mean) shrinkage_pct FDI, by(bin)
                rename FDI xbin
                rename shrinkage_pct ybin

                twoway ///
                    (scatter ybin xbin, mcolor(blue) msymbol(O)) ///
                    (lfit ybin xbin, lcolor(red) lwidth(medthick) legend(label(2 "`gname'"))) ///
                    , ///
                    xtitle("FDI") ///
                    ytitle("Shrinkage (%)") ///
                    title("Shrinkage (`shrink_spec') vs FDI (`gname')") ///
                    legend(order(2) ring(0) position(5) region(lcolor(none)))

                graph export "`outdir_fdi'/binscatter_FDI_`gname'.png", replace
            }

        restore
    }

}

