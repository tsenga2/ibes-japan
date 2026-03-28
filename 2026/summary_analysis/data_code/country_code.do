clear
input str2 COUNTRY str3 countrycode

*====================*
* Asia / Pacific
*====================*
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

*====================*
* North America
*====================*
"NC" "CAN"
"NA" "USA"
"NB" "BMU"
"LF" "CYM"

*====================*
* Europe
*====================*
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

*====================*
* Latin America
*====================*
"LA" "ARG"
"LB" "BRA"
"LC" "CHL"
"LL" "COL"
"LM" "MEX"
"LP" "PER"
"LV" "VEN"

*====================*
* Middle East / Africa
*====================*
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

*====================*
* Special / edge cases
*====================*
"DO" "DOM"   // Dominican Republic
"AI" "AIA"   // Anguilla
"EW" "EUZ"   // Euro area (pseudo, non-ISO)
"LR" "LBR"   // Liberia
"DJ" "DJI"   // Djibouti
"GV" "GNB"   // Guinea-Bissau
"LE" "LBN"   // Lebanon
"EV" "SLV"   // El Salvador
"EJ" "JAM"   // Jamaica
"DY" "BEN"   // Benin
"KI" "KEN"   // Kenya
"KU" "KWT"   // Kuwait
"KZ" "KAZ"   // Kazakhstan
"NP" "NPL"   // Nepal
"JR" "RWA"   // Rwanda
"KT" "TZA"   // Tanzania
"LY" "LBY"   // Libya
"EQ" "GNQ"   // Equatorial Guinea
"KV" "CPV"   // Cape Verde

end
gen dev_group = .

replace dev_group = 1 if inlist(countrycode,"USA","CAN","GBR","FRA","DEU","ITA","AUS","NZL","JPN")
replace dev_group = 1 if inlist(countrycode,"KOR","SGP","CHE","SWE","NOR","NLD","BEL","AUT","DNK")
replace dev_group = 1 if inlist(countrycode,"FIN","IRL","ESP","PRT","LUX")

replace dev_group = 2 if inlist(countrycode,"CHN","IND","BRA","RUS","ZAF","MEX","THA","IDN","MYS")
replace dev_group = 2 if inlist(countrycode,"TUR","ARG","COL","PER","CHL","HUN","POL","CZE","ROU")
replace dev_group = 2 if inlist(countrycode,"SVN","PHL","SVK")

replace dev_group = 3 if inlist(countrycode,"BGD","GHA","KEN","NGA","ZWE","EGY","LKA","VEN","PAK")
replace dev_group = 3 if inlist(countrycode,"MAR","JOR","QAT","OMN","RWA")


save "$mypath/outputs/country_map.dta", replace
