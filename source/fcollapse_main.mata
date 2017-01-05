// FCOLLAPSE - Main routine
mata:
mata set matastrict on

void f_collapse(`Factor' F,
                `Dict' fun_dict,
                `Dict' query,
                `String' vars,
                `Integer' pool,
              | `Varname' wvar,
                `String' wtype)
{
	`Integer'			num_vars, num_targets, num_obs, niceness
	`Integer'			i, i_next, j, i_cstore, j_cstore, i_target
	`Real'				q
	`StringRowVector'	var_formats, var_types
	`StringRowVector'	targets, target_labels, target_types, target_formats
	`RowVector'			var_is_str, target_is_str
	`String'			var
	`Vector'			weights
	`Dict'				data_cstore, results_cstore
	`Dict'				var_positions // varname -> (column, start)
	`RowVector'			var_pos
	`Vector'			box
	`StringMatrix'		target_stat
	`String'			target, stat
	`DataCol'			data
	`Boolean'			merge
	pointer(`DataCol')	scalar fp

	// Variable information
	vars = tokens(vars)
	assert(cols(vars) == cols(asarray_keys(query)'))
	num_vars = length(vars)
	var_formats = var_types = J(1, num_vars, "")
	var_is_str = J(1, num_vars, .)
	num_targets = 0
	for (i = 1; i <= num_vars; i++) {
		var = vars[i]
		var_formats[i] = st_varformat(var)
		var_types[i] = st_vartype(var)
		var_is_str[i] = st_isstrvar(var)
		num_targets = num_targets + rows(asarray(query, var))
	}

	// Compute permutation vector so we can sort the data
	F.panelsetup()
	merge = (F.touse != .)
	if (!merge) {
		F.levels = . // save memory
	}

	// Weights (not really implemented!)
	if (wvar != "") {
		weights = F.sort(st_data(., wvar))
	}
	else {
		weights = J(0, 1, .) // empty colvector
	}

	// Load variables
	niceness = st_numscalar("c(niceness)") // requires stata 13+
	if (length(niceness) == 0) niceness = .
	stata("cap set niceness 10") // requires stata 13+
	data_cstore = asarray_create("real", 1)
	var_positions = asarray_create("string", 1)
	num_obs = st_nobs()

	// i, i_next, j -> index variables
	// i_cstore -> index vectors in the cstore
	i_next = . // to avoid warning

	for (i = i_cstore = 1; i <= num_vars; i = i_next + 1) {
		i_next = min((i + pool - 1, num_vars))
		for (j = i; j <= i_next; j++) {
			if (var_is_str[j] != var_is_str[i]) {
				i_next = j - 1
				break
			}
		}
		
		// Load data
		if (var_is_str[i]) {
			asarray(data_cstore, i_cstore, st_sdata(., vars[i..i_next], F.touse))
		}
		else {
			asarray(data_cstore, i_cstore, st_data(., vars[i..i_next], F.touse))
		}

		// Keep pending vars
		if (!merge) {
			if (i_next == num_vars) {
				stata("clear")
			}
			else {
				st_keepvar(vars[i_next+1..num_vars])
			}
		}

		// Store collated and vectorized data
		// cstore[i_cstore] = vec(sort(cstore[i_cstore]))
		asarray(data_cstore, i_cstore, 
		        vec(F.sort(asarray(data_cstore, i_cstore))))

		// Store the position of each variable in the cstore
		for (j = i; j <= i_next; j++) {
			var = vars[j]
			j_cstore = 1 + (j - i) * num_obs
			var_pos = (i_cstore, j_cstore)
			asarray(var_positions, var, var_pos)
		}
		i_cstore++
	}

	results_cstore = asarray_create("string", 1)
	targets = target_labels = target_types = target_formats = J(1, num_targets, "")
	target_is_str = J(1, num_targets, .)

	// Apply aggregations
	for (i = i_target = 1; i <= num_vars; i++) {
		var = vars[i]
		target_stat = asarray(query, var)
		var_pos = asarray(var_positions, var)

		for (j = 1; j <= rows(target_stat); j++) {
			target = target_stat[j, 1]
			stat = target_stat[j, 2]
			fp = asarray(fun_dict, stat)
			targets[i_target] =  target
			target_labels[i_target] = sprintf("(%s) %s", stat, var)
			target_types[i_target] = infer_type(var_types[i], var_is_str[i], stat)
			target_formats[i_target] = stat=="count" ? "%8.0g" : var_formats[i]
			target_is_str[i_target] = var_is_str[i]
			
			i_cstore = var_pos[1]
			j_cstore = var_pos[2]
			box = j_cstore \ j_cstore + num_obs - 1
			data = asarray(data_cstore, i_cstore)[|box|]
			if (stat == "median") {
				stat = "p50"
			}
			if (regexm(stat, "^p[0-9]+$")) {
				q = strtoreal(substr(stat, 2, .)) / 100
				fp = asarray(fun_dict, "quantile")
				asarray(results_cstore, target, (*fp)(F, data, weights, q))
			}
			else {
				asarray(results_cstore, target, (*fp)(F, data, weights))
			}
			++i_target
		} 
		// Clear vector if done with it
		if (box[2] == rows(asarray(data_cstore, i_cstore))) {
			asarray(data_cstore, i_cstore, .)
		}
	}

	// Store results
	if (!merge) {
		F.store_keys(1) // sort=1 will 'sort' by keys (faster now than later)
	}

	for (i = 1; i <= length(targets); i++) {
		target = targets[i]
		data = asarray(results_cstore, target)
		if (merge) {
			data = rows(data) == 1 ? data[F.levels, .] : data[F.levels]
		}

		if (target_is_str[i]) {
			st_sstore(., st_addvar(target_types[i], target, 1), F.touse, data)
		}
		else {
			st_store(., st_addvar(target_types[i], target, 1), F.touse, data)
		}
		asarray(results_cstore, target, .)
	}

	// Label and format vars
	for (i = 1; i <= cols(targets); i++) {
		st_varlabel(targets[i], target_labels[i])
		st_varformat(targets[i], target_formats[i])
	}
	stata(sprintf("cap set niceness %s", strofreal(niceness)))
}


// Infer type required for new variables after collapse
`String' infer_type(`String' var_type, `Boolean' var_is_str, `String' stat)
{
	`String' 					ans
	`StringRowVector' 			fixed_stats

	fixed_stats = ("min", "max", "first", "last", "firstnm", "lastnm")

	if ( var_is_str | any(fixed_stats :== stat) ) {
		ans = var_type
	}
	else if (stat == "count") {
		ans = "long"
	}
	else {
		ans = "double"
	}
	return(ans)
}

end
