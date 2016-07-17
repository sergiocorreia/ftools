// This file is just used to compile ftools.mlib

cap pr drop ftools
pr ftools
	args flavor

	* Check if we need to rerun
	if ("`flavor'" == "check") {
		mata: st_local("needs_compile", strofreal(ftools_needs_compile()))
		assert inlist(`needs_compile', 0, 1)
		if (!`needs_compile') exit
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

	if ("`flavor'" == "dummy") {
		di as text "(compiling fake lftools.mlib)"
		// assert `version' < 12
		qui findfile "ftools_dummy.mata"
		loc fn "`r(fn)'"
		run "`fn'"
		qui mata: mata mlib create lftools  , dir(.) replace
		qui mata: mata mlib add lftools *() , dir(.) complete
		mata: mata describe using lftools
	}
	else {
		di as text "(compiling lftools.mlib for Stata `version')"
		qui findfile "ftools.mata"
		loc fn "`r(fn)'"
		run "`fn'"
		loc path = c(sysdir_plus) + c(dirsep) + "l"
		qui mata: mata mlib create lftools  , dir("`path'") replace
		qui mata: mata mlib add lftools *() , dir("`path'") complete
		// mata: mata describe using lftools
	}

	* Verify
	qui findfile lftools.mlib
	loc fn `r(fn)'
	//mata: mata describe using lftools
	qui mata: mata mlib index
	di as text `"(library saved in `fn')"'
end
