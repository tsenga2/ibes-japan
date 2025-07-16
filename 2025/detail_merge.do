cls
clear all
set graph on

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/Both"
use $mypath/det_history.dta, clear


keep if FPI == "1"
keep if PDF == "P"

drop if missing(ACTUAL)
destring FPI, replace force
drop if missing(FPI)
*drop if ANALYS == 0

gen syear=year(ANNDATS)
gen sm=month(ANNDATS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm
gen rownum = _n

*egen global_combo = group(TICKER ANALYS)
*bysort TICKER FPEDATS ANALYS (ANNDATS): gen change_flag = (global_combo != global_combo[_n-1]) if _n>1
*bysort TICKER FPEDATS ANALYS (ANNDATS): replace change_flag = 1 if _n==1

gen change_flag = 0
bysort TICKER FPEDATS ANALYS ESTIMATOR (ANNDATS ANNTIMS): ///
    replace change_flag = 1 if ANNDATS == ANNDATS[1]
	
bysort TICKER FPEDATS (ANALYS ESTIMATOR ANNDATS ANNTIMS): gen F = sum(change_flag)


rename VALUE forecaster
reshape wide forecaster, i(rownum) j(F)

foreach v of varlist forecaster* {
    bysort TICKER FPEDATS (ANNDATS ANNTIMS): ///
        replace `v' = `v'[_n-1] if missing(`v')
}

foreach v of varlist forecaster* {
	bysort sym eym TICKER: egen `v'_1 = mean(`v')
	replace `v'= `v'_1
	drop `v'_1
}

duplicates drop forecaster* TICKER FPEDATS, force
sort TICKER sym


order CNAME sym eym ACTUAL forecaster*

save "$mypath/det_data.dta", replace

*summary
use $mypath/sum_history.dta, clear
keep if FPI == "1"
drop FPI

gen syear=year(STATPERS)
gen sm=month(STATPERS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(FPEDATS)
gen em=month(FPEDATS)
gen eym = ym(eyear, em)
format eym %tm

* 例：ANNDATS（日付）が同じなら ANNTIMS（時刻）の遅いものを残す
gsort +ANNDATS -ANNTIMS   // 日付は昇順、時刻は降順
duplicates drop eym sym TICKER CURR_ACT, force


merge 1:1 TICKER CURR_ACT sym eym using "$mypath/det_data.dta"

foreach v of varlist forecaster* {
    bysort TICKER eym (sym): ///
        replace `v' = `v'[_n-1] if missing(`v')
}

sort TICKER eym sym

drop _merge

tempfile data
save `data', replace

*actual
use $mypath/det_actuals.dta, clear


gen syear=year(ANNDATS)
gen sm=month(ANNDATS)
gen sym = ym(syear, sm)
gen month = sym
format sym %tm

gen eyear=year(PENDS)
gen em=month(PENDS)
gen eym = ym(eyear, em)
format eym %tm

* QTR を上にするための一時変数を作成
gen pdicity_sort = .
replace pdicity_sort = 0 if PDICITY == "QTR"
replace pdicity_sort = 1 if PDICITY == "ANN"

* PENDSで昇順、pdicity_sortでQTR→ANNの順にソート
sort TICKER PENDS pdicity_sort

* ANNを基にグループIDを生成
by TICKER (PENDS), sort: gen byte _reset = (PDICITY == "ANN")

* 累積和でグループ番号を作る
by TICKER (PENDS): gen group_id1 = sum(_reset)
drop _reset

* 1. グループごとの最大 eym を取得する新しい変数を作る
gen eym_max = .

* 2. group_id1 ごとに最大の eym を計算
bysort TICKER group_id1 (eym): replace eym_max = eym[_N]

* 3. 最大の値をすべての行に反映させる
bysort TICKER group_id1 (eym): replace eym_max = eym_max[_n-1] if missing(eym_max)

* 4. eym を書き換える（必要なら）
replace eym = eym_max

drop if missing(VALUE)
keep if PDICITY == "QTR"
bysort TICKER group_id1 (ANNDATS): gen seq = _n
gen rownum = _n
reshape wide VALUE, i(rownum) j(seq)

foreach v of varlist VALUE* {
    bysort TICKER group_id1 (PENDS): ///
        replace `v' = `v'[_n-1] if missing(`v')
}
duplicates drop TICKER eym sym CURR_ACT, force

quietly {
    forvalues i = 1/`=_N' {
        if missing(VALUE1[`i']) {
            local newcount = 0
            forvalues j = 1/20 {
                if !missing(VALUE`j'[`i']) {
                    local newcount = `newcount' + 1
                    replace VALUE`newcount' = VALUE`j' in `i'
                    if `j' > `newcount' {
                        replace VALUE`j' = . in `i'
                    }
                }
            }
        }
    }
}

merge 1:1 TICKER CURR_ACT sym eym using `data'


foreach v of varlist ACTUAL VALUE* forecaster* {
     bysort TICKER eym (sym): ///
         replace `v' = `v'[_n-1] if missing(`v')
}

order TICKER eym sym ACTUAL VALUE* forecaster* 

drop change_flag pdicity_sort group_id1 eym_max rownum
sort TICKER eym sym

forvalues i = 1/112 {
    capture drop flag_forecaster`i'
    gen flag_forecaster`i' = .
    
    * lagをTICKERごとのeym順に取得
    gen double lag`i' = .
    by TICKER (eym), sort: replace lag`i' = forecaster`i'[_n-1]
    
    * 値が変化したかどうかを判定
    replace flag_forecaster`i' = (forecaster`i' != lag`i') if !missing(forecaster`i') & !missing(lag`i')
    
    * 前の値が欠損で今が値ありの場合は変化とみなす
    replace flag_forecaster`i' = 1 if missing(lag`i') & !missing(forecaster`i')
    
    * lag列を削除
    drop lag`i'
}

foreach i of numlist 1/112 {
    bysort TICKER eym: egen updcount`i' = total(flag_forecaster`i'), missing
    gen byte flag_u3_`i' = flag_forecaster`i'==1 & updcount`i' >= 3
}

*****************************************************
* 0. 並べ替え                                               
sort TICKER eym sym   // 「時間順」になる変数を最後に置いておく

*****************************************************
* 1. ブロック内で VALUE1 が出現したかを判定
by TICKER eym: gen byte started = !missing(VALUE1)     // 非欠損なら 1
by TICKER eym: replace  started = sum(started)         // 累積和 → 0/1/2…

/* started == 0   : VALUE1 がまだ欠損（フラグはすべて .）
   started == 1   : VALUE1 が初めて入った行（flag_VALUE1 だけ 1）
   started >= 2   : 2 行目以降（通常の変化フラグを立てる）            */

*****************************************************
* 2. VALUE* の変化フラグを作成（started ≥ 1 の行だけ）
foreach v of varlist VALUE* {
    gen flag_`v' = cond(started, (`v' != `v'[_n-1]), .)
}

*****************************************************
* 3. 「VALUE1 が初めて入った行」の特別処理
by TICKER eym: gen byte firstrow = started==1 & (_n==1 | started[_n-1]==0)

replace flag_VALUE1 = 1 if firstrow          // その行だけ 1
foreach v of varlist VALUE* {
    if "`v'" != "VALUE1" {
        replace flag_`v' = 0 if firstrow     // ほかは 0
    }
}

*****************************************************
* 4. 仕上げ（不要なら削除）
drop started firstrow

/*--------------------------------------------------------------*
 | 1. 行ごとの forecaster 非欠損カウント                         |
 *--------------------------------------------------------------*/
egen n_fcst_row = rownonmiss(forecaster*)   // 0–112

/*--------------------------------------------------------------*
 | 2. グループ最大値を各行にコピー                               |
 *--------------------------------------------------------------*/
bysort TICKER eym: egen n_fcst = max(n_fcst_row)   // ← ここがポイント
label var n_fcst "Max # of forecasters in {TICKER, eym}"

drop _merge
merge m:m OFTIC using "$mypath/ibes_summary_identif.dta"

save "$mypath/merged_data.dta", replace
stop
