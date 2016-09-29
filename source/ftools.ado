*! version 1.1.0 29sep2016
* This file is just used to compile ftools.mlib

cap pr drop ftools
pr ftools
	args flavor
	if ("`flavor'" == "") loc flavor check

	* Check if we need to recompile
	if ("`flavor'" == "check") {
		cap mata: mata drop ftools_stata_version()
		loc compiled_with 0
		cap mata: st_local("compiled_with", ftools_stata_version())
		_assert inlist(`c(rc)', 0, 3499), msg("ftools check: unexpected error")
		if (`compiled_with' == c(stata_version)) exit
		* If we reach this point, we need to recompile
		local flavor compile
	}

	loc version = c(stata_version)
	clear mata

	* Delete previous versions; based on David Roodman's -boottest-
	loc mlib "lftools.mlib"
	cap findfile "`mlib'"
	while !_rc {
	        erase "`r(fn)'"
	        cap findfile "`mlib'"
	}

	di as text "(compiling lftools.mlib for Stata `version')"
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
