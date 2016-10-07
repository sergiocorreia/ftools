
// -------------------------
// Programs

cap pr drop crData
pr crData
	args n k
	clear
	qui set obs `n'
	noi di "(obs set)"
	loc m = ceil(`n' / 10)
	//set seed 234238921
	*gen long x1 = ceil(uniform()*`m')
	gen long x1 = ceil(uniform()*10000) * 100

	gen int x2 = ceil(uniform()*3000)
	gen byte x3 = ceil(uniform()*100)
	gen str x4 = "u" + string(ceil(uniform()*100), "%5.0f")
	gen long x5 = ceil(uniform()*5000)
	// compress
	noi di "(Xs set)"

	forv i=1/`k' {
		gen double y`i' = 123.456
	}

	loc obs_k = ceil(`c(N)' / 1000)
end

cap pr drop FactorsAgree
pr FactorsAgree, sortpreserve
	args id1 id2
	tempvar ok
	
	bys `id1' (`id2'): gen byte `ok' = `id2'[1] == `id2'[_N]
	assert `ok' == 1
	drop `ok'
	
	bys `id2' (`id1'): gen byte `ok' = `id1'[1] == `id1'[_N]
	assert `ok' == 1
	drop `ok'
end

cap pr drop ValidateFactor
pr ValidateFactor
	syntax varlist [in] [if], [factor(string) method(string)]
	preserve
	di as smcl "{txt}{bf:[OPTIONS]} {res}`0'"
	if ("`factor'" == "") {
		loc factor F
	}
	if ("`in'`if'" != "") {
		marksample touse
		cou if `touse'
		loc num_obs = r(N)
	}
	else {
		loc num_obs = c(N)
	}
	// factor(varlist, touse, verbose, method, sort_levels, count_levels, hash_ratio)
	loc cmd mata: `factor' = factor("`varlist'", "`touse'", 1, "`method'")
	di as res `"          `cmd'"'
	`cmd'
	loc cmd mata: `factor'.store_levels("new_id")
	di as res `"          `cmd'"'
	`cmd'
	loc cmd mata: `factor'.panelsetup()
	di as res `"          `cmd'"'
	`cmd'

	di as smcl "{txt}{bf:[TESTING] }" _c

	// Output:
	// num_levels num_obs touse varlist
	// levels keys counts info p
	di as res "F.num_obs " _c
	mata: assert(`factor'.num_obs == `num_obs')
	egen long benchmark_id = group(`varlist')
	di as res "F.levels " _c
	assert benchmark_id == new_id
	
	gen long i = _n
	sort benchmark_id, stable
	mata: benchmark_id = st_data(., "benchmark_id")
	sort i
	drop i

	gen byte counts = 1
	collapse (first) `varlist' (count) counts , by(benchmark_id)
	di as res "F.num_levels " _c
	loc num_levels = c(N)
	mata: assert(`factor'.num_levels == `num_levels')
	di as res "F.touse " _c
	mata: assert(`factor'.touse == "`touse'")
	di as res "F.varlist " _c
	mata: assert(`factor'.varlist == tokens("`varlist'"))
	di as res "F.keys " _c
	mata: benchmark_keys = __fload_data("`varlist'")
	mata: assert(benchmark_keys == `factor'.keys)
	di as res "F.counts " _c
	mata: benchmark_counts = st_data(., "counts")
	mata: assert(benchmark_counts == `factor'.counts)
	di as res "F.offsets "
	sort benchmark_id
	mata: assert(panelsetup(benchmark_id, 1) == `factor'.info)

	// note: order is not a stable sort so we also sort by _n
	mata: assert(`factor'.p == order((`factor'.levels, (1::`factor'.num_obs)), 1..2) )

	// same for offsets, p
	mata: mata drop `factor'
	di as smcl "{txt}{bf:[OK]}"
end
