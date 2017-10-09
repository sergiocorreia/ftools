reghdfe, reload
ftools, compile
pr drop _all

clear all
sysuse auto
set rmsg off
set more off
cls

* Test underlying gegen command
gegen long id = group(turn), missing counts(c) fill(data)
return list

* Ensure same results
mata: F1 = factor("turn foreign", "", 1, "hash1", 1, 1, ., 0)
mata: F2 = factor("turn foreign", "", 1, "gtools", 1, 1, ., 0)
mata: assert(F1.equals(F2))

mata: F1 = factor("turn foreign", "", 1, "hash1", 1, 1, ., 1)
mata: F2 = factor("turn foreign", "", 1, "gtools", 1, 1, ., 1)
mata: assert(F1.equals(F2))

mata: F1 = factor("turn foreign", "", 1, "hash1", 1, 0, ., 1)
mata: F2 = factor("turn foreign", "", 1, "gtools", 1, 0, ., 1)
mata: assert(F1.equals(F2))

mata: F1 = factor("turn foreign", "", 1, "hash1", 1, 0, ., 0)
mata: F2 = factor("turn foreign", "", 1, "gtools", 1, 0, ., 0)
mata: assert(F1.equals(F2))


* Benchmark
clear
set obs 5000000

gen long id1 = ceil(runiform()*100000)
gen long id2 = ceil(runiform()*1000)
gen double y = runiform()

set rmsg on
mata: F = factor("id1 id2", "", 1, "", 1, 1, ., 0)
mata: F = factor("id1 id2", "", 1, "hash0", 1, 1, ., 0)
mata: F = factor("id1 id2", "", 1, "hash1", 1, 1, ., 0)
mata: F = factor("id1 id2", "", 1, "gtools", 1, 1, ., 0)

mata: F = factor("id1 id2", "", 1, "", 1, 1, ., 0)
mata: F = factor("id1 id2", "", 1, "hash0", 1, 1, ., 0)
mata: F = factor("id1 id2", "", 1, "hash1", 1, 1, ., 0)
mata: F = factor("id1 id2", "", 1, "gtools", 1, 1, ., 0)

set rmsg off

exit
