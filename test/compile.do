program drop _all
 
di "`c(sysdir_plus)'"
di "`c(sysdir_personal)'"

* Because we are changing adopaths in this test script, reinstall tools from source each time
local netfrom "https://github.com/reifjulian/ftools/raw/master/src/"

* Custom installation and deletion commands differ by OS
* CAUTION: these commands include a recursive deletion of a directory (temporarily) created by this test script
if "`c(os)'"=="Windows" {
	local custom_lib "C:/custom_lib"
	local deletion1 `"shell rmdir "`custom_lib'" /s /q"'
	local deletion2 `"shell rmdir "wd" /s /q"'
}

else if "`c(os)'"=="MacOSX" {
	local custom_lib "~/custom_lib"
	local deletion1 `"shell rm -r `custom_lib'"'
	local deletion2 `"shell rm -r "wd""'
}

else if "`c(os)'"=="Unix" {
	local custom_lib "~/custom_lib"
	local deletion1 `"shell rm -r -f `custom_lib'"'
	local deletion2 `"shell rm -r -f wd"'
	
	* Remove default NBER paths to ensure test script uses development version of ftools
	adopath - /home/site/etc/stata/ado.nber
}

else error 1

***********
* RUN TEST
***********

* Installing to PERSONAL
net set ado "`c(sysdir_personal)'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`c(sysdir_personal)'/l/lftools.mlib"
ado uninstall ftools , from("`c(sysdir_personal)'")
rm "`c(sysdir_personal)'/l/lftools.mlib"

* Installing to PLUS
adopath - PERSONAL
net set ado "`c(sysdir_plus)'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`c(sysdir_plus)'/l/lftools.mlib"
ado uninstall ftools , from("`c(sysdir_plus)'")
rm "`c(sysdir_plus)'/l/lftools.mlib"


* Installing to a custom directory
mkdir "`custom_lib'"
adopath ++ "`custom_lib'"
net set ado "`custom_lib'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`custom_lib'/l/lftools.mlib"
`deletion1'

* If there is nothing available (besides BASE/SITE/OLDPLACE, which are ignored), install to current working dir
adopath - 1
adopath - PLUS
mkdir wd
cd wd
local pwd "`c(pwd)'"
net set ado "`pwd'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
ftools, compile
confirm file "`pwd'/l/lftools.mlib"
cd ..
`deletion2'


* Robustness test: user adds nonsense paths to adopath (these should be ignored)
mkdir "`custom_lib'"
adopath ++ "`custom_lib'"
net set ado "`custom_lib'"
cap ado uninstall ftools
net install ftools, from(`"`netfrom'"')
mata: mata mlib index
adopath ++ "C:/does_not_exist"
adopath ++ "~32"
adopath ++ `"dfh"i"'
adopath + "z"
ftools, compile
confirm file "`custom_lib'/l/lftools.mlib"
`deletion1'

