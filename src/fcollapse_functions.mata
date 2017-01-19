// FCOLLAPSE - Aggregate Functions


// panelsum() is an undocumented Mata function introduced in Stata 13
// Since most of the time is not spent here, we don't save much by using it

//if (c(stata_version) < 13) {
//	loc panelsum
//}
//else{
//	loc panelsum "return(length(weights) ? panelsum(data, weights, F.info) : panelsum(data, F.info))"
//}

// I disabled this for now because panelsum() is missing when all obs are missing (instead of being zero like with collapse)


mata:
mata set matastrict on

`Dict' get_funs()
{
	`Dict'					funs
	funs = asarray_create("string", 1)
	asarray_notfound(funs, NULL)
	asarray(funs, "count", &aggregate_count())
	asarray(funs, "mean", &aggregate_mean())
	asarray(funs, "sum", &aggregate_sum())
	asarray(funs, "min", &aggregate_min())
	asarray(funs, "max", &aggregate_max())
	asarray(funs, "first", &aggregate_first())
	asarray(funs, "last", &aggregate_last())
	asarray(funs, "firstnm", &aggregate_firstnm())
	asarray(funs, "lastnm", &aggregate_lastnm())
	asarray(funs, "percent", &aggregate_percent())
	asarray(funs, "quantile", &aggregate_quantile())
	asarray(funs, "iqr", &aggregate_iqr())
	asarray(funs, "sd", &aggregate_sd())
	// ...
	return(funs)
}

`Matrix' select_nm_num(`Vector' data) {
	// Return matrix in case the answer is 0x0
	return(select(data, data :< .))
}

`StringMatrix' select_nm_str(`StringVector' data) {
	return(select(data, data :!= ""))
}

`DataCol' aggregate_count(`Factor' F, `DataCol' data, `Vector' weights)
{
	`Integer'	            i
	`DataCol'	            results
	results = J(F.num_levels, 1, missingof(data))
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = nonmissing(panelsubmatrix(data, i, F.info))
	}
	return(results)
}

`Vector' aggregate_mean(`Factor' F, `Vector' data, `Vector' weights)
{
	`Integer'	            i
	`Vector'	            results
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = mean(panelsubmatrix(data, i, F.info))
	}
	return(results)
}

`Vector' aggregate_sum(`Factor' F, `Vector' data, `Vector' weights)
{
	`panelsum' // Hack
	`Integer'	            i
	`Vector'	            results
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = quadsum(panelsubmatrix(data, i, F.info))
	}
	return(results)
}

`Vector' aggregate_min(`Factor' F, `Vector' data, `Vector' weights)
{
	`Integer'	            i
	`Vector'	            results
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = min(panelsubmatrix(data, i, F.info))
	}
	return(results)
}

`Vector' aggregate_max(`Factor' F, `Vector' data, `Vector' weights)
{
	`Integer'	            i
	`Vector'	            results
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = max(panelsubmatrix(data, i, F.info))
	}
	return(results)
}

`DataCol' aggregate_first(`Factor' F, `DataCol' data, `Vector' weights)
{
	`Integer'	            i
	`DataCol'	            results
	results = J(F.num_levels, 1, missingof(data))
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = data[F.info[i, 1]]
	}
	return(results)
}

`DataCol' aggregate_last(`Factor' F, `DataCol' data, `Vector' weights)
{
	`Integer'	            i
	`DataCol'	            results
	results = J(F.num_levels, 1, missingof(data))
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = data[F.info[i, 2]]
	}
	return(results)
}

`DataCol' aggregate_firstnm(`Factor' F, `DataCol' data, `Vector' weights)
{
	`Integer'	            i
	`DataCol'	            results, tmp
	pointer(`Vector')		fp
	results = J(F.num_levels, 1, missingof(data))
	fp = isstring(data) ? &select_nm_str() : &select_nm_num()
	for (i = 1; i <= F.num_levels; i++) {
		tmp = (*fp)(panelsubmatrix(data, i, F.info))
		if (rows(tmp) == 0) continue
        results[i] = tmp[1]
	}
	return(results)
}

`DataCol' aggregate_lastnm(`Factor' F, `DataCol' data, `Vector' weights)
{
	`Integer'	            i
	`DataCol'	            results, tmp
	pointer(`Vector')		fp
	results = J(F.num_levels, 1, missingof(data))
	fp = isstring(data) ? &select_nm_str() : &select_nm_num()
	for (i = 1; i <= F.num_levels; i++) {
		tmp = (*fp)(panelsubmatrix(data, i, F.info))
		if (rows(tmp) == 0) continue
        results[i] = tmp[rows(tmp)]
	}
	return(results)
}

`Vector' aggregate_percent(`Factor' F, `DataCol' data, `Vector' weights)
{
	`Vector'	            results
	results = aggregate_count(F, data, weights)
	return(results :/ (quadsum(results) / 100))
}

`Vector' aggregate_quantile(`Factor' F, `Vector' data, `Vector' weights,
                            `Integer' P)
{
	`Integer'	            i
	`Vector'	            results, tmp
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
        // SYNTAX: _mm_quantile(data, weights, quantiles, altdef)
        // SYNTAX: mm_quantile(data, | w, P, altdef)
        tmp = select_nm_num(panelsubmatrix(data, i, F.info))
        if (rows(tmp) == 0) continue
        results[i] = _mm_quantile(tmp, 1, P, 0)
	}
	return(results)
}

`Vector' aggregate_iqr(`Factor' F, `Vector' data, `Vector' weights)
{
	`Integer'	            i
	`Vector'	            results
	`RowVector'				tmp1, tmp2
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
		tmp1 = select_nm_num(panelsubmatrix(data, i, F.info))
		if (rows(tmp1) == 1) results[i] = 0
		if (rows(tmp1) <=1 ) continue
    	tmp2 = _mm_quantile(tmp1, 1, (0.25\0.75), 0)
        results[i] = tmp2[2] - tmp2[1]
	}
	return(results)
}

`Vector' aggregate_sd(`Factor' F, `Vector' data, `Vector' weights)
{
	`Integer'	            i
	`Vector'	            results
	results = J(F.num_levels, 1, .)
	for (i = 1; i <= F.num_levels; i++) {
        results[i] = sqrt(quadvariance(panelsubmatrix(data, i, F.info)))
	}
	return(results)
}
end
