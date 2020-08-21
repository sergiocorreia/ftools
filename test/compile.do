
program drop _all




*cap mkdir "$MyProject/scripts/libraries"
*cap mkdir "$MyProject/scripts/libraries/stata"
net set ado "`c(sysdir_personal)'"


*cap ado uninstall ftools, replace
*net install ftools, from("https://github.com/reifjulian/ftools/raw/master/src/")
net install ftools, from(https://github.com/sergiocorreia/ftools/raw/master/src/)
mata: mata mlib index

ftools, compile

di "`c(sysdir_plus)'"
di "`c(sysdir_personal)'"
di "`c(sysdir_oldplace)'"