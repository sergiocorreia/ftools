
pr drop _all
clear all
set more off
set matadebug off
cls
cap log close collapse
log using benchmark_fcollapse, replace name(collapse)
include "test_utils.do"

cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile


// --------------------------------------------------
// PROGRAMS
// --------------------------------------------------

cap pr drop RunOne
pr RunOne
	syntax, by(varlist) data(varlist) stats(namelist) method(string)
	assert inlist("`method'", "sumup", "collapse", "fcol", "fcolp", "tab")
	
	foreach s of local stats {
		loc zip `zip' (`s')
		foreach var of varlist `data' {
			loc zip `zip' `s'_`var'=`var'
		}
	}
	di as text "clist=<`zip'>"

	if ("`method'"=="sumup") qui sumup `data', by(`by') stat(`stats')
	if ("`method'"=="collapse") collapse `zip', by(`by') fast
	if ("`method'"=="fcol") fcollapse `zip', by(`by') fast verbose
	if ("`method'"=="fcolp") fcollapse `zip', by(`by') fast verbose pool(5)
	if ("`method'"=="tab") {
		tab `by', missing nofreq nolabel matrow(foobar)
		noi di rowsof(foobar)
	}
end


// --------------------------------------------------
// TESTING
// --------------------------------------------------

// -------------------------
// Simple commands
	qui sysuse auto, clear
	fcollapse (sum) price weight gear, by(turn) fast
	qui sysuse auto, clear
	fcollapse (sum) price weight, by(turn) pool(1) fast
	qui sysuse auto, clear
	fcollapse (sum) price weight, by(turn) pool(5)
	qui sysuse auto, clear
	fcollapse (sum) price weight (first) make (mean) gear, by(turn) pool(2) fast
	qui sysuse auto, clear
	fcollapse (sum) price weight (first) make (mean) gear, by(turn) pool(.)
	qui sysuse auto, clear
	replace trunk = . if trunk == 5
	fcollapse (sum) price weight (first) make p=price (last) q=price m=make (count) foreign trunk, by(turn) fast
	
// -------------------------
// With missing Values
	qui sysuse auto, clear
	replace price = . if foreign
	replace gear = . if turn == 31
	gen z = 1 in 1
	local stats mean median p1 p2 p4 p50 p99 sum count percent max min iqr first last firstnm lastnm
	loc i 0
	foreach stat of local stats {
		loc ++i
		loc clist `clist' (`stat') x_price_`stat'=price x_gear_`stat'=gear x_z_`stat'=z
	}
	preserve
	
	collapse `clist', by(foreign)
	reshape long x_ , i(foreign) j(cat) string
	rename x_ collapse
	tempfile benchmark
	save "`benchmark'", replace
	restore, preserve
	
	fcollapse `clist', by(foreign)
	reshape long x_ , i(foreign) j(cat) string
	rename x_ fcollapse
	merge 1:1 foreign cat using "`benchmark'", assert(match) nogen
	gen double diff = reldif(fcollapse, collapse)
	su diff
	assert diff < 1e-6
	restore, preserve
	
	* repeat for a different by()
	
	collapse `clist', by(turn)
	reshape long x_ , i(turn) j(cat) string
	rename x_ collapse
	tempfile benchmark
	save "`benchmark'", replace
	restore, preserve
	
	fcollapse `clist', by(turn)
	reshape long x_ , i(turn) j(cat) string
	rename x_ fcollapse
	merge 1:1 turn cat using "`benchmark'", assert(match) nogen
	gen double diff = reldif(fcollapse, collapse)
	su diff
	assert diff < 1e-6
	restore, preserve

	* repeat with no by()
	
	collapse `clist'
	assert _N == 1
	gen byte i = 1
	reshape long x_ , i(i) j(cat) string
	rename x_ collapse
	tempfile benchmark
	save "`benchmark'", replace
	restore, preserve
	
	fcollapse `clist'
	assert _N == 1
	gen byte i = 1
	reshape long x_ , i(i) j(cat) string
	rename x_ fcollapse
	merge 1:1 cat using "`benchmark'", assert(match) nogen
	gen double diff = reldif(fcollapse, collapse)
	su diff
	assert diff < 1e-6
	restore, preserve

	* repeat with no by() and one obs
	
	collapse `clist' in 1
	assert _N == 1
	gen byte i = 1
	reshape long x_ , i(i) j(cat) string
	rename x_ collapse
	tempfile benchmark
	save "`benchmark'", replace
	restore, preserve
	
	fcollapse `clist' in 1
	assert _N == 1
	gen byte i = 1
	reshape long x_ , i(i) j(cat) string
	rename x_ fcollapse
	merge 1:1 cat using "`benchmark'", assert(match) nogen
	gen double diff = reldif(fcollapse, collapse)
	su diff
	assert diff < 1e-6
	//restore, preserve
	restore, not
	
// --------------------------------------------------
// BENCHMARK - LARGE DATASETS
// --------------------------------------------------

// -------------------------
// Setup
	cls
	set segmentsize 128m // default 32m
	set niceness 10, permanently // default 5

	clear
	adopath + "./comparison"
	timer clear
	loc n = 20 * 1000 * 1000
	//loc n = 1 * 1000 * 1000
	crData `n' 15 // x1 ... x5; y1..

	// loc clist (mean) x1 y1-y3 (median) X1=x1 Y1=y1 Y2=y2 Y3=y3 // (median) x5 (max) z=x5

	* prevent this bug:
	* http://www.statalist.org/forums/forum/general-stata-discussion/general/1312288-stata-mp-slows-the-sort
	set processors 3

	//sort `all_vars'
	de

// -------------------------
// Run Simple
	preserve
	timer clear

	loc by x3 // `" x1 "x2 x3" x4 x5 "'
	loc stats sum
	loc vars y1-y15

	di as text "{bf:by=`by'}"
	di as text "{bf:stats=`stats'}"
	di as text "{bf:vars=`vars'}"

	loc i 0
	loc msg

	loc methods sumup collapse fcol fcolp tab

	foreach method of local methods {
		loc ++i
		di as text "{bf:[`i'] `method'}"
		restore, preserve
		timer on `i'
		RunOne, by(`by') data(`vars') stats(`stats') method(`method')
		timer off `i'
		loc msg "`msg' `i'=`method'"
	}

	di as text "`msg'"
	timer list

// -------------------------
// Run Complex
	//preserve
	timer clear

	loc by x3 // `" x1 "x2 x3" x4 x5 "'
	loc stats mean median
	loc vars y1-y3

	di as text "{bf:by=`by'}"
	di as text "{bf:stats=`stats'}"
	di as text "{bf:vars=`vars'}"

	loc i 0
	loc msg

	// loc methods sumup collapse fcol fcolp tab
	
	foreach method of local methods {
		loc ++i
		di as text "{bf:[`i'] `method'}"
		restore, preserve
		timer on `i'
		RunOne, by(`by') data(`vars') stats(`stats') method(`method')
		timer off `i'
		loc msg "`msg' `i'=`method'"
	}

	di as text "`msg'"
	timer list
set processors 4

log close collapse
exit

exit
