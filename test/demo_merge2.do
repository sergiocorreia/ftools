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

cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile
discard

clear all
cls
set more off

set seed 435435

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


loc keys "key"
loc varlist "x y"


* Benchmark
preserve
merge m:1 `keys' using "`using'" , keepusing("`varlist'")
sort index
mata: benchmark = st_data(., .)
mata: hash1(benchmark)
restore

* FMERGE

preserve
use `keys' `varlist' using `"`using'"' , clear // if ..

mata:
	keynames = tokens("`keys'")
	pk = st_data(., keynames)
	N = rows(pk)
	
	// Assert keys are unique IDs in using
	F = _factor(pk)
	assert(all(F.counts :== 1))

	varnames = tokens("`varlist'")
	vartypes = J(1, cols(varnames), "")
	for (i=1; i<=cols(varnames); i++) {
		vartypes[i] = st_vartype(varnames[i])
	}

	data = st_data(., "`varlist'") , J(st_nobs(), 1, 3)
end:

restore

mata:
	F = _factor(pk \ st_data(., keynames))
	index = F.levels[| 1 \ N |]
	reshaped = J(F.num_levels, cols(data)-1, .) , J(F.num_levels, 1, 1)
	reshaped[index, .] = data
	
	
	index = F.levels[| N+1 \ . |]
	reshaped = reshaped[index , .]
	rows(reshaped), st_nobs()
	assert(st_nobs() == rows(reshaped))


	reshaped = reshaped
	vartypes = vartypes, "byte"
	varnames = varnames, "_merge"

	val = setbreakintr(0)
	st_store(., st_addvar(vartypes, varnames, 1), reshaped)
	(void) setbreakintr(val)

	// Add using-only data
	data = select( (pk, data) , F.counts[F.levels[| 1 \ N |]] :== 1)
	data[., cols(data)] = J(rows(data), 1, 2)
	range = st_nobs() + 1 :: st_nobs() + rows(data)
	st_addobs(rows(data))
	varnames = keynames, varnames
	st_store(range, varnames, data)
	fmerge = st_data(., .)
	hash1(fmerge), 	hash1(benchmark)

	// by default, we dont sort it and instead just attach using at the end
	// NOTE: SORT IS TOO HARD< LEAVE IT AS IT IS
	// it sorts 1+3 and then it sorts 2 at the end by itself


	// TODO with randomized datasets, ensure that fmerge+sort=merge
	// and same for fmerge,sort (same time)


	// TLDR: we got a clean option to add using.. we can drop if merge is 1
	// and we can change the name of merge and so on

	// optimize to remove merge if not asked? would imply we dont have assert or keep... which is very unlikely, so NO (!)

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

