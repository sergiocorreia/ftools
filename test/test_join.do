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
set obs 4
gen byte foreign = _n > 2
bys foreign: gen year = _n
gen xrate = foreign * 100 + year
gen rand = runiform()
save "`uuu'"

sysuse auto, clear

* Run

set trace off
join xrate, from("`uuu'" if year==1) by(foreign) keep(master match)
