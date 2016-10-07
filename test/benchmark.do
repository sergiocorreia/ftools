pr drop _all
clear all
set more off
set matadebug off
include "test_utils.do"
cls
set trace off
// -------------------------
// Profile mata

	clear
	timer clear
	loc n = 10 * 1000
	crData `n' 0 // x1 ... x5
	loc vars x5 // x2 x3 // x1 or x5


// -------------------------
// Corner cases

	clear
	timer clear
	set obs 10000

	gen long id1 = _n // many levels!!!
	gen long id2 = 1 + int(_n/1000) // a lot of levels
	gen long id3 = 1 // one level

	gen float u = runiform()
	//sort u // activate to see how it's unsorted

	forval i = 1/3 {
		loc j = 10 * `i' + 1
		timer on `j'
		egen long bench = group(id`i')
		timer off `j'

		loc ++j
		timer on `j'
		fegen small = group(id`i') ,  method(hash0) 
		timer off `j'

		loc ++j
		timer on `j'
		fegen default = group(id`i') ,  method(hash1) // ratio(2.0) nosort v 
		timer off `j'

		loc ++j
		timer on `j'
		fegen large = group(id`i') ,  method(mata) v
		timer off `j'

		assert bench == small
		assert bench == large
		assert bench == default
		drop bench small large default
	}

	keep in 1
	fegen small = group(id1) ,  method(hash0)
	fegen large = group(id2) ,  method(hash1)
	assert small == 1
	assert large == 1

	di "*1 bench *2 hash0 *3 hash1 *4 choose"
	di "0* _n 1* int(_n/1000) 2* 1"
	timer list

// -------------------------
// Profile different approaches

	clear
	timer clear
	loc n = 20 * 1000 // * 1000
	crData `n' 0 // x1 ... x5
	loc vars x5 // x2 x3 // x1 or x5

	gen u = runiform()
	loc cond // in 1/20000 if u>0.1
	set processors 2 // 1
	forval j = 1/6 {
		loc min_t`j' = .
		loc mean_t`j' = 0
	}

	loc num_t = 5

loc min99 .

forval i = 1/`num_t' {
	cap drop id*

	// Benchmark
	timer on 1
	egen id1 = group(`vars') `cond'
	timer off 1
	cap drop id*

	// First principles
	timer on 2
	fegen id2 = group(`vars') `cond', method(stata) v
	timer off 2
	cap drop id*

	// Force hash1 but sort
	timer on 3
	fegen id3 = group(`vars') `cond', method(hash1) v sort
	timer off 3
	cap drop id*

	// Force hash1; do not sort (faster)
	timer on 4
	fegen id4 = group(`vars') `cond', method(hash1) v nosort
	timer off 4
	cap drop id*

	// Force hash0; do not sort (faster)
	timer on 5
	fegen id5 = group(`vars') `cond', method(hash0) v
	timer off 5
	drop id*

	// Auto choose method
	timer on 6
	fegen id6 = group(`vars') `cond', v
	timer off 6
	drop id*

	qui timer list
	forval j = 1/6 {
		loc min_t`j' = min(`min_t`j'', r(t`j'))
		loc mean_t`j' = `mean_t`j'' + r(t`j')
	}
	loc min99 = min(`min99', r(t99))
	timer clear
}
set processors 4
*assert id1 == id2
*assert id1 == id3
*FactorsAgree id1 id4
*assert id1 == id5
mata: mata desc

loc cmds `" "benchmark " "stata-bys " hash1-sort hash1-noso "hash0     " "mata-auto " "'
di as text "Profile results with `num_t' tries:"
forval j = 1/6 {
	loc mean_t`j' = `mean_t`j'' / `num_t'
	gettoken cmd cmds : cmds
	di as text "  [`cmd'] min " %6.3f `min_t`j'' _c
	di as text " | avg " %6.3f `mean_t`j''
}

di as error `min99'
exit
