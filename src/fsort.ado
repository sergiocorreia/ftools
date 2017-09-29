*! version 2.9.0 28mar2017

* Possible improvements: allow in, if, reverse sort (like gsort)
* This uses Andrew Maurer's trick to clear the sort order:
* http://www.statalist.org/forums/forum/general-stata-discussion/mata/172131-big-data-recalling-previous-sort-orders


program define fsort
	syntax varlist, [Verbose]

	loc sortvar : sortedby

	if ("`sortvar'" == "`varlist'") {
		exit
	}
	else if ("`sortvar'" != "") {
		* Andrew Maurer's trick to clear `: sortedby'
		loc sortvar : word 1 of `sortvar'
		loc val = `sortvar'[1]
		cap replace `sortvar' = 0 in 1
		cap replace `sortvar' = . in 1
		cap replace `sortvar' = "" in 1
		cap replace `sortvar' = "." in 1
		qui replace `sortvar' = `val' in 1
		assert "`: sortedby'" == ""
	}

	fsort_inner `varlist', `verbose'
	sort `varlist' // dataset already sorted by `varlist' but flag `: sortedby' not set

end


program define fsort_inner, sortpreserve
	syntax varlist, [Verbose]
	loc verbose = ("`verbose'" != "")
	mata: F = factor("`varlist'", "", `verbose', "", ., ., ., 0)
	mata: st_local("is_sorted", strofreal(F.is_sorted))
	if (!`is_sorted') {
		mata: F.panelsetup()
		mata: st_store(., "`_sortindex'", invorder(F.p))
	}
	mata: mata drop F
end


ftools, check
exit
