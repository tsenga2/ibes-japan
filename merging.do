cls
clear all
set more off
set graphics on

import delimited  "/Users/kawabatahatsu/Desktop/ra/renketsu.csv", clear

generate date = date(ap, "YM")
format date %td
drop ap

gen eyear=year(date)
gen em=month(date)
gen eym = ym(eyear, em)
format eym %tm

rename stock_code OFTIC

save renketsu1, replace

use "/Users/kawabatahatsu/Desktop/ra/IBES/international/ibes-summary-international.dta", clear

keep if CURCODE == "JPY"

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

destring OFTIC, replace force


merge m:1 OFTIC eym using "/Users/kawabatahatsu/Desktop/ra/IBES/international/renketsu1.dta"

save merged, replace
