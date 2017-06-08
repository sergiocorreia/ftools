/*
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile
pr drop _all
discard
*/

clear all
cls
set more off

sysuse auto
gen _brand = word(make, 1)
encode _brand, gen(brand)
//drop _brand
tab brand

local_inlist turn 40 41 42 43
keep if !(`inlist')

local_inlist _brand Fiat BMW Toyota Datsun Dodge Olds Plym. Linc. Honda Ford Fiat AMC Audi //, label
di as error `"`inlist'"'
tab brand if `inlist'


local_inlist brand Fiat BMW Toyota Datsun Dodge Olds Plym. Linc. Honda Ford Fiat AMC Audi, label
di as error `"`inlist'"'
tab brand if `inlist'

exit
