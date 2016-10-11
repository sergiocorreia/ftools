cap pr drop join
program define join
	syntax ///
		[namelist]  /// Variables that will be added (default is _all)
		, ///
		[from(string asis) into(string asis)] /// -using- dataset
		[by(string)] /// Primary and foreign keys
		[KEEP(string)] /// 1 master 2 using 3 match
		[ASSERT(string)] /// 1 master 2 using 3 match
		[GENerate(name) NOGENerate] /// _merge variable
		[UNIQuemaster] /// Assert that -by- is an id in the master dataset
		[NOLabel] ///
		[NONOTES] ///
		[NOREPort]
set trace on
timer on 20
	* Parse other dataset
	_assert (`"`from'"' != "") + (`"`into'"' != "") == 1, ///
		msg("specify either from() or into()")
	loc is_from = (`"`from'"' != "")
	ParseUsing `from' `into' // Return -filename- and -if-
	
	* Parse _merge
	_assert ("`generate'" != "") + ("`nogenerate'" != "") < 2, ///
		msg("generate() and nogenerate are mutually exclusive")
	if ("`nogenerate'" == "") {
		if ("`generate'" == "") loc generate _merge
		confirm new variable `generate'
	}
	else {
		tempvar generate
	}
timer off 20
timer on 21
	
	loc uniquemaster = ("`uniquemaster'" != "")
	loc nolabel = ("`nolabel'" != "")
	loc nonotes = ("`nonotes'" != "")

	ParseMerge, keep(`keep') assert(`assert')

	* Parse key variables
	ParseBy `by' /// Return -master_keys- and -using_keys-

timer off 21
	timer on 22

		* Load -using- dataset
		if (`is_from') {
			preserve
			use "`filename'", clear
			if ("`if'" != "") qui keep `if'
			loc cmd restore
		}
		else {
			loc cmd `"use `if' using "`filename'", clear"'
		}
	timer off 22
timer on 23

	if ("`namelist'" != "") {
		keep `using_keys' `namelist'
	}
	else {
		qui ds `using_keys', not
		loc namelist `r(varlist)'
	}
	unab namelist : `namelist', name(keepusing)
	unab using_keys : `using_keys'
	confirm variable `using_keys', exact

	* uniquemaster assert keep
	* nolabel nonotes
	* generate
timer off 23
timer on 24

	mata: join("`using_keys'", "`master_keys'", "`namelist'", ///
	    `"`cmd'"', "`generate'", `uniquemaster', ///
	    `keep_using', `assert_not_using')
timer off 24
timer on 25
	
	la def _merge ///
		1 "master only (1)" 2 "using only (2)" 3 "matched (3)" /// Used
		4 "missing updated (4)" 5 "nonmissing conflict (5)" // Unused
	la val `generate' _merge
timer off 25
timer on 26
	loc msg "merge:  after merge, not all observations from `assert_words'"
	if ("`assert_nums'" == "") _assert !inlist(`generate', 1, 3), msg("`msg'")
	if ("`assert_nums'" == "1") _assert !inlist(`generate', 3), msg("`msg'")
	if ("`assert_nums'" == "3") _assert !inlist(`generate', 1), msg("`msg'")

	if ("`keep_nums'" == "") drop if inlist(`generate', 1, 3)
	if ("`keep_nums'" == "1") drop if inlist(`generate', 3)
	if ("`keep_nums'" == "3") drop if inlist(`generate', 1)
timer off 26
timer on 27

* HACK: merge==2 always goes at the end so we can do -in-
* BETTER HACK: do a more complex but smarter check for assert+merge
	if ("`keep_assert'" != "1, 2, 3") {
		qui keep if inlist(`generate', `keep_nums')
	}
timer off 27

	if ("`noreport'" == "") {
		Table `generate'
	}


	// it should be _all EXCEPT by
	// if ("`namelist'" == "") loc namelist "_all"

end


cap pr drop ParseUsing
program define ParseUsing
	* SAMPLE INPUT: somefile.dta if foreign==true
	gettoken filename if : 0,
	c_local filename `filename'
	c_local if `if'
end


cap pr drop ParseMerge
program define ParseMerge
	syntax, [keep(string) assert(string)]
	if ("`keep'" == "") loc keep "master match using"
	if ("`assert'" == "") loc assert "master match using"
	loc keep_using 0
	loc assert_not_using 1

	foreach cat in keep assert {
		foreach word of local `cat' {
			if ("`word'"=="1" | substr("`word'", 1, 3) == "mas") {
				loc nums `nums' 1
				loc words `words' "master"
			}
			else if ("`word'"=="2" | substr("`word'", 1, 2) == "us") {
				if ("`cat'" == "keep") loc keep_using 1
				if ("`cat'" == "assert") loc assert_not_using 0
			}
			else if (inlist("`word'", "3", "match", "mat", "matc", "matches", "matched")) {
				loc nums `nums' 3
				loc words `words' "match"
			}
			else {
				di as error "invalid category: <`word'>"
				error 117
			}
		}
		loc words : list sort words
		loc nums : list sort nums
		c_local `cat'_words `words'
		c_local `cat'_nums `nums'
	}
end


cap pr drop ParseBy
program define ParseBy
	* SAMPLE INPUT: turn trunk
	* SAMPLE INPUT: year=time country=cou
	while ("`0'" != "") {
		gettoken right 0 : 0
		gettoken left right : right, parse("=")
		if ("`right'" != "") {
			gettoken eqsign right : right, parse("=")
			assert "`eqsign'" == "="
		}
		else {
			loc right `left'
		}
		loc master_keys `master_keys' `left'
		loc using_keys `using_keys' `right'
	}
	c_local master_keys `master_keys'
	c_local using_keys `using_keys'
end

cap pr drop Table
program define Table
	syntax varname
	tempname freqs values
	tab `varlist', nolabel nofreq matcell(`freqs') matrow(`values')

	loc N = rowsof(`freqs')
	loc is_temp = substr("`varlist'", 1, 2) == "__"
	* Initialize defaults
	forval i = 1/3 {
		loc m`i' 0
	}
	* Fill actual values
	forval i = 1/`N' {
		loc j = `values'[`i', 1]
		loc m`j' = `freqs'[`i', 1]
		if (!`is_temp') loc v`j' "(`varlist'==`j')"
	}

	* This chunk is based on merge.ado
	di
	di as smcl as txt _col(5) "Result" _col(38) "# of obs."
	di as smcl as txt _col(5) "{hline 41}"
	di as smcl as txt _col(5) "not matched" ///
	        _col(30) as res %16.0fc (`m1'+`m2')
	if (`m1'|`m2') { 
	        di as smcl as txt _col(9) "from master" ///
	                _col(30) as res %16.0fc `m1' as txt "  `v1'"
	        di as smcl as txt _col(9) "from using" ///
	                _col(30) as res %16.0fc `m2' as txt "  `v2'"
	        di
	}
    di as smcl as txt _col(5) "matched" ///
    _col(30) as res %16.0fc `m3' as txt "  `v3'"
	di as smcl as txt _col(5) "{hline 41}"

end

ftools check
findfile "ftools_type_aliases.mata"
include "`r(fn)'"

mata:
mata set matastrict on

void join(`String' using_keys,
          `String' master_keys,
          `String' varlist,
          `String' cmd,
          `Varname' generate,
          `Boolean' uniquemaster,
          `Boolean' keep_using,
          `Boolean' assert_not_using)
{
	`Varlist'				pk_names, fk_names, varnames, vartypes
	`Variables'				pk
	`Integer'				N, i, val
	`Factor'				F
	`DataFrame'				data, reshaped
	`Vector'				index, range, mask
	
	`Boolean'				integers_only
	`Boolean'				has_using

timer_on(50)
	// Using
	pk_names = tokens(using_keys)
	fk_names = tokens(master_keys)
	pk = st_data(., pk_names)
	N = rows(pk)
	timer_on(60)
	// Assert keys are unique IDs in using

	integers_only = is_integers_only(pk_names)
	F = _factor(pk, integers_only, 1, "", 0)
	assert_is_id(F, using_keys, "using")

	timer_off(60)
timer_on(61)
	varnames = tokens(varlist)
	vartypes = J(1, cols(varnames), "")
	for (i=1; i<=cols(varnames); i++) {
		vartypes[i] = st_vartype(varnames[i])
	}
timer_off(61)
timer_on( 62)
	data = st_data(., varnames) , J(st_nobs(), 1, 3) // _merge==3
timer_off(62)
	// Master
	timer_on(63)
	stata(cmd) // load (either -restore- or -use-)
	timer_off(63)
	timer_on(64)
	
	integers_only = integers_only & is_integers_only(fk_names)
	integers_only, integers_only, integers_only
	F = _factor(pk \ st_data(., fk_names), integers_only, 1, "", 0)

	timer_off(64)
	timer_on(65)
	index = F.levels[| 1 \ N |]
	reshaped = J(F.num_levels, cols(data)-1, .) , J(F.num_levels, 1, 1) // _merge==1
	reshaped[index, .] = data
	timer_off(65)
	timer_on(66)
	index = F.levels[| N+1 \ . |]
	timer_off(66)
	timer_on(67)
	reshaped = reshaped[index , .]
timer_off(67)
timer_on(68)
	index = . // conserve memory
	assert(st_nobs() == rows(reshaped))
timer_off(68)
timer_on(69)
	vartypes = vartypes, "byte"
	varnames = varnames, generate
	val = setbreakintr(0)
	st_store(., st_addvar(vartypes, varnames, 1), reshaped)
	reshaped = . // conserve memory
	(void) setbreakintr(val)
timer_off(69)
	// Ensure that the keys are unique in master
	if (uniquemaster) {
		F.keep_obs(N + 1 :: st_nobs())
		assert_is_id(F, master_keys, "master")
	}
timer_on(70)
	// Add using-only data
	// status_using = 1 (assert not) 2 (drop it) 3 (keep it)
	if (keep_using | assert_not_using) {
		mask = (F.counts[F.levels[| 1 \ N |]] :== 1)
		has_using = any(mask)

		if (assert_not_using & has_using) {
			_error("merge found observations from using")
		}

		if (keep_using & has_using) {
			data = select( (pk, data) , mask)
			data[., cols(data)] = J(rows(data), 1, 2) // _merge==1
			range = st_nobs() + 1 :: st_nobs() + rows(data)
			st_addobs(rows(data))
			varnames = fk_names, varnames
			st_store(range, varnames, data)
		}
		
	}

	timer_off(70)
timer_off(50)
}


`Boolean' is_integers_only(`String' vars)
{
	`Boolean'				integers_only
	`Integer'				i
	`String'				type
	for (i = integers_only = 1; i <= cols(vars); i++) {
		type = st_vartype(vars[i])
		if (!anyof(("byte", "int", "long"), type)) {
			integers_only = 0
			break
		}
	}
	return(integers_only)
}


void assert_is_id(`Factor' F, `String' keys, `String' dta)
{
	`String'				msg
	msg = sprintf("<%s> do not uniquely identify observations in the %s data ", keys, dta)
	if (!F.is_id()) {
		_error(msg)
	}
}

end


exit
