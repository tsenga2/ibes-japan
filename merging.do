cls
clear all
set more off


*global data_path "/Users/kawabatahatsu/Desktop/ra"
global data_path "/Users/tsenga/ibes-japan/ibes-japan"
import delimited "$data_path/renketsu.csv", clear

generate date = date(ap, "YM")
format date %td
drop ap

gen eyear=year(date)
gen em=month(date)
gen eym = ym(eyear, em)
format eym %tm

rename stock_code OFTIC

save renketsu1, replace

use "$data_path/IBES/international/ibes-summary-international.dta", clear

keep if CURCODE == "JPY"

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

destring OFTIC, replace force


merge m:1 OFTIC eym using "$data_path/renketsu1.dta"

save "$data_path/merged.dta", replace
