clear all
cls 
set more off


set obs 1000000
gen int year = 1916 + ceil(_n/10000)
bys year: gen firm = _n
xtset firm year
gen double v1 = runiform()
gen double v2 = runiform()
gen double v3 = runiform()
su

preserve
timer clear

timer on 1
sort year
timer off 1

restore, preserve

timer on 2
fsort year
timer off 2

timer list
exit

/* Results:


. timer list
   1:      0.77 /        1 =       0.7660
   2:      0.76 /        1 =       0.7590

*/
