*! version 1.5.0 08oct2016
cap pr drop fegen_group
pr fegen_group
	syntax [if] [in] , [by(varlist) type(string)] /// -by- is ignored
		name(string) args(string) ///
		[Missing Label LName(name) Truncate(numlist max=1 int >= 1) ///
		Ratio(string) Verbose METhod(string) noSORT] ///

	loc ifcmd `if'
	loc incmd `in'

	local 0 `args'
	syntax varlist

	loc if `ifcmd'
	loc in `incmd'

	* TODO: support label lname truncate

	// ----------------

	loc missing = ("`missing'" != "")
	loc verbose = ("`verbose'" != "")
	loc sort = ("`sort'" != "nosort")
	_assert inlist("`method'", "", "stata", "mata", "hash0", "hash1", "hash2")
	_assert ("`by'" == ""), msg("by() not supported")

	// ----------------

	loc markit = ("`if'`in'" != "")
	if (!`markit' & !`missing') {
		foreach var of local varlist {
			qui cou if missing(`var')
			if (r(N) > 0) {
				loc markit 1
				break
			}
		}
	}

	if (`markit') {
		tempvar touse
		mark `touse' `if' `in'
		if ("`missing'"=="") { 
			markout `touse' `varlist', strok
		}
	}

	* Choose method if not provided
	if ("`method'" == "") {
		loc usemata = (c(N) > 5e5) | (c(k) * c(N) > 5e6) | ("`touse'" != "")
		loc method = cond(`usemata', "mata", "stata")
	}

	// ----------------

	* If varlist mixes strings and integers, use alternative strategy
	loc n1 0
	loc n2 0
	
	foreach var of local varlist {
		loc type : type `var'
		if (substr("`type'", 1, 3) == "str") {
			loc ++n1
		}
		else {
			loc ++n2
		}
	}
	
	// ----------------

	loc problem = (`n1' > 0) & (`n2' > 0)
	if (`problem') {
		loc method stata
	}

	// ----------------

	if ("`method'" == "stata") {
		Group_FirstPrinciples `varlist' , id(`name') ///
			touse(`touse') verbose(`verbose')
	}
	else {
		cap noi {
			mata: F = factor("`varlist'", "`touse'", `verbose', "`method'", `sort', 0, `ratio')
			mata: F.store_levels("`name'")
		}
		loc rc = c(rc)
		cap mata: mata drop F
		error `rc'
	}
	la var `name' "group(`varlist')"
end


cap pr drop Group_FirstPrinciples
pr Group_FirstPrinciples, sortpreserve
	syntax varlist, id(name) [touse(string) Verbose(integer 0)]
	if (`verbose') {
		di as smcl "{txt}(method: {res}stata{txt})"
	}

	if ("`touse'" == "") {
		bys `varlist': gen long `id' = (_n == 1)
		qui replace `id' = sum(`id')
	}
	else {
		qui bys `touse' `varlist': gen long `id' = (_n == 1) if `touse'
		qui replace `id' = sum(`id')
		qui replace `id' = . if (`touse' != 1)
	}
	qui compress `id'
end

ftools check
exit
