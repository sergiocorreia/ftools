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
		[UNIQUEmaster] /// Assert that -by- is an id in the master dataset
		[NOLabel] ///
		[NONOTES]

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
	
	loc uniquemaster = ("`uniquemaster'" != "")
	loc nolabel = ("`nolabel'" != "")
	loc nonotes = ("`nonotes'" != "")

	* Parse key variables
	ParseBy `by' /// Return -master_keys- and -using_keys-

	// it should be _all EXCEPT by
	// if ("`namelist'" == "") loc namelist "_all"

	macro list
end


cap pr drop ParseUsing
program define ParseUsing
	* SAMPLE INPUT: somefile.dta if foreign==true
	gettoken filename if : 0,
	c_local filename `filename'
	c_local if `if'
end


cap pr drop ParseBy
program define ParseBy
	* SAMPLE INPUT: turn trunk
	* SAMPLE INPUT: year=time country=cou
	while ("`0'" != "") {
		gettoken right 0 : 0
		gettoken left right : right
		if ("`right'" != "") {
			loc eqsign right : right, parse("=")
			assert "`eqsign'" == "="
		}
		else {
			loc right `left'
		}
		loc master_keys `master_keys' `left'
		loc using_keys `using_keys' `right'
	}
	c_local `master_keys'
	c_local `using_keys'
end
