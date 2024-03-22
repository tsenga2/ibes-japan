cls
clear all


use  "/Users/kawabatahatsu/Desktop/ra/IBES/international/merged.dta", clear

keep if _merge == 3

gen horizon = eym - sym

gen Fdis_CV =  STDEV/abs(MEDEST)
gen FE_log = abs(log(ACTUAL/MEDEST))
gen FE_pct = abs(ACTUAL/MEDEST -1)

bysort CNAME: egen first_year = min(eyear)
bysort CNAME: egen Age = max(eyear - first_year)


levelsof eyear, local(levels)
foreach l of local levels{
	preserve
	keep if eyear == `l'
	duplicates drop TICKER, force
	egen num_firms = count(TICKER)
	keep eyear num_firms
	duplicates drop num_firms, force
	tempfile `l'
	save `l',replace
	restore
}
preserve


local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save num_firms.dta, replace

restore


levelsof eyear, local(levels)
foreach l of local levels{
	preserve
	keep if eyear == `l'
	keep NUMEST Fdis_CV FE_log FE_pct
	winsor2 *, replace cuts(1 99) trim
	egen mean_NUMEST = mean(NUMEST)
	egen mean_Fdis_CV = mean(Fdis_CV)
	egen mean_FE_log = mean(FE_log)
	egen mean_FE_pct = mean(FE_pct)
	gen eyear = `l'
	drop NUMEST Fdis_CV FE_log FE_pct
	duplicates drop mean_NUMEST, force
	tempfile `l'
	save `l',replace
	
	restore 
}

preserve

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save sum_year.dta, replace

restore

levelsof eyear, local(levels)
foreach l of local levels{
	preserve
	keep if eyear == `l'
	keep sale ta
	duplicates drop	*, force
	winsor2 *, replace cuts(1 99) trim
	egen mean_sale = mean(sale)
	egen mean_ta = mean(ta)
	gen eyear = `l'
	drop sale ta
	duplicates drop mean_sale, force
	tempfile `l'
	save `l',replace	
	restore 
}

local first = 1
foreach l of local levels {
    if `first' {
        use `l', clear
        local first = 0
    }
    else {
        append using `l'
    }
}


save sum_renketsu.dta, replace


merge 1:1 eyear using "/Users/kawabatahatsu/Desktop/ra/IBES/international/num_firms.dta"

save sum, replace
drop _merge 

merge 1:1 eyear using "/Users/kawabatahatsu/Desktop/ra/IBES/international/sum_year.dta"

save sum, replace
drop _merge
order eyear, first

outsheet using "sum.tex", replace


twoway (line num_firms eyear, sort), legend(label(1 "num_firms")) name(num_firms, replace)
twoway (line mean_sale eyear, sort), legend(label(1 "mean_sale")) name(mean_sale, replace)
twoway (line mean_ta eyear, sort), legend(label(1 "mean_ta")) name(mean_ta, replace)
twoway (line mean_NUMEST eyear, sort), legend(label(1 "mean_NUMEST")) name(mean_NUMEST, replace)
twoway (line mean_Fdis_CV eyear, sort), legend(label(1 "mean_Fdis_CV")) name(mean_Fdis_CV, replace)
twoway (line mean_FE_log eyear, sort), legend(label(1 "mean_FE_log")) name(mean_FE_log, replace)
twoway (line mean_FE_pct eyear, sort), legend(label(1 "mean_FE_pct")) name(mean_FE_pct, replace)

graph combine num_firms mean_sale mean_ta mean_NUMEST mean_Fdis_CV mean_FE_log mean_FE_pct, title("") graphregion(color(white)) name(combo, replace)