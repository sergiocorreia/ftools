*! version 2.30.3 02aug2018
* This file is just used to compile ftools.mlib

program define ftools
	syntax, [*]

	if ("`options'" == "") loc options "check"

	if inlist("`options'", "check", "compile") {
		if ("`options'"=="compile") loc force "force"
		ms_get_version ftools // included in this package
		// maybe just add all fns explicitly?
		loc functions Factor*() factor*() _factor*() join_factors() ///
					  __fload_data() __fstore_data() ftools*() __factor*() ///
					  assert_msg() assert_in() assert_boolean() /// bin_order()
					  aggregate_*() select_nm_*() rowproduct() ///
					  create_mask() update_mask()
		ms_compile_mata, package(ftools) version(`package_version') `force' fun(`functions') verbose // debug
	}
	else if "`options'"=="version" {
		which ftools
		di as text _n "Required packages installed?"
		loc reqs moremata
		if (c(version)<13) loc reqs `reqs' boottest
		foreach req of local reqs {
			loc fn `req'.ado
			if ("`req'"=="moremata") loc fn `req'.hlp
			cap findfile `fn'
			if (_rc) {
				di as text "{lalign 20:- `req'}" as error "not" _c
				di as text "    {stata ssc install `req':install from SSC}"
			}
			else {
				di as text "{lalign 20:- `req'}" as text "yes"
			}
		}
	}
	else {
		di as error "Wrong option for ftools: `options'"
		assert 123
	}
end
