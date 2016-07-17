pr drop _all
clear all
set more off
set matadebug off
include "test_utils.do"
cls

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
	

// -------------------------
// Larger random datasets
set segmentsize 128m // default 32m
set niceness 10, permanently // default 5
	clear
	adopath + "./comparison"
	timer clear
	loc n = 20 * 1000 // * 1000
	crData `n' 10 // x1 ... x5; y1..
	loc all_vars `" x1 "x2 x3" x4 x5 "'

	loc all_vars x3 // `" "x2 x3" "' // x1
	loc clist (mean) x1 y1-y3 (median) X1=x1 Y1=y1 Y2=y2 Y3=y3 // (median) x5 (max) z=x5
	
	* prevent this bug:
	* http://www.statalist.org/forums/forum/general-stata-discussion/general/1312288-stata-mp-slows-the-sort
	set processors 3
	
	//sort `all_vars'
	de

	foreach vars of local all_vars {
		preserve
		timer clear
		di as text "{bf:`vars'}"
		
		timer on 1
		qui sumup x3 y1-y3, by(`vars') statistics(mean median)
		timer off 1

		timer on 2
		collapse `clist', by(`vars') fast
		timer off 2
		li in 1/5
		li in -5/-1
		
		restore, preserve

		di "(starting fcollapse)"
		timer on 3
		fcollapse `clist', by(`vars') verbose fast
		timer off 3
		li in 1/5
		li in -5/-1
		//timer list
		//timer clear
		restore
		
		timer on 4
		fcollapse `clist', by(`vars') verbose pool(5) fast
		timer off 4
		li in 1/5
		li in -5/-1

		di as text "1 other 2 default 3 me"
		di as text "20 mark 21 factor() 22 fcollapse() 23 sort"
		di as text "30 F.panelsetup() 31 st_data() 32 F.paneldata() 33 J() "
		di as text "34 results= 35 store-keys 36 store-res 37 compress"
		di as text "60 st_data 61 _factor(data)"
		di as text "70 minmax 71 hash"
		di as text "80 hash0 81 selectindex 82 dict[] 83 keys="
		di as text "84 levels= 85 counts="
		timer list
	}

set processors 4
exit



	* Initialize with random sort
	loc sortvars `" "turn" "trunk turn" "foreign turn" "foreign turn trunk" one "'
	foreach vars of local sortvars {
		di as text "{bf:`vars'}"
		qui sysuse auto, clear
		gen u = uniform()
		gen byte one = 1
		keep `vars' u
		
		sort u
		sort `vars', stable
		gen long index_bench = _n
		egen long id_bench = group(`vars'), missing
		
		sort u
		fsort `vars'
		CheckOrder, vars(`vars') idx(index_bench) id(id_bench) stable
	}
