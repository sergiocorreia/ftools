
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



* Installing to a custom directory
mkdir "C:/custom_lib"
adopath ++ "C:/custom_lib"
net set ado "C:/custom_lib"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "C:/custom_lib/l/lftools.mlib"
erase "C:/custom_lib"

* If there is nothing available (besides BASE/SITE/OLDPLACE, which are ignored), install to local dir
adopath - 1
mkdir workdir
cd workdir
net set ado "`c(pwd)'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`c(pwd)'/l/lftools.mlib"
erase "C:/custom_lib"