clear all
set more off
cls

* Warmup
	sysuse auto
	sort turn
	fsort trunk
	hashsort turn

* Create dataset
	set obs 1000000
	gen int year = 1916 + ceil(_n/10000)
	bys year: gen firm = _n
	sort firm year
	gen double v1 = runiform()
	gen double v2 = runiform()
	gen double v3 = runiform()
	su

* Benchmark
preserve
timer clear

forv i=1/4 {
	timer on `i'
	if (`i'==1) sort year
	if (`i'==2) sort year, stable
	if (`i'==3) fsort year
	if (`i'==4) hashsort year
	timer off `i'
	mata: hash1(st_data(.,.))
	restore, preserve
	timer list
}

timer list
di c(processors)
exit

/* Results:
. timer list
   1:      0.46 /        1 =       0.4640
   2:      0.53 /        1 =       0.5260
   3:      0.49 /        1 =       0.4900
   4:      0.23 /        1 =       0.2290
*/
