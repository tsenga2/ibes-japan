xclear all
set more off
set graphics off

global mypath "~/Library/CloudStorage/Dropbox/IBES"
global graphroot "$mypath/graphs"

*============================================================*
* 0) FDI データ作成（あなたのコードそのまま）
*============================================================*
import delimited "$mypath/Both/FDI.csv", clear
keep if frequency == "Annual" & indicator =="Financial Development Index"

gen iso3 = ""

replace iso3 = "AUS" if country=="Australia"
replace iso3 = "AUT" if country=="Austria"
replace iso3 = "BEL" if country=="Belgium"
replace iso3 = "BRA" if country=="Brazil"
replace iso3 = "CAN" if country=="Canada"
replace iso3 = "CHL" if country=="Chile"
replace iso3 = "CHN" if country=="China, People's Republic of"
replace iso3 = "COL" if country=="Colombia"
replace iso3 = "DNK" if country=="Denmark"
replace iso3 = "FIN" if country=="Finland"
replace iso3 = "FRA" if country=="France"
replace iso3 = "DEU" if country=="Germany"
replace iso3 = "GRC" if country=="Greece"
replace iso3 = "HKG" if strpos(country,"Hong Kong")
replace iso3 = "HUN" if country=="Hungary"
replace iso3 = "IND" if country=="India"
replace iso3 = "IDN" if country=="Indonesia"
replace iso3 = "IRL" if country=="Ireland"
replace iso3 = "ISR" if country=="Israel"
replace iso3 = "ITA" if country=="Italy"
replace iso3 = "JPN" if country=="Japan"
replace iso3 = "KOR" if country=="Korea, Republic of"
replace iso3 = "MYS" if country=="Malaysia"
replace iso3 = "MEX" if country=="Mexico"
replace iso3 = "NLD" if country=="Netherlands, The"
replace iso3 = "NZL" if country=="New Zealand"
replace iso3 = "NOR" if country=="Norway"
replace iso3 = "PHL" if country=="Philippines"
replace iso3 = "POL" if country=="Poland, Republic of"
replace iso3 = "PRT" if country=="Portugal"
replace iso3 = "SGP" if country=="Singapore"
replace iso3 = "ZAF" if country=="South Africa"
replace iso3 = "ESP" if country=="Spain"
replace iso3 = "SWE" if country=="Sweden"
replace iso3 = "CHE" if country=="Switzerland"
replace iso3 = "THA" if country=="Thailand"
replace iso3 = "TUR" if country=="Türkiye, Republic of"
replace iso3 = "GBR" if country=="United Kingdom"
replace iso3 = "USA" if country=="United States"

rename iso3 countrycode
drop if countrycode ==""

replace time_period = strtrim(time_period)
gen str4 year_s = substr(time_period, 1, 4)
destring year_s, replace
rename year_s year

keep if inrange(year,2000,2019)
keep countrycode year obs_value
rename obs_value FDI
save "$mypath/Both/FDI.dta", replace


*============================================================*
* 1) shrinkage 定義ループ（フォルダもここで分離）
*============================================================*
foreach shrink_spec in ///
    "STDEV_6to11_vs_0to5" ///
    "STDEV_6to11_vs_0" ///
    "STDEV_5_vs_0" ///
    "Mean_log_STDEV_change" ///
    "CV_10_vs_0" ///
    "CV_5_vs_0" {

    global outdir "$graphroot/FDI_`shrink_spec'"
    capture mkdir "$outdir"

    di "===== Running FDI × `shrink_spec' ====="

*============================================================*
* 2) すでに作ってある shrinkage_country.dta を使用
*============================================================*
    use shrinkage_country.dta, clear

    merge 1:1 countrycode year using "$mypath/Both/FDI.dta"
    keep if _merge==3
    drop _merge

    * FDI を完全に数値化
    replace FDI = trim(FDI)
    replace FDI = subinstr(FDI, ",", "", .)
    replace FDI = "" if FDI == ".." | FDI == "NA" | FDI == "na" | FDI == "N/A"
    destring FDI, replace force

*============================================================*
* 3) All-year scatter（FDI × shrinkage、no-obs 完全防御）
*============================================================*
    quietly count if !missing(FDI, shrinkage_pct)
    if r(N) >= 2 {

        quietly count if dev_group==1 & !missing(FDI, shrinkage_pct)
        local n1 = r(N)
        quietly count if dev_group==2 & !missing(FDI, shrinkage_pct)
        local n2 = r(N)
        quietly count if dev_group==3 & !missing(FDI, shrinkage_pct)
        local n3 = r(N)

        local fit1 ""
        local fit2 ""
        local fit3 ""
        local sc1  ""
        local sc2  ""
        local sc3  ""

        if `n1' > 1 local fit1 "(lfit FDI shrinkage_pct if dev_group==1)"
        if `n2' > 1 local fit2 "(lfit FDI shrinkage_pct if dev_group==2)"
        if `n3' > 1 local fit3 "(lfit FDI shrinkage_pct if dev_group==3)"

        if `n1' > 0 local sc1 "(scatter FDI shrinkage_pct if dev_group==1)"
        if `n2' > 0 local sc2 "(scatter FDI shrinkage_pct if dev_group==2)"
        if `n3' > 0 local sc3 "(scatter FDI shrinkage_pct if dev_group==3)"

        corr FDI shrinkage_pct
        local rho_all = round(r(rho), .001)

        twoway `fit1' `fit2' `fit3' `sc1' `sc2' `sc3', ///
            xtitle("Shrinkage Rate (%)") ///
            ytitle("FDI") ///
            title("FDI vs Shrinkage (All Years)") ///
            text(0.95 0.05 "Corr = `rho_all'", place(ne)) ///
            legend(order(1 "Advanced (fit)" 2 "Emerging (fit)" 3 "LDC (fit)" ///
                         4 "Advanced"      5 "Emerging"      6 "LDC") pos(3))

        graph export "$outdir/fdi_all_year_scatter.png", replace
    }

*============================================================*
* 4) 年別 scatter（FDI 版、完全ガード）
*============================================================*
    levelsof year, local(years)

    foreach y of local years {

        preserve
            keep if year==`y'

            quietly count if !missing(FDI, shrinkage_pct)
            if r(N) < 2 {
                restore
                continue
            }

            quietly corr FDI shrinkage_pct
            if _rc != 0 {
                restore
                continue
            }
            local rho = round(r(rho), .001)

            quietly count if dev_group==1 & !missing(FDI, shrinkage_pct)
            local n1 = r(N)
            quietly count if dev_group==2 & !missing(FDI, shrinkage_pct)
            local n2 = r(N)
            quietly count if dev_group==3 & !missing(FDI, shrinkage_pct)
            local n3 = r(N)

            local fit1 ""
            local fit2 ""
            local fit3 ""
            local sc1  ""
            local sc2  ""
            local sc3  ""

            if `n1' > 1 local fit1 "(lfit FDI shrinkage_pct if dev_group==1)"
            if `n2' > 1 local fit2 "(lfit FDI shrinkage_pct if dev_group==2)"
            if `n3' > 1 local fit3 "(lfit FDI shrinkage_pct if dev_group==3)"

            if `n1' > 0 local sc1 "(scatter FDI shrinkage_pct if dev_group==1)"
            if `n2' > 0 local sc2 "(scatter FDI shrinkage_pct if dev_group==2)"
            if `n3' > 0 local sc3 "(scatter FDI shrinkage_pct if dev_group==3)"

            twoway `fit1' `fit2' `fit3' `sc1' `sc2' `sc3', ///
                xtitle("Shrinkage Rate (%)") ///
                ytitle("FDI") ///
                title("FDI vs Shrinkage (`y')") ///
                text(0.95 0.05 "Corr = `rho'", place(ne)) ///
                legend(order(1 "Advanced (fit)" 2 "Emerging (fit)" 3 "LDC (fit)" ///
                             4 "Advanced"      5 "Emerging"      6 "LDC") pos(3))

            graph export "$outdir/fdi_scatter_`y'.png", replace
        restore
    }
}
