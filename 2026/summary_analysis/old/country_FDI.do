clear all
set more off
set graphics off

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES"
global outdir "$mypath/graphs"


import delimited "$mypath/Both/FDI.csv", clear
keep if frequency == "Annual" & indicator =="Financial Development Index"

gen iso3 = ""

* ==== Region / Aggregates → missing ====

* ==== 1:1 country mapping ====
replace iso3 = "ALB" if country=="Albania"
replace iso3 = "DZA" if country=="Algeria"
replace iso3 = "AGO" if country=="Angola"
replace iso3 = "ATG" if country=="Antigua and Barbuda"
replace iso3 = "ARG" if country=="Argentina"
replace iso3 = "ARM" if country=="Armenia, Republic of"
replace iso3 = "ABW" if country=="Aruba, Kingdom of the Netherlands"
replace iso3 = "AUS" if country=="Australia"
replace iso3 = "AUT" if country=="Austria"
replace iso3 = "AZE" if country=="Azerbaijan, Republic of"
replace iso3 = "BHS" if country=="Bahamas, The"
replace iso3 = "BHR" if country=="Bahrain, Kingdom of"
replace iso3 = "BGD" if country=="Bangladesh"
replace iso3 = "BRB" if country=="Barbados"
replace iso3 = "BLR" if country=="Belarus, Republic of"
replace iso3 = "BEL" if country=="Belgium"
replace iso3 = "BLZ" if country=="Belize"
replace iso3 = "BEN" if country=="Benin"
replace iso3 = "BTN" if country=="Bhutan"
replace iso3 = "BOL" if country=="Bolivia"
replace iso3 = "BIH" if country=="Bosnia and Herzegovina"
replace iso3 = "BWA" if country=="Botswana"
replace iso3 = "BRA" if country=="Brazil"
replace iso3 = "BRN" if country=="Brunei Darussalam"
replace iso3 = "BGR" if country=="Bulgaria"
replace iso3 = "BFA" if country=="Burkina Faso"
replace iso3 = "BDI" if country=="Burundi"
replace iso3 = "CPV" if country=="Cabo Verde"
replace iso3 = "KHM" if country=="Cambodia"
replace iso3 = "CMR" if country=="Cameroon"
replace iso3 = "CAN" if country=="Canada"
replace iso3 = "CAF" if country=="Central African Republic"
replace iso3 = "TCD" if country=="Chad"
replace iso3 = "CHL" if country=="Chile"
replace iso3 = "CHN" if country=="China, People's Republic of"
replace iso3 = "COL" if country=="Colombia"
replace iso3 = "COM" if country=="Comoros, Union of the"
replace iso3 = "COD" if country=="Congo, Democratic Republic of the"
replace iso3 = "COG" if country=="Congo, Republic of"
replace iso3 = "CRI" if country=="Costa Rica"
replace iso3 = "HRV" if country=="Croatia, Republic of"
replace iso3 = "CYP" if country=="Cyprus"
replace iso3 = "CZE" if country=="Czech Republic"
replace iso3 = "CIV" if country=="Côte d'Ivoire"
replace iso3 = "DNK" if country=="Denmark"
replace iso3 = "DJI" if country=="Djibouti"
replace iso3 = "DMA" if country=="Dominica"
replace iso3 = "DOM" if country=="Dominican Republic"
replace iso3 = "ECU" if country=="Ecuador"
replace iso3 = "EGY" if country=="Egypt, Arab Republic of"
replace iso3 = "SLV" if country=="El Salvador"
replace iso3 = "GNQ" if country=="Equatorial Guinea, Republic of"
replace iso3 = "ERI" if country=="Eritrea, The State of"
replace iso3 = "EST" if country=="Estonia, Republic of"
replace iso3 = "SWZ" if country=="Eswatini, Kingdom of"
replace iso3 = "ETH" if strpos(country,"Ethiopia")
replace iso3 = "FJI" if country=="Fiji, Republic of"
replace iso3 = "FIN" if country=="Finland"
replace iso3 = "FRA" if country=="France"
replace iso3 = "PYF" if country=="French Polynesia"
replace iso3 = "GAB" if country=="Gabon"
replace iso3 = "GMB" if country=="Gambia, The"
replace iso3 = "GEO" if country=="Georgia"
replace iso3 = "DEU" if country=="Germany"
replace iso3 = "GHA" if country=="Ghana"
replace iso3 = "GRC" if country=="Greece"
replace iso3 = "GRD" if country=="Grenada"
replace iso3 = "GTM" if country=="Guatemala"
replace iso3 = "GIN" if country=="Guinea"
replace iso3 = "GNB" if country=="Guinea-Bissau"
replace iso3 = "GUY" if country=="Guyana"
replace iso3 = "HTI" if country=="Haiti"
replace iso3 = "HND" if country=="Honduras"
replace iso3 = "HKG" if strpos(country,"Hong Kong")
replace iso3 = "HUN" if country=="Hungary"
replace iso3 = "ISL" if country=="Iceland"
replace iso3 = "IND" if country=="India"
replace iso3 = "IDN" if country=="Indonesia"
replace iso3 = "IRN" if country=="Iran, Islamic Republic of"
replace iso3 = "IRL" if country=="Ireland"
replace iso3 = "ISR" if country=="Israel"
replace iso3 = "ITA" if country=="Italy"
replace iso3 = "JAM" if country=="Jamaica"
replace iso3 = "JPN" if country=="Japan"
replace iso3 = "JOR" if country=="Jordan"
replace iso3 = "KAZ" if country=="Kazakhstan, Republic of"
replace iso3 = "KEN" if country=="Kenya"
replace iso3 = "KIR" if country=="Kiribati"
replace iso3 = "KOR" if country=="Korea, Republic of"
replace iso3 = "KWT" if country=="Kuwait"
replace iso3 = "KGZ" if country=="Kyrgyz Republic"
replace iso3 = "LAO" if country=="Lao People's Democratic Republic"
replace iso3 = "LVA" if country=="Latvia, Republic of"
replace iso3 = "LBN" if country=="Lebanon"
replace iso3 = "LSO" if country=="Lesotho, Kingdom of"
replace iso3 = "LBR" if country=="Liberia"
replace iso3 = "LBY" if country=="Libya"
replace iso3 = "LTU" if country=="Lithuania, Republic of"
replace iso3 = "LUX" if country=="Luxembourg"
replace iso3 = "MAC" if strpos(country,"Macao")
replace iso3 = "MDG" if country=="Madagascar, Republic of"
replace iso3 = "MWI" if country=="Malawi"
replace iso3 = "MYS" if country=="Malaysia"
replace iso3 = "MDV" if country=="Maldives"
replace iso3 = "MLI" if country=="Mali"
replace iso3 = "MLT" if country=="Malta"
replace iso3 = "MHL" if country=="Marshall Islands, Republic of the"
replace iso3 = "MRT" if country=="Mauritania, Islamic Republic of"
replace iso3 = "MUS" if country=="Mauritius"
replace iso3 = "MEX" if country=="Mexico"
replace iso3 = "FSM" if country=="Micronesia, Federated States of"
replace iso3 = "MDA" if country=="Moldova, Republic of"
replace iso3 = "MNG" if country=="Mongolia"
replace iso3 = "MAR" if country=="Morocco"
replace iso3 = "MOZ" if country=="Mozambique, Republic of"
replace iso3 = "MMR" if country=="Myanmar"
replace iso3 = "NAM" if country=="Namibia"
replace iso3 = "NPL" if country=="Nepal"
replace iso3 = "NLD" if country=="Netherlands, The"
replace iso3 = "NZL" if country=="New Zealand"
replace iso3 = "NIC" if country=="Nicaragua"
replace iso3 = "NER" if country=="Niger"
replace iso3 = "NGA" if country=="Nigeria"
replace iso3 = "MKD" if country=="North Macedonia, Republic of"
replace iso3 = "NOR" if country=="Norway"
replace iso3 = "OMN" if country=="Oman"
replace iso3 = "PAK" if country=="Pakistan"
replace iso3 = "PAN" if country=="Panama"
replace iso3 = "PNG" if country=="Papua New Guinea"
replace iso3 = "PRY" if country=="Paraguay"
replace iso3 = "PER" if country=="Peru"
replace iso3 = "PHL" if country=="Philippines"
replace iso3 = "POL" if country=="Poland, Republic of"
replace iso3 = "PRT" if country=="Portugal"
replace iso3 = "QAT" if country=="Qatar"
replace iso3 = "ROU" if country=="Romania"
replace iso3 = "RUS" if country=="Russian Federation"
replace iso3 = "RWA" if country=="Rwanda"
replace iso3 = "WSM" if country=="Samoa"
replace iso3 = "SAU" if country=="Saudi Arabia"
replace iso3 = "SEN" if country=="Senegal"
replace iso3 = "SRB" if country=="Serbia, Republic of"
replace iso3 = "SYC" if country=="Seychelles"
replace iso3 = "SLE" if country=="Sierra Leone"
replace iso3 = "SGP" if country=="Singapore"
replace iso3 = "SVK" if country=="Slovak Republic"
replace iso3 = "SVN" if country=="Slovenia, Republic of"
replace iso3 = "SLB" if country=="Solomon Islands"
replace iso3 = "ZAF" if country=="South Africa"
replace iso3 = "SSD" if country=="South Sudan, Republic of"
replace iso3 = "ESP" if country=="Spain"
replace iso3 = "LKA" if country=="Sri Lanka"
replace iso3 = "KNA" if country=="St. Kitts and Nevis"
replace iso3 = "LCA" if country=="St. Lucia"
replace iso3 = "VCT" if country=="St. Vincent and the Grenadines"
replace iso3 = "SDN" if country=="Sudan"
replace iso3 = "SUR" if country=="Suriname"
replace iso3 = "SWE" if country=="Sweden"
replace iso3 = "CHE" if country=="Switzerland"
replace iso3 = "SYR" if country=="Syrian Arab Republic"
replace iso3 = "STP" if strpos(country,"São Tomé")
replace iso3 = "TJK" if country=="Tajikistan, Republic of"
replace iso3 = "TZA" if country=="Tanzania, United Republic of"
replace iso3 = "THA" if country=="Thailand"
replace iso3 = "TLS" if country=="Timor-Leste, Democratic Republic of"
replace iso3 = "TGO" if country=="Togo"
replace iso3 = "TON" if country=="Tonga"
replace iso3 = "TTO" if country=="Trinidad and Tobago"
replace iso3 = "TUN" if country=="Tunisia"
replace iso3 = "TKM" if country=="Turkmenistan"
replace iso3 = "TUR" if country=="Türkiye, Republic of"
replace iso3 = "UGA" if country=="Uganda"
replace iso3 = "UKR" if country=="Ukraine"
replace iso3 = "ARE" if country=="United Arab Emirates"
replace iso3 = "GBR" if country=="United Kingdom"
replace iso3 = "USA" if country=="United States"
replace iso3 = "URY" if country=="Uruguay"
replace iso3 = "UZB" if country=="Uzbekistan, Republic of"
replace iso3 = "VUT" if country=="Vanuatu"
replace iso3 = "VEN" if country=="Venezuela, República Bolivariana de"
replace iso3 = "VNM" if country=="Vietnam"
replace iso3 = "YEM" if country=="Yemen, Republic of"
replace iso3 = "ZMB" if country=="Zambia"

rename iso3 countrycode

drop if countrycode ==""

replace time_period = strtrim(time_period)              // 前後の空白を削除
gen str4 year_s = substr(time_period, 1, 4)      // 先頭4文字だけ取り出す
destring year_s, replace                  // 文字列→数値に変換
rename year_s year

keep if year >= 2000 & year <= 2019

keep countrycode year obs_value
rename obs_value FDI
save "$mypath/Both/FDI.dta", replace

use shrinkage_country.dta, clear

merge 1:1 countrycode year using "$mypath/Both/FDI.dta"

* 空白除去
replace FDI = trim(FDI)

* 文字のカンマ除去（1,234 → 1234）
replace FDI = subinstr(FDI, ",", "", .)

* よくある欠損記号 ".." → ""
replace FDI = "" if FDI == ".." | FDI == "NA" | FDI == "na" | FDI == "N/A"

* 数値化
destring FDI, replace force


corr FDI shrinkage_pct
local rho_all = round(r(rho), .001)

twoway ///
    (lfit FDI shrinkage_pct, lcolor(black)) ///
    (lfit FDI shrinkage_pct if dev_group==1, lcolor(red)) ///
    (lfit FDI shrinkage_pct if dev_group==2, lcolor(blue)) ///
    (lfit FDI shrinkage_pct if dev_group==3, lcolor(green)) ///
    (scatter FDI shrinkage_pct if dev_group==1, mcolor(red) msymbol(O)) ///
    (scatter FDI shrinkage_pct if dev_group==2, mcolor(blue) msymbol(O)) ///
    (scatter FDI shrinkage_pct if dev_group==3, mcolor(green) msymbol(O)) ///
, ///
    xtitle("Shrinkage Rate (%)") ///
    ytitle("FDI") ///
    title("FDI vs Shrinkage (All Years)") ///
    text(0.95 0.05 "Corr = `rho_all'", place(ne) size(medlarge)) ///
    legend(order(1 "Overall (fit)" 2 "Advanced (fit)" 3 "Emerging (fit)" 4 "LDC (fit)"  ///
                 5 "Advanced (scatter)" 6 "Emerging (scatter)" 7 "LDC (scatter)") pos(3)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "$outdir/fdi_all_year_scatter.png", replace

*============================================================*
* 5) 年別 scatter（3色 + Corr）:  FDI版
*============================================================*
levelsof year, local(years)

foreach y of local years {

    preserve
        keep if year==`y'

        corr FDI shrinkage_pct
        local rho = round(r(rho), .001)

        * --- 観測数 ---
        quietly count if dev_group==1
        local n1 = r(N)
        quietly count if dev_group==2
        local n2 = r(N)
        quietly count if dev_group==3
        local n3 = r(N)

        * --- dev_groupごとの線形フィット（観測数の安全確認） ---
        local fit1 ""
        local fit2 ""
        local fit3 ""

        if `n1' > 1 local fit1 "(lfit FDI shrinkage_pct if dev_group==1, lcolor(red))"
        if `n2' > 1 local fit2 "(lfit FDI shrinkage_pct if dev_group==2, lcolor(blue))"
        if `n3' > 1 local fit3 "(lfit FDI shrinkage_pct if dev_group==3, lcolor(green))"

        * --- プロット ---
        twoway ///
            (lfit FDI shrinkage_pct, lcolor(black)) ///
            `fit1' ///
            `fit2' ///
            `fit3' ///
            (scatter FDI shrinkage_pct if dev_group==1, mcolor(red)   msymbol(O)) ///
            (scatter FDI shrinkage_pct if dev_group==2, mcolor(blue)  msymbol(O)) ///
            (scatter FDI shrinkage_pct if dev_group==3, mcolor(green) msymbol(O)) ///
        , ///
            xtitle("Shrinkage Rate (%)") ///
            ytitle("FDI") ///
            title("FDI vs Shrinkage (`y')") ///
            text(0.95 0.05 "Corr = `rho'", place(ne) size(medlarge)) ///
            legend(order(1 "Overall (fit)"  ///
                         2 "Advanced (fit)"  ///
                         3 "Emerging (fit)"  ///
                         4 "LDC (fit)"  ///
                         5 "Advanced (scatter)"  ///
                         6 "Emerging (scatter)"  ///
                         7 "LDC (scatter)") pos(3)) ///
            graphregion(color(white)) ///
            plotregion(color(white))

        graph export "$outdir/fdi_scatter_`y'.png", replace
    restore
}
