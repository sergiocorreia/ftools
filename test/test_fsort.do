pr drop _all
clear all
set more off
set matadebug off
include "test_utils.do"
cls

cap pr drop CheckOrder
pr CheckOrder
	syntax, vars(string) idx(string) id(string) [stable]
	if ("`stable'" != "") {
		assert `idx' == _n
		di as res "STABLE OK"
	}
	else {
		assert `id'[_n-1] <= `id' | _n == 1
		di as res "UNSTABLE OK"
	}
end

// -------------------------
// Simple commands

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

// -------------------------
// With missing Values
	qui sysuse auto, clear
	gen u = uniform()
	loc vars turn
	keep `vars' u
	replace turn = . if turn < 39
	
	sort u
	sort `vars', stable
	gen long index_bench = _n
	egen long id_bench = group(`vars'), missing
	
	sort u
	fsort `vars'
	CheckOrder, vars(`vars') idx(index_bench) id(id_bench) stable

// -------------------------
// Generating IDs
	qui sysuse auto, clear
	gen u = uniform()
	loc vars turn
	keep `vars' u
	replace turn = . if turn < 39
	
	sort u
	sort `vars', stable
	gen long index_bench = _n
	egen long id_bench = group(`vars'), missing
	
	sort u
	fsort `vars', gen(id)
	CheckOrder, vars(`vars') idx(index_bench) id(id_bench) stable
	assert id == id_bench

// -------------------------
// Larger random datasets
	clear
	timer clear
	loc n = 10 * 1000
	crData `n' 0 // x1 ... x5
	gen idx = _n
	gen long index_bench = .
	loc all_vars `" x1 "x2 x3" x4 x5 "'

	foreach vars of local all_vars {
		di as text "{bf:`vars'}"
		sort idx
		sort `vars', stable
		qui replace index_bench = _n
		egen long id_bench = group(`vars'), missing

		sort idx
		fsort `vars'
		CheckOrder, vars(`vars') idx(index_bench) id(id_bench) stable

		drop id_bench
	}

// -------------------------
// Profile
	clear
	timer clear
	loc n = 10 * 1000
	crData `n' 0 // x1 ... x5
	gen idx = _n
	gen long index_bench = .
	loc vars x1 // x1 "x2 x3" x4 x5

	profiler on
	fsort `vars'
	profiler off
	profiler report
	profiler clear
	timer list
	sort idx

	timer clear
	timer on 1
	fsort `vars'
	timer off 1
	sort idx
	timer list

// -------------------------
// Benchmark
	clear
	timer clear
	loc n = 50 * 1000 // * 1000
	crData `n' 0 // x1 ... x5
	gen idx = _n
	gen long index_bench = .
	loc all_vars `" x1 "x2 x3" x4 x5 "'
	set processors 4
	
	loc j 0
	foreach vars of local all_vars {
		loc ++j
		di as text "{bf:`vars'}"

		sort idx
		timer on `j'1
		sort `vars', stable
		timer off `j'1

		sort idx
		timer on `j'2
		sort `vars'
		timer off `j'2

		sort idx
		timer on `j'3
		fsort `vars'
		timer off `j'3
	}

	set processors 4
	di "10=10k 20=3k*.1k 30=str.1k 40=5k"
	di "1=sort+stable 2=sort 3=fsort+stable"
	timer list

exit
