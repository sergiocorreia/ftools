* TODO: create a proper test

cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile

pr drop _all
clear all
cls

sysuse auto

tab turn

mata:

void foo()
{
	class Factor colvector Fs
	real colvector idx
	Fs = Factor(3)

	Fs[1] = factor("turn")
	idx = Fs[1].drop_singletons()
	if (idx == J(0, 1, .)) return
	st_nobs()
	st_dropobsin(idx)
	st_nobs()
	
	Fs[2] = factor("trunk")
	idx = Fs[1].drop_singletons()
	if (idx == J(0, 1, .)) return
	st_nobs()
	st_dropobsin(idx)
	st_nobs()
	// here I need to update F1

	Fs[3] = factor("foreign")
	idx = Fs[1].drop_singletons()
	if (idx == J(0, 1, .)) return
	st_nobs()
	st_dropobsin(idx)
	st_nobs()
	// here I need to upate F1, F2
	
	// @ F1
	// here I need to update F2 F3
	
	// RULE:
	// for j=1/num_factors
	// if no the same as the one in drop_singletons() *AND*
	// ... if j < i ...
	// 	Fs[i].drop_obs(idx)
}

end

mata: foo()

gen index = _n
bys turn: gen N = _N
sort index
li if N == 1
