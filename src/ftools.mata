// --------------------------------------------------------------------------
// Mata Code: Efficiently compute levels of variables (factors/categories)
// --------------------------------------------------------------------------
// Project URL: https://github.com/sergiocorreia/ftools


// Miscellanea --------------------------------------------------------------
	loc debug 0
	loc debug_on = cond(`debug', "on", "off")
	loc debug_off = cond(`debug', "off", "on")
	
	set matadebug `debug_on'
	mata: mata clear
	mata: mata set matastrict `debug_off'
	mata: mata set mataoptimize on
    mata: mata set matadebug `debug_on'
   	mata: mata set matalnum `debug_on'


// Versioning ---------------------------------------------------------------
	ms_get_version ftools // moresyntax package
	assert("`package_version'" != "")
    mata: string scalar ftools_version() return("`package_version'")
    mata: string scalar ftools_stata_version() return("`c(stata_version)'")
    mata: string scalar ftools_joint_version() return("`package_version'|`c(stata_version)'")


// Includes -----------------------------------------------------------------
	findfile "ftools_type_aliases.mata"
	include "`r(fn)'"

	findfile "ftools_common.mata"
	include "`r(fn)'"

	findfile "ftools_main.mata"
	include "`r(fn)'"

	findfile "ftools_bipartite.mata"
	include "`r(fn)'"

	findfile "fcollapse_functions.mata"
	include "`r(fn)'"



// Possible Improvements
// ----------------------
// 1) Do this in a C plugin; perhaps using khash (MIT-lic) like Pandas
// 2) Use a faster hash function like SpookyHash or CityHash (both MIT-lic)
// 3) Use double hashing instead of linear/quadratic probing
// 4) Compute the hashes in parallel


// Notes:
// ----------------------
// This requires Stata 13+ due to the selectindex() and panelsum() functions
// They *could* be replaced for Stata 12 with:
// - select(1::rows(dict), dict)
// - panelsubmatrix()
// But this comes at a speed + terseness cost (not worth it)
