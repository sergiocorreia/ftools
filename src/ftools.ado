*! version 2.13.0 22jun2017
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
					  assert_msg() /// bin_order()
					  aggregate_*() select_nm_*() rowproduct()
		ms_compile_mata, package(ftools) version(`package_version') `force' fun(`functions') verbose // debug
	}
	else {
		di as error "Wrong option for ftools: `options'"
		assert 123
	}
end
