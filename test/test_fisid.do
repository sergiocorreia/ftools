clear all
cap cls
set more off

use "HDFE\datasets\quadros\QP_Sergio.dta" 
loc vars firm worker year

timer clear

// Benchmark
timer on 1
cap noi isid `vars'
timer off 1

// Raw Mata
timer on 2
mata: F = factor("`vars'")
mata: isid = max(F.counts) == 1
mata: isid
timer off 2

// Raw Mata
timer on 3
mata: F = factor("`vars'", "", 0, "", 0, 1)
mata: isid = max(F.counts) == 1
mata: isid
timer off 3

timer list
