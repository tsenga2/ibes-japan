use "/Users/kawabatahatsu/Desktop/ra/IBES/international/ibes-summary-international.dta", clear

keep if CURCODE == "JPY"

gen FE = abs(ACTUAL-MEDEST)

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

gen horizon = eym - sym
keep if horizon >= -1

preserve

winsor2 FE, replace cuts(1 99) trim

egen mean_FE = mean(FE), by(syear)
egen median_FE = median(FE), by(syear)

duplicates drop mean_FE, force

twoway (line mean_FE syear,sort)(line median_FE syear,sort) , legend(label(1 "mean_FE")) name(mean_FE, replace)



restore

preserve

winsor2 STDEV, replace cuts(1 99) trim
replace STDEV = STDEV/ACTUAL

egen mean_STDEV = mean(STDEV), by(syear)
egen median_STDEV = median(STDEV), by(syear)

duplicates drop mean_STDEV, force
twoway (line mean_STDEV syear,sort)(line median_STDEV syear,sort), legend(label(1 "mean_STDEV")) name(mean_STDEV, replace)

restore
preserve

winsor2 MEDEST, replace cuts(1 99) trim
winsor2 ACTUAL, replace cuts(1 99) trim

egen mean_MEDEST = mean(MEDEST), by(syear)
egen mean_ACTUAL = mean(ACTUAL), by(syear)
twoway (line mean_MEDEST syear,sort) (line mean_ACTUAL syear,sort), name(mean_MDAC, replace)

restore
preserve

winsor2 NUMEST, replace cuts(1 99) trim

egen mean_NUMEST = mean(NUMEST), by(syear)
egen median_NUMEST = median(NUMEST), by(syear)
duplicates drop mean_NUMEST, force
twoway (line mean_NUMEST syear,sort)(line median_NUMEST syear,sort), name(mean_NUM, replace)


restore

egen numc = count(TICKER), by(syear)

twoway (line numc syear,sort), name(numc, replace)

graph combine mean_FE mean_STDEV mean_MDAC mean_NUM numc, title("") graphregion(color(white)) name(combo, replace)


*2015のSTDEV
*NUMESTなど、事実関係
*medianもつける
*企業数
