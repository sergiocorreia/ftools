* Regression tests on -join-

* 1) Create datasets
clear

set obs 1
gen i = _n
gen k = 1
gen x = 0
xtset i
tempfile using
save "`using'"

clear
set obs 2
gen i = _n
gen j = _n
gen k = 1
xtset j
gisid i


* 2) Run checks

preserve
	drop k
	keep in 1
	xtset
	assert r(panelvar) == "j"
	
	join, from(`"`using'"') by(i) keep(match) uniquemaster
	assert x == 0
	
	xtset
	assert r(panelvar) == "j"
restore

preserve
	drop k
	join, from(`"`using'"') by(i) keep(match) uniquemaster
	assert x == 0
restore


preserve
	replace i = 1
	*cap noi merge 1:1 i k using "`using'", keep(match)
	cap noi join, from(`"`using'"') by(i k) keep(match) uniquemaster nogen
	assert c(rc) == 459
restore

preserve
	replace i = 1	
	drop k
	cap noi join, from(`"`using'"') by(i) keep(match) uniquemaster
	assert c(rc) == 459
restore


// Done!
exit
