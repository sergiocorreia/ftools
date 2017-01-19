*! version 1.9.0 10jan2017
* This file is just used to compile ftools.mlib

program define ftools
	syntax, [*]

	if ("`options'" == "") loc options "check"

	if inlist("`options'", "check", "compile") {
		if ("`options'"=="compile") loc force "force"
		ms_get_version ftools // from moresyntax package; save local package_version
		loc functions "Factor*() factor*() _factor*() __fload_data() __fstore_data() ftools*() __factor*() assert_msg()" // 
		// loc functions "*()"
		ms_compile_mata, package(ftools) version(`package_version') `force' fun("`functions'") verbose // debug
	}
	else {
		di as error "Wrong option for ftools: `options'"
		assert 123
	}
end
