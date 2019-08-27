discard
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile

clear all
cls

sysuse auto

gen i = cond(_n < 10, "a", "b")
tab i


exit

mata: F = factor("turn")
mata: F = factor("i")
mata: F = factor("turn i")
