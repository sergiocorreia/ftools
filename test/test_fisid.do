clear all
cap cls
set more off
timer clear

* Prepare data

discard
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile

use "C:\dropbox\projects\HDFE\datasets\quadros\QP_Sergio.dta" 
loc vars firm worker year

timer clear

// Benchmark
timer on 1
cap noi isid `vars'
timer off 1

// New cmd
timer on 2
cap noi fisid `vars'
timer off 2

// Raw Mata
timer on 3
mata: F = factor("`vars'", "", 0, "", 0, 1)
mata: isid = allof(F.counts, 1)
mata: isid
timer off 3

loc vars worker

// Benchmark
timer on 11
cap noi isid `vars'
timer off 11

// New cmd
timer on 12
cap noi fisid `vars'
timer off 12

// Raw Mata
timer on 13
mata: F = factor("`vars'", "", 0, "", 0, 1)
mata: isid = allof(F.counts, 1)
mata: isid
timer off 13

timer list
