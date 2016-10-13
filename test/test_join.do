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
la var rand "RANDOM()"
gen c = 1
la def c 1 "Const"
la val c c
drop if year != 1 // remove
la def origin 2 "Using"
la val foreign origin
note :the milk
char foreign[asda] "FOOBAR"
note foreign: This is the third note for foreign
note xrate: This is the first note for xrate
note xrate: This is the second note for xrate
note: This is a note in using
char _dta[somechar] Some char info
char xrate[more] another char
note xrate: and more
//gen byte d = 1
tab c
save "`uuu'", orphans
la list

sysuse auto, clear
replace foreign = 3 in 1
gen long idx = _n
gen byte d = 1
tempfile mmm
char foreign[asda] "EGGS"
note foreign: note1!	
note foreign: note2!
note :remember
save "`mmm'"
//drop make

preserve
merge m:1 for* using "`uuu'", keep(match using) nogen debug keepus(xrate)
char list
sort idx // sort back b/c merge screws up sort
de
mata: benchmark = st_data(., .)
de
//save bench
la list
notes
tab foreign
char list
restore

* Run

set trace off
join xrate, from("`uuu'") by(for=foreign) ///
	keep(match using) v nogen

de
mata: fmerge = st_data(., .)
mata: hash1(fmerge), hash1(benchmark), hash1(fmerge)==hash1(benchmark)


* Run -into-
use "`uuu'", clear
join xrate, into("`mmm'") by(for=foreign) keep(match using) v nogen
de
mata: fmerge = st_data(., .)
mata: hash1(fmerge), hash1(benchmark), hash1(fmerge)==hash1(benchmark)
la list
notes

* Run fmerge
use "`mmm'", clear
fmerge m:1 for* using "`uuu'", keep(match using) nogen keepus(xrate) verb
mata: fmerge = st_data(., .)
mata: hash1(fmerge), hash1(benchmark), hash1(fmerge)==hash1(benchmark)


exit

//cls
use "`uuu'", clear
keep if year==1
join, into("`mmm'") by(for)
