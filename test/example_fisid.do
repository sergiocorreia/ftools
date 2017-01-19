clear all
cls
set more off
set trace off

cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile

sysuse auto

gen i = _n
gen j = _n if foreign

sort gear
cap noi isid turn
cap noi fisid turn

cap noi isid i
cap noi fisid i

cap noi isid i turn
cap noi fisid i turn


cap noi isid turn i turn
cap noi fisid turn i turn

cap noi isid j
cap noi fisid j

cap noi isid j, misso
cap noi fisid j, misso

cap noi fisid j if !missing(j), misso

cap noi fisid j if !missing(j), misso show
