clear all
cap cls
set more off
timer clear

* Prepare data

discard
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/source")
ftools compile


tempfile uuu
clear
set obs 6
gen byte foreign = (_n > 2) + (_n > 4)
bys foreign: gen year = _n
gen long xrate = foreign * 100 + year
gen rand = runiform()
gen c = 1
la def c 1 "Const"
la val c c
drop if year != 1 // remove
la def origin 2 "Using"
la val foreign origin
note :the milk
char foreign[asda] "FOOBAR"
note foreign: spam
//gen byte d = 1
tab c
save "`uuu'"

sysuse auto, clear
replace foreign = 3 in 1
gen long idx = _n
gen byte d = 1
tempfile mmm
char foreign[asda] "EGGS"
save "`mmm'"
note foreign: note1!	
note foreign: note2!
note :remember
//drop make

preserve
merge m:1 for* using "`uuu'", keep(match) nogen // keepus(xrate) 
char list
sort idx // sort back b/c merge screws up sort
de
mata: benchmark = st_data(., .)
de
//save bench
restore

*exit

* Run

set trace off
join /*xrate*/, from("`uuu'") by(for=foreign) ///
	keep(match) v nogen

de
mata: fmerge = st_data(., .)
mata: hash1(fmerge), hash1(benchmark), hash1(fmerge)==hash1(benchmark)

exit

//cls
use "`uuu'", clear
keep if year==1
join, into("`mmm'") by(for)
