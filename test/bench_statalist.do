* Setup
clear
timer clear
set more off

* Create using dataset
clear
set obs 3000
gen long year = _n
gen long pop = _n * 1000
gen long gdp = _n * 100
tempfile using
save "`using'"

* Create master dataset
clear
set obs 1000000
gen long id = ceil(_n / 10000)
bys id: gen long year = _n
xtset id year
gen double v1 = runiform()
gen double v2 = 123


* Benchmark collapse

preserve
timer on 1
	collapse (max) v1 (median) v2, by(year) fast
timer off 1

restore, preserve
timer on 11
	fcollapse (max) v1 (median) v2, by(year) fast
timer off 11

* Benchmark merge

restore, preserve
timer on 2
	merge m:1 year using "`using'", keep(master match) keepusing(pop)
timer off 2

restore, preserve
timer on 12
	fmerge m:1 year using "`using'", keep(master match) keepusing(pop) verbose
	// join pop, from("`using'") by(year) keep(master match)
timer off 12

* Benchmark egen

restore, preserve
timer on 3
	egen max_v1 = max(v1), by(year)
	egen max_v2 = max(v2), by(year)
timer off 3
su

restore, preserve
timer on 13
	fcollapse (max) v*, by(year) merge
timer off 13
su

* Benchmark isid

restore, preserve
timer on 4
	cap noi isid year
timer off 4

restore, preserve
timer on 14
	cap noi fisid year
timer off 14

timer list

/*

1:	1.68	/	1	=	1.6800
2:	1.03	/	1	=	1.0340
3:	3.87	/	1	=	3.8710
4:	1.02	/	1	=	1.0190

11:	0.72	/	1	=	0.7210
12:	0.37	/	1	=	0.3710
13:	0.69	/	1	=	0.6910
14:	0.30	/	1	=	0.3040
*/
exit
