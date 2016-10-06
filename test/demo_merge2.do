/*

fmerge varlist, from(name if <>) by() keep() assert() nosort

use macro
fmerge xrate, into(prices) by(country year) ///
	keep(master match) nosort

use prices
fmerge xrate, from(macro if currency="usd") by(cou year) ///
	keep(master match) nosort


join xrate from macro if currency=="usd", by(cou year)

join xrate, using("macro" if cur=="usd") by(cou year) keep(1 2) nos


join xrate, using("macro") by(cou year) keep(1 2) nos

merge m:1 cou year using "macro" keepus(xrate) keep(1 2)





fmerge m:1 <key> using <dta> ,
	SORT (we can leave it unsorted, no need to sort back!)
	ASSERT(master using match)
	KEEPOBJECT(F)
	NOGENERATE (_merge) | GENerate(newvar)
	KEEEPUSing(varlist)

m:1 and 1:m can share the same codepath (1:m is faster)
m:m will never happen
1:1 is just like m:1 but F21.counts must be 1 or 2 only (!)
*/

clear all
cls
set more off

* using
set obs 6
gen byte key = _n
drop if inlist(key, 1, 3, 6)
gen x = rnormal()
gen y = 100 * key
gen u = runiform()
sort u
tempfile using
save "`using'"

* Master
clear
set obs 24
gen byte key = ceil(_n/3)
drop if inlist(key, 5)
gen w = 100 * key
gen v = runiform()
sort v
gen index = _n
sort index

* Benchmark
preserve
merge m:1 key using "`using'"
sort index
mata: benchmark = st_data(., .)
mata: hash1(benchmark)
restore

* FMERGE
loc keys "foreign"
loc varlist "x y"

preserve
use `keys' `varlist'' using "`using'", clear
mata:
	

end


exit



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

