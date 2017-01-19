cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile
discard

clear all
cls
set more off

cap pr drop Bysort
pr Bysort, sortpreserve
	loc by `0'
	bys `by': gen double sum_x = sum(x)
	
	//bys `by': gen double mean_x = sum(x)
	//tempvar N
	//bys `by': gen long `N' = (x != .)
	//bys `by': replace `N' = sum(`N')
	//bys `by': replace mean_x = mean_x[_N] / _N
end

* benchmark
sysuse auto
egen double sum_foreign = sum(foreign), by(turn)
egen byte max_foreign = max(foreign), by(turn)
egen int MAX_PRICE = max(price), by(turn)
egen int _freq = count(turn), by(turn)

de *_*
drop make
mata: bench = hash1(st_data(., "_all"))
mata: bench
li in 1/10

sysuse auto, clear
fcollapse (sum) foreign (max) MAX_PRICE=price foreign, by(turn) merge freq v

de *_*
drop make
mata: ftools = hash1(st_data(., "_all"))
mata: ftools
mata: bench == ftools
li in 1/10

* TEST SPEED
clear

set obs 10000000
gen long firm = ceil(runiform() * c(N) / 10)
bys firm: gen int year = _n
xtset firm year
gen double x = rnormal()
gen int y = ceil(runiform() * 10)

// sort year
loc by year // firm



timer clear

timer on 1
egen double sum_x = sum(x), by(`by')
//egen int max_y = max(y), by(`by')
timer off 1

//de
//li in 1/10
//drop sum_x
//mata: bench = hash1(st_data(., "_all"))
//mata: bench

drop *_*

set trace off
timer on 2
fcollapse (sum) x /*(max) y*/, by(`by') merge fast verbose
timer off 2
de, short

//de
//li in 1/10
//drop sum_x
//mata: ftools = hash1(st_data(., "_all"))
//mata: ftools
//mata: bench == ftools

drop *_*
timer on 3
Bysort `by'
timer off 3

drop *_*

timer list
di as text "1 egen 2 fcollapse+merge 3 bysort"


exit
