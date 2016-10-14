cap pr drop join
program define join

// Parse --------------------------------------------------------------------

	syntax ///
		[namelist]  /// Variables that will be added (default is _all)
		, ///
		[from(string asis) into(string asis)] /// -using- dataset
		[by(string)] /// Primary and foreign keys
		[KEEP(string)] /// 1 master 2 using 3 match
		[ASSERT(string)] /// 1 master 2 using 3 match
		[GENerate(name) NOGENerate] /// _merge variable
		[UNIQuemaster] /// Assert that -by- is an id in the master dataset
		[noLabel] ///
		[noNOTES] ///
		[noREPort] ///
		[Verbose]

	* Parse details of using dataset
	_assert (`"`from'"' != "") + (`"`into'"' != "") == 1, ///
		msg("specify either from() or into()")
	ParseUsing `from' `into' // Return -filename- and -if-
	
	* Parse _merge indicator
	_assert ("`generate'" != "") + ("`nogenerate'" != "") < 2, ///
		msg("generate() and nogenerate are mutually exclusive")
	if ("`nogenerate'" == "") {
		if ("`generate'" == "") loc generate _merge
		confirm new variable `generate'
	}
	else {
		tempvar generate
	}
	
	* Parse booleans
	loc is_from = (`"`from'"' != "")
	loc uniquemaster = ("`uniquemaster'" != "")
	loc nolabel = ("`label'" != "")
	loc nonotes = ("`notes'" != "")
	loc noreport = ("`report'" != "")
	loc verbose = ("`verbose'" != "")

	* Parse keep() and assert() requirements
	ParseMerge, keep(`keep') assert(`assert')
	/* Return locals
		keep_using: 1 if we will keep using-only obs
		assert_not_using: 1 to check that there are no using-only obs.
		keep_nums: {1, 3, 1 3} depending on whether we keep master/match
		assert_nums: as above but to assert only these exist (besides using)
		keep_words assert_words: as above but with words instead of nums
	*/ 

	* Parse -key- variables
	ParseBy `by' /// Return -master_keys- and -using_keys-


// Load using  dataset -------------------------------------------------------

	* Load -using- dataset
	if (`is_from') {
		preserve
		use "`filename'", clear
		if ("`if'" != "") qui keep `if'
		loc cmd restore
	}
	else {
		loc cmd `"qui use `if' using "`filename'", clear"'
	}

	if ("`namelist'" != "") {
		keep `using_keys' `namelist'
	}
	else {
		qui ds `using_keys', not
		loc namelist `r(varlist)'
	}
	unab namelist : `namelist', name(keepusing) min(0)
	unab using_keys : `using_keys'
	confirm variable `using_keys', exact


// Join ---------------------------------------------------------------------

	mata: join("`using_keys'", "`master_keys'", "`namelist'", ///
	    `"`cmd'"', "`generate'", `uniquemaster', ///
	    `keep_using', `assert_not_using', ///
	    `nolabel', `nonotes', ///
	    `verbose')


// Apply requirements on _merge variable ------------------------------------

	la def _merge ///
		1 "master only (1)" 2 "using only (2)" 3 "matched (3)" /// Used
		4 "missing updated (4)" 5 "nonmissing conflict (5)" // Unused
	la val `generate' _merge

	loc msg "merge:  after merge, not all observations from `assert_words'"
	if ("`assert_nums'" == "") _assert !inlist(`generate', 1, 3), msg("`msg'")
	if ("`assert_nums'" == "1") _assert !inlist(`generate', 3), msg("`msg'")
	if ("`assert_nums'" == "3") _assert !inlist(`generate', 1), msg("`msg'")

	if ("`keep_nums'" == "") qui drop if inlist(`generate', 1, 3)
	if ("`keep_nums'" == "1") qui drop if inlist(`generate', 3)
	if ("`keep_nums'" == "3") qui drop if inlist(`generate', 1)

	if (`noreport') {
		Table `generate'
	}
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

	loc match_valid `""3", "match", "mat", "matc", "matches", "matched""'

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
			else if (inlist("`word'", `match_valid')) {
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
	c_local keep_using `keep_using'
	c_local assert_not_using `assert_not_using'	
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
	* Mata functions such as st_vartype() don't play well with abbreviations
	unab master_keys : `master_keys'
	unab using_keys : `using_keys'
	c_local master_keys `master_keys'
	c_local using_keys `using_keys'
end


cap pr drop Table
program define Table
	syntax varname

	* Initialize defaults
	loc N 0
	forval i = 1/3 {
		loc m`i' 0
	}
	
	if (c(N)) {
		tempname freqs values
		tab `varlist', nolabel nofreq matcell(`freqs') matrow(`values')
		loc N = rowsof(`freqs')
		loc is_temp = substr("`varlist'", 1, 2) == "__"
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
          `Boolean' assert_not_using,
          `Boolean' nolabel,
          `Boolean' nonotes,
          `Boolean' verbose)
{
	`Varlist'				pk_names, fk_names, varnames, vartypes, varformats
	`Variables'				pk
	`Integer'				N, i, val, j, k
	`Factor'				F
	`DataFrame'				data, reshaped
	`Vector'				index, range, mask
	
	`Boolean'				integers_only
	`Boolean'				has_using
	`Varname'				var
	`String'				msg

	`StringVector'			varlabels, varvaluelabels
	`Dict'					label_values, label_text
	`Vector'				values
	`StringVector'			text
	`String'				label

	`Integer'				num_chars
	`StringMatrix'			chars
	`StringVector'			charnames
	`String'				char_name, char_val


	// Using
	pk_names = tokens(using_keys)
	fk_names = tokens(master_keys)
	pk = st_data(., pk_names)
	N = rows(pk)
	// Assert keys are unique IDs in using

	integers_only = is_integers_only(pk_names)
	F = _factor(pk, integers_only, verbose, "", 0)
	assert_is_id(F, using_keys, "using")

	varnames = tokens(varlist)
	vartypes = J(1, cols(varnames), "")
	varlabels = J(1, cols(varnames), "")
	varvaluelabels = J(1, cols(varnames), "")
	label_values = asarray_create("string", 1)
	label_text = asarray_create("string", 1)
	text = ""
	values = .

	num_chars = rows(st_dir("char", "_dta", "*"))

	msg = "{err}merge:  string variables are not allowed (%s)\n"
	for (i=1; i<=cols(varnames); i++) {
		var = varnames[i]

		// Assert vars are not strings (could allow for it, but not useful)
		if (st_isstrvar(var)) {
			printf(msg, var)
			exit(110)
		}

		vartypes[i] = st_vartype(var)
		varformats[i] = st_varformat(var)

		// Add variable labels, value labels, and assignments
		varlabels[i] = st_varlabel(var)
		varvaluelabels[i] = label = st_varvaluelabel(var)

		if (label != "" ? st_vlexists(label) : 0) {
			st_vlload(label, values, text)
			asarray(label_values, label, values)
			asarray(label_text, label, text)
		}

		num_chars = num_chars + rows(st_dir("char", var, "*"))
	}

	// Save chars
	// Note: we are NOT saving chars (or labels) from the by() variables!
	chars = J(num_chars, 3, "")
	j = 0
	for (k=0; k<=cols(varnames); k++) {
		var = k ? varnames[k] : "_dta"
		charnames = st_dir("char", var, "*")
		for (i=1 ; i<=rows(charnames); i++) {
			++j
			chars[j, 1] = var
			chars[j, 2] = charnames[i]
			chars[j, 3] = st_global(sprintf("%s[%s]", var, charnames[i]))
		}
	}


	if (cols(varnames) > 0) {
		data = st_data(., varnames) , J(st_nobs(), 1, 3) // _merge==3
	}
	else {
		data = J(st_nobs(), 1, 3) // _merge==3
	}

	// Master
	stata(cmd) // load (either -restore- or -use-)

	// Check that variables don't exist yet
	msg = "{err}merge:  variable %s already exists in master dataset\n"
	for (i=1; i<=cols(varnames); i++) {
		var = varnames[i]
		if (_st_varindex(var) != .) {
			printf(msg, var)
			exit(108)
		}
	}
	
	integers_only = integers_only & is_integers_only(fk_names)
	if (verbose) {
		printf("{txt}(integers only? {res}%s{txt})\n", verbose ? "true" : "false")
	}
	F = _factor(pk \ st_data(., fk_names), integers_only, verbose, "", 0)

	index = F.levels[| 1 \ N |]
	reshaped = J(F.num_levels, cols(data)-1, .) , J(F.num_levels, 1, 1) // _merge==1
	reshaped[index, .] = data
	index = F.levels[| N+1 \ . |]
	reshaped = reshaped[index , .]
	index = . // conserve memory
	assert(st_nobs() == rows(reshaped))
	vartypes = vartypes, "byte"
	varnames = varnames, generate
	val = setbreakintr(0)
	st_store(., st_addvar(vartypes, varnames, 1), reshaped)
	reshaped = . // conserve memory
	(void) setbreakintr(val)

	// Ensure that the keys are unique in master
	if (uniquemaster) {
		F.keep_obs(N + 1 :: st_nobs())
		assert_is_id(F, master_keys, "master")
	}

	// Add labels
	msg = "{err}(warning: value label %s already exists; values overwritten)"
	for (i=cols(fk_names)+1; i<=cols(varnames)-1; i++) {
		var = varnames[i]

		// label variable <var> <text>
		if (varlabels[i] != "") {
			st_varlabel(var, varlabels[i])
		}
		varformats[i]
		//st_varformat(var, varformats[i])

		label = varvaluelabels[i]
		if (label != "") {

			// Warn if value label gets overwritten
			if (st_vlexists(label)) {
				printf(msg, label)
			}
			// label define <label> <#> <text> <...>
			st_vlmodify(label, 
			            asarray(label_values, label),
			            asarray(label_text, label))
			// label values <varlist> <label>
			st_varvaluelabel(var, label)
		}
	}

	// Add chars and notes
	for (i=1; i<=num_chars; i++) {
		var = chars[i, 1]
		char_name = chars[i, 2]
		char_val = chars[i, 3]
		if (char_name == "note0") {
			continue
		}
		else if (strpos(char_name, "note")==1) {
			stata(sprintf("note %s: %s", var, char_val))
		}
		else {
			st_global(sprintf("%s[%s]", var, char_name), char_val)
		}
	}

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
}


`Boolean' is_integers_only(`Varlist' vars)
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
	msg = sprintf("<%s> do not uniquely identify obs. in the %s data",
	              keys, dta)
	if (!F.is_id()) {
		_error(msg)
	}
}

end


exit
