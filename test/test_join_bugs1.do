clear
set obs 1
gen x = "a string that is very long"
de
tempfile using
save "`using'"

clear
set obs 1
gen x = "a string"
de
join, from("`using'") by(x)
li

isid x
exit
