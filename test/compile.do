noi cscript "ftools: compile" adofile ftools







*cap mkdir "$MyProject/scripts/libraries"
*cap mkdir "$MyProject/scripts/libraries/stata"
*net set ado "$MyProject/scripts/libraries/stata"


cap ado uninstall ftools, replace

* Install latest developer's version of the package from GitHub
foreach p in ftools {
	net install `p', from("https://raw.githubusercontent.com/reifjulian/`p'/master") replace
}


di "`c(sysdir_plus)'"
di "`c(sysdir_personal)'"
di "`c(sysdir_oldplace)'"