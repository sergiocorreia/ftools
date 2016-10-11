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
gen xrate = foreign * 100 + year
gen rand = runiform()
gen c = 1
la def c 1 "Const"
la val c c
drop if year != 1 // remove
la def origin 2 "Using"
la val foreign origin
save "`uuu'"
tab c
sysuse auto, clear
replace foreign = 3 in 1
tempfile mmm
save "`mmm'"
//drop make

preserve
merge m:1  for* using "`uuu'", keep(master match)
de
restore
*exit

* Run

set trace off
join xrate, from("`uuu'" if year==1) by(for=foreign) ///
	keep(using match) norep

cls
use "`uuu'", clear
keep if year==1
join, into("`mmm'") by(for)

