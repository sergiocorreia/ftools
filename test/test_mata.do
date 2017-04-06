pr drop _all
clear all
set more off
include "test_utils.do"
cls

// -------------------------

sysuse auto, clear
loc vars turn trunk
replace trunk = 5 if trunk==17
gen m1 = substr(make, 1, 1)
gen m2 = "x" + string(foreign)

// -------------------------

ValidateFactor turn
ValidateFactor turn, method(hash0)
ValidateFactor turn, method(hash1)

ValidateFactor turn trunk
ValidateFactor turn trunk, method(hash0)
ValidateFactor turn trunk, method(hash1)

ValidateFactor m1
ValidateFactor m1, method(hash0)
ValidateFactor m1, method(hash1)


ValidateFactor m1 m2
ValidateFactor m1 m2, method(hash0)
ValidateFactor m1 m2, method(hash1)


// -------------------------
sysuse auto, clear
mata: F = factor("foreign turn")
mata: F.varformats
mata: F.varlabels
mata: F.varvaluelabels
mata: F.vartypes
mata: F.vl
collapse (mean) price, by(foreign turn) fast
rename foreign FOREIGN
rename turn TURN
label drop _all
mata: F.store_keys(1)


exit
