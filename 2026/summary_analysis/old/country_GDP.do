clear all
set more off
set graphics off

global mypath "~/Library/CloudStorage/Dropbox/IBES"
*============================================================*
* shrinkage 定義ループ（フォルダ名＝計算方法）
*============================================================*
foreach shrink_spec in ///
    "STDEV_6to11_vs_0to5" ///
    "STDEV_6to11_vs_0" ///
    "STDEV_5_vs_0" ///
    "Mean_log_STDEV_change" ///
    "CV_10_vs_0" ///
    "CV_5_vs_0" {

    global outdir "$mypath/graphs/`shrink_spec'"
    capture mkdir "$outdir"

    di "===== Running shrinkage spec: `shrink_spec' ====="

*============================================================*
* 1) 生データ段階で CV を作る → 銘柄×年×国×horizon で平均
*============================================================*
    use $mypath/Both/sum_history.dta, clear
    merge m:m TICKER using $mypath/Both/ibes_summary_identif.dta

    gen pred_year = year(STATPERS)
    gen eyear     = year(FPEDATS)

    keep if inrange(pred_year,2000,2019)
    keep if eyear != 2008
    keep if FISCALP=="ANN"

    gen sym = ym(year(STATPERS), month(STATPERS))
    gen eym = ym(year(FPEDATS),  month(FPEDATS))
    gen horizon = eym - sym
    keep if inrange(horizon,0,11)

    * ★ あなた指定どおり：ここで CV を作る
    gen CV = STDEV / MEANEST

    * ★ その後で平均
    collapse (mean) STDEV CV, by(TICKER pred_year COUNTRY horizon)

    reshape wide STDEV CV, i(TICKER pred_year COUNTRY) j(horizon)

*============================================================*
* 2) shrinkage 定義（すべて銘柄レベル）
*============================================================*
    gen STDEV_long  = (STDEV6+STDEV7+STDEV8+STDEV9+STDEV10+STDEV11)/6
    gen STDEV_short = (STDEV0+STDEV1+STDEV2+STDEV3+STDEV4+STDEV5)/6

    gen shrink_1 = 100*(STDEV_long - STDEV_short)/STDEV_long
    gen shrink_2 = 100*(STDEV_long - STDEV0)/STDEV_long
    gen shrink_3 = 100*(STDEV5 - STDEV0)/STDEV5

    forvalues h=1/11 {
        gen d`h' = ln(STDEV`h') - ln(STDEV`=`h'-1')
    }
    gen shrink_4 = 100*(d1+d2+d3+d4+d5+d6+d7+d8+d9+d10+d11)/11

    gen shrink_5 = CV10 - CV0
    gen shrink_6 = CV5  - CV0

    gen shrinkage_pct = .
    if "`shrink_spec'"=="STDEV_6to11_vs_0to5"        replace shrinkage_pct = shrink_1
    if "`shrink_spec'"=="STDEV_6to11_vs_0"           replace shrinkage_pct = shrink_2
    if "`shrink_spec'"=="STDEV_5_vs_0"               replace shrinkage_pct = shrink_3
    if "`shrink_spec'"=="Mean_log_STDEV_change"     replace shrinkage_pct = shrink_4
    if "`shrink_spec'"=="CV_10_vs_0"                 replace shrinkage_pct = shrink_5
    if "`shrink_spec'"=="CV_5_vs_0"                  replace shrinkage_pct = shrink_6

*============================================================*
* 3) 年別 trimming → 年×国平均
*============================================================*
    sort pred_year
    by pred_year: egen p10 = pctile(shrinkage_pct), p(10)
    by pred_year: egen p90 = pctile(shrinkage_pct), p(90)
    drop if shrinkage_pct < p10 | shrinkage_pct > p90

    collapse (mean) shrinkage_pct, by(pred_year COUNTRY)
    rename pred_year year
    save shrinkage_year_country.dta, replace

*============================================================*
* 4) 国分類 merge
*============================================================*
    use shrinkage_year_country.dta, clear
    merge m:1 COUNTRY using country_map.dta
    keep if _merge==3
    drop _merge
    save shrinkage_year_country2.dta, replace

*============================================================*
* 5) PWT merge
*============================================================*
    use $mypath/Both/pwt1001.dta, clear
    keep if year>=2000
    sort countrycode year
    gen log_gdp = log(rgdpe)

    merge m:1 countrycode year using shrinkage_year_country2.dta
    keep if _merge==3
    drop _merge

*============================================================*
* 6) All-year scatter（dev_group別 回帰線）
*============================================================*
    quietly count if !missing(log_gdp, shrinkage_pct)
    if r(N) >= 2 {

        quietly count if dev_group==1 & !missing(log_gdp, shrinkage_pct)
        local n1 = r(N)
        quietly count if dev_group==2 & !missing(log_gdp, shrinkage_pct)
        local n2 = r(N)
        quietly count if dev_group==3 & !missing(log_gdp, shrinkage_pct)
        local n3 = r(N)

        local fit1 ""
        local fit2 ""
        local fit3 ""
        local sc1  ""
        local sc2  ""
        local sc3  ""

        if `n1' > 1 local fit1 "(lfit log_gdp shrinkage_pct if dev_group==1, lcolor(red))"
        if `n2' > 1 local fit2 "(lfit log_gdp shrinkage_pct if dev_group==2, lcolor(blue))"
        if `n3' > 1 local fit3 "(lfit log_gdp shrinkage_pct if dev_group==3, lcolor(green))"

        if `n1' > 0 local sc1 "(scatter log_gdp shrinkage_pct if dev_group==1, mcolor(red))"
        if `n2' > 0 local sc2 "(scatter log_gdp shrinkage_pct if dev_group==2, mcolor(blue))"
        if `n3' > 0 local sc3 "(scatter log_gdp shrinkage_pct if dev_group==3, mcolor(green))"

        corr log_gdp shrinkage_pct
        local rho_all = round(r(rho), .001)

        twoway `fit1' `fit2' `fit3' `sc1' `sc2' `sc3', ///
            xtitle("Shrinkage Rate (%)") ///
            ytitle("log(GDP)") ///
            title("GDP vs Shrinkage (All Years)") ///
            text(0.95 0.05 "Corr = `rho_all'", place(ne)) ///
            legend(order(1 "Advanced (fit)" 2 "Emerging (fit)" 3 "LDC (fit)" ///
                         4 "Advanced"      5 "Emerging"      6 "LDC") pos(3))

        graph export "$outdir/all_year_scatter.png", replace
    }

*============================================================*
* 7) 年別 scatter（no observations 完全ガード）
*============================================================*
    levelsof year, local(years)

    foreach y of local years {

        preserve
            keep if year==`y'

            quietly count if !missing(log_gdp, shrinkage_pct)
            if r(N) < 2 {
                restore
                continue
            }

            quietly corr log_gdp shrinkage_pct
            if _rc != 0 {
                restore
                continue
            }
            local rho = round(r(rho), .001)

            quietly count if dev_group==1 & !missing(log_gdp, shrinkage_pct)
            local n1 = r(N)
            quietly count if dev_group==2 & !missing(log_gdp, shrinkage_pct)
            local n2 = r(N)
            quietly count if dev_group==3 & !missing(log_gdp, shrinkage_pct)
            local n3 = r(N)

            local fit1 ""
            local fit2 ""
            local fit3 ""
            local sc1  ""
            local sc2  ""
            local sc3  ""

            if `n1' > 1 local fit1 "(lfit log_gdp shrinkage_pct if dev_group==1, lcolor(red))"
            if `n2' > 1 local fit2 "(lfit log_gdp shrinkage_pct if dev_group==2, lcolor(blue))"
            if `n3' > 1 local fit3 "(lfit log_gdp shrinkage_pct if dev_group==3, lcolor(green))"

            if `n1' > 0 local sc1 "(scatter log_gdp shrinkage_pct if dev_group==1, mcolor(red))"
            if `n2' > 0 local sc2 "(scatter log_gdp shrinkage_pct if dev_group==2, mcolor(blue))"
            if `n3' > 0 local sc3 "(scatter log_gdp shrinkage_pct if dev_group==3, mcolor(green))"

            twoway `fit1' `fit2' `fit3' `sc1' `sc2' `sc3', ///
                xtitle("Shrinkage Rate (%)") ///
                ytitle("log(GDP)") ///
                title("GDP(log) vs Shrinkage (`y')") ///
                text(0.95 0.05 "Corr = `rho'", place(ne)) ///
                legend(order(1 "Advanced (fit)" 2 "Emerging (fit)" 3 "LDC (fit)" ///
                             4 "Advanced"      5 "Emerging"      6 "LDC") pos(3))

            graph export "$outdir/scatter_`y'.png", replace
        restore
    }

}
