cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile
discard

clear all
cls
set more off

sysuse auto

mata: f = factor("turn")

fcollapse (sum) price, by(turn trunk)
fisid turn trunk
fsort trunk

