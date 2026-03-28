clear all
set more off
set graphics off

global mypath "/Users/hatsu/ibes-japan/ibes-japan/IBES"
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

bysort countrycode year: gen n_ctry_year = _N


*============================================================*
* 2) すでに作ってある shrinkage_all.dta を使用
*============================================================*
    use "$mypath/outputs/shrinkage_all_specs.dta", clear
	drop if missing(countrycode)

    merge 1:1 countrycode year using "$mypath/Both/FDI.dta"
    keep if _merge==3
    drop _merge

    * FDI を完全に数値化
    replace FDI = trim(FDI)
    replace FDI = subinstr(FDI, ",", "", .)
    replace FDI = "" if FDI == ".." | FDI == "NA" | FDI == "na" | FDI == "N/A"
    destring FDI, replace force
	
save "$mypath/outputs/shrinkage_all_FDI.dta", replace
