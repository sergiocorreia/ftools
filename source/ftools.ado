*! version 1.7.0 04jan2017
* This file is just used to compile ftools.mlib

program define ftools
	loc ftools_version = "1.5.0 08oct2016"
	loc stata_version = c(stata_version)

	args flavor
	if ("`flavor'" == "") loc flavor check

	* Check if we need to recompile
	if ("`flavor'" == "check") {
		
		loc mlib_stata_version ???
		cap mata: mata drop ftools_stata_version()
		cap mata: st_local("mlib_stata_version", ftools_stata_version())
		_assert inlist(`c(rc)', 0, 3499), msg("ftools check: unexpected error")
		
		loc mlib_ftools_version ???
		cap mata: mata drop ftools_version()
		cap mata: st_local("mlib_ftools_version", ftools_version())
		_assert inlist(`c(rc)', 0, 3499), msg("ftools check: unexpected error")
		
		loc ok 1
		if ("`mlib_stata_version'" != "`stata_version'") {
			di as text "(existing ftools.mlib compiled with Stata `mlib_stata_version'; need to recompile for Stata `stata_version')"
			loc ok 0
		}
		if ((`ok') & ("`mlib_ftools_version'" != "`ftools_version'")) {
			di as text "(existing ftools.mlib is version `mlib_ftools_version'; need to recompile for `ftools_version')"
			loc ok 0
		}
		if (`ok') exit
		* If we reach this point, we need to recompile
		local flavor compile
	}

	clear mata

	* Delete previous versions; based on David Roodman's -boottest-
	loc mlib "lftools.mlib"
	cap findfile "`mlib'"
	while !_rc {
	        erase "`r(fn)'"
	        cap findfile "`mlib'"
	}

	di as text "(compiling lftools.mlib for Stata `stata_version')"
	qui findfile "ftools.mata"
	loc fn "`r(fn)'"
	run "`fn'"
	loc path = c(sysdir_plus) + "l"
	cap {
		qui mata: mata mlib create lftools  , dir("`path'") replace
		qui mata: mata mlib add lftools *() , dir("`path'") complete
	}
	if (c(rc)) {
		// Exit with error but still save the file somewhere
		di as error `"could not save file in "`path'"; saving it in ".""'
		qui mata: mata mlib create lftools  , dir(.) replace
		qui mata: mata mlib add lftools *() , dir(.) complete
		qui findfile lftools.mlib
		loc fn `r(fn)'
		di as text `"(library saved in `fn')"'
		exit 603
	}

	* Verify
	qui findfile lftools.mlib
	loc fn `r(fn)'
	//mata: mata describe using lftools
	qui mata: mata mlib index
	di as text `"(library saved in `fn')"'
end
