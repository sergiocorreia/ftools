mata:

// Call gtools plugin
`Factor' __factor_gtools(
	`Varlist' vars,
	`String' touse,
	`Boolean' verbose,
	`Boolean' sort_levels,
	`Boolean' count_levels,
	`Boolean' save_keys)
{
	`Factor'				F
	`Integer'				num_vars, num_levels, num_obs
	`String'				levels_var, tag_var, counts_var, cmd, ifcmd
	`Vector'				levels, counts, idx, p
	`Matrix'				keys

	// Options
	if (verbose == .) verbose = 0
	if (sort_levels == .) sort_levels = 1
	if (count_levels == .) count_levels = 1
	if (save_keys == .) save_keys = 1

	assert_msg(count_levels == 0 | count_levels == 1, "count_levels")
	assert_msg(save_keys == 0 | save_keys == 1, "save_keys")

	// Load data, based on output from -gegen group+tag+count
	levels_var = st_tempname()
	tag_var = st_tempname()
	counts_var = st_tempname()
	
	// BUGBUG use fegen temporarily until bugfix with touse!!
	ifcmd = touse == "" ? "" : " if " + touse
	cmd = "gegen long %s = group(%s)%s, missing"
	cmd = sprintf(cmd, levels_var, invtokens(vars), ifcmd)
	if (verbose) printf(cmd + "\n")
	stata(cmd)
	
	cmd = sprintf("gegen byte %s = tag(%s)%s", tag_var, levels_var, ifcmd)
	if (verbose) printf(cmd + "\n")
	stata(cmd)
	
	if (count_levels) {
		cmd = sprintf("gegen long %s = count(1)%s, by(%s)", counts_var, ifcmd, levels_var)
		if (verbose) printf(cmd + "\n")
		stata(cmd)

		cmd = sprintf("qui replace %s = 0 if %s!=1", counts_var, tag_var)
		if (verbose) printf(cmd + "\n")
		stata(cmd)
		
		st_dropvar(tag_var)
	}
	else {
		counts_var = tag_var
	}

	levels = st_data(., levels_var, touse)
	counts = st_data(., counts_var, touse)
	idx = selectindex(counts)
	counts = counts[idx]

	// TODO: allow strings with st_sdata()
	if (save_keys | sort_levels) {
		keys = st_data(idx, vars, touse)
	}

	num_levels = rows(counts)
	num_obs = rows(levels)
	num_vars = cols(vars)

	assert_msg(num_obs > 0, "no observations")
	assert_msg(num_vars > 0, "no variables")

	// Sort levels by keys
	if (sort_levels & num_levels > 1) {
		p = order(keys, 1..num_vars) // this is O(K log K) !!!
		if (save_keys) keys = keys[p, .] // _collate(keys, p)
		counts = counts[p] // _collate(counts, p)
		levels = rows(levels) > 1 ? invorder(p)[levels] : 1
	}
	p = . // save memory

	F = Factor()
	F.num_levels = num_levels
	F.num_obs = num_obs
	if (save_keys) swap(F.keys, keys)
	swap(F.levels, levels)
	swap(F.counts, counts)
	F.method = "gtools"
	assert_msg(rows(F.levels) == F.num_obs & cols(F.levels) == 1, "levels")
	if (save_keys==1) assert_msg(rows(F.keys) == F.num_levels, "keys")
	if (count_levels) assert_msg(rows(F.counts)==F.num_levels & cols(F.counts)==1, "counts")
	F.is_sorted = 0
	return(F)
}

end
