clear
set more off
set graphics off

*--- 0) パス設定
global mypath "~/Library/CloudStorage/Dropbox/IBES"
global outdir "$mypath/graphs" 


use $mypath/Both/sum_history.dta, clear
capture mkdir "$outdir"

merge m:m TICKER using $mypath/Both/ibes_summary_identif.dta 

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

keep if eyear >= 2000 & eyear <= 2019 & FISCALP == "ANN"

gen horizon = eym -sym

keep if horizon >= 0 & horizon <=11

gen horizon_grp = .
replace horizon_grp = 1 if inrange(horizon, 6, 11)
replace horizon_grp = 2 if inrange(horizon, 0, 5)

tab horizon_grp


keep if eyear != 2008

sort eyear COUNTRY
by eyear COUNTRY: egen p2_5  = pctile(STDEV), p(2.5)
by eyear COUNTRY: egen p97_5 = pctile(STDEV), p(97.5)
drop if STDEV < p2_5 | STDEV > p97_5



collapse (mean) STDEV, by(COUNTRY horizon_grp)

reshape wide STDEV, i(COUNTRY) j(horizon_grp)

gen shrinkage_pct = (STDEV1 - STDEV2) / STDEV1 * 100

list COUNTRY STDEV1 STDEV2 shrinkage_pct, noobs sepby(COUNTRY)

save country_stdev.dta, replace

clear
input str3 COUNTRY str3 countrycode
"AA" "AUS"
"FB" "BGD"
"FC" "CHN"
"FH" "HKG"
"FI" "IND"
"FL" "IDN"
"FJ" "JPN"
"FK" "KOR"
"FM" "MYS"
"AN" "NZL"
"FQ" "PAK"
"FP" "PHL"
"FS" "SGP"
"BL" "LKA"
"FA" "TWN"
"FT" "THA"
"AP" "PNG"
"NC" "CAN"
"NA" "USA"
"NB" "BMU"
"LF" "CYM"
"EA" "AUT"
"EB" "BEL"
"DB" "BGR"
"DC" "HRV"
"EO" "CYP"
"EC" "CZE"
"SD" "DNK"
"DE" "EST"
"SF" "FIN"
"EF" "FRA"
"ED" "DEU"
"EH" "GRC"
"EM" "HUN"
"SI" "ISL"
"EZ" "IRL"
"FZ" "ISR"
"EI" "ITA"
"DK" "LVA"
"DL" "LTU"
"EL" "LUX"
"EN" "NLD"
"SN" "NOR"
"EG" "POL"
"EP" "PRT"
"EK" "ROU"
"ER" "RUS"
"DR" "SVK"
"DV" "SVN"
"EE" "ESP"
"SS" "SWE"
"ES" "CHE"
"ET" "TUR"
"DU" "UKR"
"EX" "GBR"
"LA" "ARG"
"LB" "BRA"
"LC" "CHL"
"LL" "COL"
"LM" "MEX"
"LP" "PER"
"LV" "VEN"
"FD" "BHR"
"KB" "BWA"
"KE" "EGY"
"KJ" "GHA"
"FR" "JOR"
"KP" "MUS"
"KM" "MAR"
"JX" "NAM"
"KN" "NGA"
"DM" "OMN"
"GQ" "QAT"
"FW" "SAU"
"KS" "ZAF"
"FU" "ARE"
"KR" "ZWE"
end

save country_map.dta, replace
merge m:1 COUNTRY using country_stdev.dta
drop if countrycode == ""
drop _merge
save country_2000.dta, replace

use $mypath/Both/pwt1001.dta, clear

* 1. 2000年以降に制限
keep if year >= 2000
gen gdp_growth = 100 * (ln(rgdpe) - ln(rgdpe[_n-1])) if countrycode==countrycode[_n-1]


* 2. 国ごとの平均を collapse（year と country, currency_unit は消さない）
collapse (mean) rgdpe rgdpo pop emp avh hc ccon cda cgdpe cgdpo cn ck ctfp cwtfp ///
                 rgdpna rconna rdana rnna rkna rtfpna rwtfpna labsh irr delta xr ///
                 pl_con pl_da pl_gdpo pl_c pl_i pl_g pl_x pl_m pl_n pl_k ///
                 csh_c csh_i csh_g csh_x csh_m csh_r statcap cor_exp gdp_growth, ///
                 by(countrycode)

merge m:1 countrycode using country_2000.dta

keep if STDEV1 != . & rgdpe != .
* GDP の大きい順に並べてランク付け
gsort -rgdpe

* 上位10カ国にフラグ
gen top10 = (_n <= 10)
gen label10 = countrycode if top10 == 1
gen bubblesize = sqrt(rgdpe)/50   // 例：平方根＋割縮


set graphics on

twoway ///
    (lfit gdp_growth shrinkage_pct, lcolor(black)) ///
    (scatter gdp_growth shrinkage_pct, ///
        msize(bubblesize) msymbol(O) mcolor(%60)) ///
    (scatter gdp_growth shrinkage_pct if top10==1, ///
        msize(bubblesize) msymbol(O) mcolor(%60) ///
        mlabel(label10) mlabpos(0) mlabcolor(black)) ///
    , ///
    xtitle("Shrinkage rate (%)") ///
    ytitle("GDP Growth Rate") ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    legend(off)


	


