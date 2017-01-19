clear all
cap cls
set more off
timer clear

* Prepare data

discard
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile

set obs 100
gen int year = _n
gen gdp = year*100
gen xrate = runiform()
gen rand = runiform()
gen spam = "eggs"
tempfile aggregate
drop spam // -join- doesnt support string vars
save "`aggregate'"

clear
set obs 20000000
gen long id = ceil(_n/100)
bys id: gen int year = _n
xtset id year
gen price = runiform()

timer clear

preserve
timer on 1
merge m:1 year using "`aggregate'", keepusing(gdp xrate) ///
	gen(_MERGE) nol nonotes keep(master match)
timer off 1
restore, preserve

timer on 2
join gdp xrate, from("`aggregate'") by(year) gen(_MERGE) keep(master match)
timer off 2
restore, preserve

timer on 3
fmerge m:1 year using "`aggregate'", keepusing(gdp xrate) ///
	gen(_MERGE) nol nonotes keep(master match)
timer off 3

timer list
exit
