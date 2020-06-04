* ===========================================================================
* Prevent regression of bug #29
* ===========================================================================
* https://github.com/sergiocorreia/ftools/issues/29

* ISSUE
* Merging data with keep(.. using ..) needs to check if we need to recast the identifiers

// --------------------------------------------------------------------------
// Setup test data
// --------------------------------------------------------------------------

	clear all
	set obs 3
	gen int id = _n
	replace id = 200 in 3
	gen y = 10 * _n
	li
	tempfile using
	save "`using'"

	clear
	set obs 3
	gen byte id = _n + 1
	gen z = 100 * _n
	li

	de
	fmerge 1:1 id using "`using'"
	li
	de

	_assert !mi(id)
	_assert "`: type id'" == "int"
