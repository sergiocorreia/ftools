clear all
cls
set more off

* Fake -using- dataset
set obs 5
gen byte foreign = _n - 1
gsort -foreign
gen x = rnormal()
gen y = 100 * foreign
tempfile using_dta
save "`using_dta'"

sysuse auto
set obs `=c(N)+1'
replace foreign = 9 in `c(N)'

* START

loc key "foreign"
loc varlist "x y"

preserve

use "`using_dta'", clear

mata:
	F = factor("`key'")
	keysize = F.num_levels
	data = st_data(., "`varlist'")
end

restore

mata:
	fk = F.keys \ st_data(., "`key'")
	F = _factor(fk)
	// WE CAN USE F.counts for levels up to numkeys to report those only in using
	// create levels = F.levels but TRUNCATED from numkeys+1
	// create mask = levels :<= numkeys
	// replace levels = F.levels :- numkeys
	// what about those only in master?

	// answer = data[levels]
	// st_store(obs, "`varlist'", mask, answer)
end

