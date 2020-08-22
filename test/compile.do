
program drop _all
di "`c(sysdir_plus)'"
di "`c(sysdir_personal)'"

local netfrom "https://github.com/reifjulian/ftools/raw/master/src/"


*cap mkdir "$MyProject/scripts/libraries"
*cap mkdir "$MyProject/scripts/libraries/stata"


* Installing to PERSONAL
net set ado "`c(sysdir_personal)'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`c(sysdir_personal)'/l/lftools.mlib"
ado uninstall ftools , from("`c(sysdir_personal)'")


* Installing to PLUS
adopath - PERSONAL
net set ado "`c(sysdir_plus)'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`c(sysdir_plus)'/l/lftools.mlib"
ado uninstall ftools , from("`c(sysdir_plus)'")





