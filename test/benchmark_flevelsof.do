clear all
cls
timer clear

log using benchmark_flevelsof, replace name(collapse)

loc sizes 1000000 20000000

foreach size of local sizes {
	clear
	set obs `size'
	gen byte id1 = int(runiform()*10)
	gen long id2 = int(runiform()*100) * 10

	timer on 11
	levelsof id1, loc(x)
	timer off 11

	timer on 12
	flevelsof id1, loc(x)
	timer off 12

	timer on 21
	levelsof id2, loc(x)
	timer off 21

	timer on 22
	flevelsof id2, loc(x)
	timer off 22

	di as text "Sample size: `size'"
	di as text "11 12: small id - 21 22 large id"
	timer list
	timer clear
}

log close _all
exit
