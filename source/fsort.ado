*! version 1.5.0 08oct2016
cap pr drop fsort
pr fsort
	syntax varlist [if] [in] , [Generate(name)]
	
	* Apply Andrew Maurer's trick:
	* http://www.statalist.org/forums/forum/general-stata-discussion/mata/172131-big-data-recalling-previous-sort-orders
	loc sortvar : sort
	if ("`sortvar'" != "") {
		loc sortvar : word 1 of `sortvar'
		loc val = `sortvar'[1]
		cap replace `sortvar' = 0 in 1
		cap replace `sortvar' = . in 1
		cap replace `sortvar' = "" in 1
		cap replace `sortvar' = "." in 1
		qui replace `sortvar' = `val' in 1
		assert "`: sort'" == ""
	}

	mata: F = factor("`varlist'", "`touse'", 1, "", 1, 1)
	mata: F.panelsetup()
	if ("`generate'" != "") {
		mata: F.store_levels("`generate'")
	}

	foreach var of varlist _all {
		if (substr("`: type `var''", 1, 3) == "str") {
			loc strvars `strvars' `var'
		}
		else {
			loc numvars `numvars' `var'
		}
	}
	
	if ("`numvars'" != "") {
		mata: st_view(data = ., ., "`numvars'")
		mata: st_store(., tokens("`numvars'"), data[F.p, .])
	}

	if ("`strvars'" != "") {
		mata: st_sview(data = ., ., "`strvars'")
		mata: st_sstore(., tokens("`strvars'"), data[F.p, .])
	}
	mata: mata drop F
	sort `varlist'
end

ftools check
exit
