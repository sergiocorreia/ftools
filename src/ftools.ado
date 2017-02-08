*! version 2.6.0 08feb2017
* This file is just used to compile ftools.mlib

program define ftools
	syntax, [*]

	if ("`options'" == "") loc options "check"

	if inlist("`options'", "check", "compile") {
		if ("`options'"=="compile") loc force "force"
		ms_get_version ftools // from moresyntax package; save local package_version
		// maybe just add all fns...
		loc functions Factor*() factor*() _factor*() join_factors() ///
					  __fload_data() __fstore_data() ftools*() __factor*() ///
					  bin_order() assert_msg() ///
					  aggregate_*() select_nm_*()
		ms_compile_mata, package(ftools) version(`package_version') `force' fun(`functions') verbose // debug
	}
	else {
		di as error "Wrong option for ftools: `options'"
		assert 123
	}
end
