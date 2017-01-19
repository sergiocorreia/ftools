* TODO: create a proper test

cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile

pr drop _all
clear all
cls

sysuse auto

tab turn

mata:
F = factor("turn")
F.drop_singletons()
end

gen index = _n
bys turn: gen N = _N
sort index
li if N == 1
