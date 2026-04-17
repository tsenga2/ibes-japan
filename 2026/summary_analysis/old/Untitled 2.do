clear all
set more off
set graphics off

global mypath "~/Library/CloudStorage/Dropbox/IBES"

*============================================================*
* shrinkage（STDEV & FE）を shrink_spec ごとに回す
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
* 1) 生データ読み込み
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

*---------------------------------------------------------------------*
* 2) FE & CV
*---------------------------------------------------------------------*

    gen FE_MEAN   = abs(ACTUAL - MEANEST)
    gen FE_MEDIAN = abs(ACTUAL - MEDEST)
    gen CV        = STDEV / abs(MEANEST)

*---------------------------------------------------------------------*
* 3) trimming（STDEV ベース）
*---------------------------------------------------------------------*

    sort COUNTRY eyear horizon
    by COUNTRY eyear horizon: egen p5  = pctile(STDEV), p(5)
    by COUNTRY eyear horizon: egen p95 = pctile(STDEV), p(95)
    drop if STDEV < p5 | STDEV > p95

*---------------------------------------------------------------------*
* 4) horizon × TICKER 平均
*---------------------------------------------------------------------*

    collapse (mean) ///
        STDEV CV ///
        FE_MEAN FE_MEDIAN ///
        , by(TICKER pred_year COUNTRY horizon)

    reshape wide ///
        STDEV CV ///
        FE_MEAN FE_MEDIAN ///
        , i(TICKER pred_year COUNTRY) j(horizon)

*---------------------------------------------------------------------*
* 5) STDEV shrinkage（中間平均も保持）
*---------------------------------------------------------------------*

    gen STDEV_long  = (STDEV6 + STDEV7 + STDEV8 + STDEV9 + STDEV10 + STDEV11)/6
    gen STDEV_short = (STDEV0 + STDEV1 + STDEV2 + STDEV3 + STDEV4 + STDEV5)/6

    gen STDEV_6to11_vs_0to5 = 100*(STDEV_long - STDEV_short)/STDEV_long
    gen STDEV_6to11_vs_0    = 100*(STDEV_long - STDEV0)/STDEV_long
    gen STDEV_5_vs_0        = 100*(STDEV5 - STDEV0)/STDEV5

    forvalues h = 1/11 {
        gen dSTDEV`h' = ln(STDEV`h') - ln(STDEV`=`h'-1')
    }

    gen Mean_log_STDEV_change = 100*( ///
        dSTDEV1 + dSTDEV2 + dSTDEV3 + dSTDEV4 + dSTDEV5 + ///
        dSTDEV6 + dSTDEV7 + dSTDEV8 + dSTDEV9 + dSTDEV10 + dSTDEV11 ///
        )/11

    gen CV_10_vs_0 = CV10 - CV0
    gen CV_5_vs_0  = CV5  - CV0

*---------------------------------------------------------------------*
* 6) FE shrinkage（完全対称）
*---------------------------------------------------------------------*

    gen FE_long  = (FE_MEAN6 + FE_MEAN7 + FE_MEAN8 + FE_MEAN9 + FE_MEAN10 + FE_MEAN11)/6
    gen FE_short = (FE_MEAN0 + FE_MEAN1 + FE_MEAN2 + FE_MEAN3 + FE_MEAN4 + FE_MEAN5)/6

    gen FE_6to11_vs_0to5 = 100*(FE_long - FE_short)/FE_long
    gen FE_6to11_vs_0    = 100*(FE_long - FE_MEAN0)/FE_long
    gen FE_5_vs_0        = 100*(FE_MEAN5 - FE_MEAN0)/FE_MEAN5

    forvalues h = 1/11 {
        gen dFE`h' = ln(FE_MEAN`h') - ln(FE_MEAN`=`h'-1')
    }

    gen Mean_log_FE_change = 100*( ///
        dFE1 + dFE2 + dFE3 + dFE4 + dFE5 + ///
        dFE6 + dFE7 + dFE8 + dFE9 + dFE10 + dFE11 ///
        )/11

*---------------------------------------------------------------------*
* 7) horizon 平均 FE（レベル）
*---------------------------------------------------------------------*

    egen FE_MEAN   = rowmean(FE_MEAN0-FE_MEAN11)
    egen FE_MEDIAN = rowmean(FE_MEDIAN0-FE_MEDIAN11)

*---------------------------------------------------------------------*
* 8) shrink_spec に応じた変数選択
*---------------------------------------------------------------------*

    gen shrinkage_pct = .
    if "`shrink_spec'" == "STDEV_6to11_vs_0to5"    replace shrinkage_pct = STDEV_6to11_vs_0to5
    if "`shrink_spec'" == "STDEV_6to11_vs_0"       replace shrinkage_pct = STDEV_6to11_vs_0
    if "`shrink_spec'" == "STDEV_5_vs_0"           replace shrinkage_pct = STDEV_5_vs_0
    if "`shrink_spec'" == "Mean_log_STDEV_change"  replace shrinkage_pct = Mean_log_STDEV_change
    if "`shrink_spec'" == "CV_10_vs_0"             replace shrinkage_pct = CV_10_vs_0
    if "`shrink_spec'" == "CV_5_vs_0"              replace shrinkage_pct = CV_5_vs_0

*---------------------------------------------------------------------*
* 9) country × year
*---------------------------------------------------------------------*

    collapse (mean) ///
        shrinkage_pct ///
        FE_MEAN FE_MEDIAN ///
        , by(pred_year COUNTRY)

    rename pred_year year
    save "shrinkage_year_country.dta", replace

*---------------------------------------------------------------------*
* 10) dev_group merge
*---------------------------------------------------------------------*

    use "shrinkage_year_country.dta", clear
    merge m:1 COUNTRY using "country_map.dta"
    keep if _merge == 3
    drop _merge
    save "shrinkage_year_country2.dta", replace

*---------------------------------------------------------------------*
* 11) Penn World Table merge（GDP）
*---------------------------------------------------------------------*

    use "$mypath/Both/pwt1001.dta", clear
    keep if year >= 2000

    gen log_gdp    = log(rgdpe)
    gen gdp_pc     = rgdpo/pop if pop > 0
    gen gdp_pw     = rgdpo/emp if emp > 0
    gen log_gdp_pc = log(gdp_pc) if gdp_pc > 0
    gen log_gdp_pw = log(gdp_pw) if gdp_pw > 0

    merge m:1 countrycode year using "shrinkage_year_country2.dta"
    drop _merge

*---------------------------------------------------------------------*
* 12) GDP binscatter（Advanced / Others）
*---------------------------------------------------------------------*

    local outdir_gdp "$mypath/graphs/`shrink_spec'_GDP_group_binscatter"
    capture mkdir "`outdir_gdp'"

    foreach grp in 1 2 {

        preserve
            if `grp' == 1 {
                keep if dev_group == 1
                local gname "Advanced"
            }
            else {
                keep if inlist(dev_group,2,3)
                local gname "Others"
            }

            quietly count if !missing(shrinkage_pct, log_gdp_pc)
            if r(N) >= 2 {

                xtile bin = log_gdp_pc, nq(min(r(N),50))
                collapse (mean) shrinkage_pct log_gdp_pc, by(bin)

                twoway ///
                    (scatter shrinkage_pct log_gdp_pc) ///
                    (lfit shrinkage_pct log_gdp_pc), ///
                    title("`shrink_spec' vs log GDP pc (`gname')")

                graph export "`outdir_gdp'/log_gdp_pc_`gname'.png", replace
            }
        restore
    }

*---------------------------------------------------------------------*
* 13) FDI merge
*---------------------------------------------------------------------*

    use "$mypath/Both/FDI.dta", clear
    destring FDI, replace ignore(",")

    merge m:1 countrycode year using "shrinkage_year_country2.dta"
	}
