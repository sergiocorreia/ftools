// DataTable: container that allows both integer and string types ----------------------------------
mata:

class DataTable
{
	`Integer'				key_type			// 1=Integers 2=Strings 3=Hybrid
	`Integer'				rows
	`Integer'				cols
	`Matrix'				data
	`StringMatrix'			sdata
	`RowVector'				column_is_string
	`Boolean'				is_all_numeric, is_all_string, is_hybrid

	`Boolean'				is_integers()
}


`Boolean' DataTable::is_integers(`Varlist' varlist)
{
	`Integer'				k, i
	`String'				type

	if (!is_all_numeric) {
		return(0)
	}

	k = cols(varlist)
	for (i = 1; i <= k; i++) {
		type = st_vartype(varlist[i])
		if (anyof(("byte", "int", "long"), type)) {
			continue
		}
		if (round(data[., i])==data[., i]) {
				continue
		}
		return(0)
	}
	return(1)
}



// Main functions ----------------------------------------------------------------------------------

`DataTable' data_table(`Varlist' varnames,
                     | `DataCol' touse,
                       `Boolean' touse_is_selectvar)
{
	`DataTable'				dt
	`Varlist'				vars, numeric_vars, string_vars
	`RowVector'				var_is_str
	`String'				var
	`Integer'				k, i
	`Matrix'				data
	`StringMatrix'			sdata

	if (args()<2) touse = .
	if (args()<3) touse_is_selectvar = 1 // can be selectvar (a 0/1 mask) or an index vector

	vars = tokens(invtokens(varnames)) // accept both types
	k = cols(vars)
	
	var_is_str = J(1, k, .)
	for (i = 1; i <= k; i++) {
		var = vars[i]
		var_is_str[i] = st_isstrvar(var)
	}
	
	numeric_vars = select(vars, !var_is_str)
	string_vars = select(vars, var_is_str)
	assert(rows(numeric_vars)==1)
	assert(rows(string_vars)==1)

	data =  st_data(touse_is_selectvar ? . : touse , numeric_vars, touse_is_selectvar ? touse : .)
	sdata =  st_sdata(touse_is_selectvar ? . : touse , string_vars, touse_is_selectvar ? touse : .)

	dt = _data_table(data, sdata, var_is_str)
	return(dt)
}


`DataTable' _data_table(`Matrix' data,
                        `StringMatrix' sdata,
                        `RowVector' column_is_string)
{
	`DataTable'				dt
	assert_msg(rows(data) == rows(sdata), "invalid matrix sizes")
	assert_msg(rows(column_is_string) == 1)
	assert_msg(cols(data) + cols(sdata) == cols(column_is_string), "invalid matrix sizes")
	assert( all(column_is_string:==0 :| column_is_string:==1) )

	dt = DataTable()
	dt.rows = rows(data)
	dt.cols = cols(column_is_string)
	dt.data = data
	dt.sdata = sdata
	dt.column_is_string = column_is_string
	dt.is_all_numeric = !any(column_is_string)
	dt.is_all_string = all(column_is_string)
	dt.is_hybrid = min(column_is_string) < max(column_is_string)
	return(dt)
}


// TODO:
// 1) WRITE THE HYBRID HASH
// 2) FIX THE BUGBUG IN MAIN (IS SORTED?)
// 3) ADD .KEYS AND .SKEYS ALL OVER THE PLACE IN FACTOR
// 4) FIX .STORE_KEYS() AND ADD F.IS_STRING (FOR EACH) (ALSO, FILL IN THE TYPE)
`Factor' __factor_hash1_hybrid(
	`DataTable' data,
    `Boolean' verbose,
    `Integer' dict_size,
    `Boolean' sort_levels,
    `Integer' max_numkeys,
    `Boolean' save_keys)
{
	`Factor'				F
	`Integer'				h, num_collisions, j, val
	`Integer'				obs, start_obs, num_obs, num_vars
	`Vector'				dict
	`Vector'				levels // new levels
	`Vector'				counts
	`Vector'				p
	`DataFrame'				keys
	`DataRow'				key, last_key
	`String'				msg

	assert(eltype(data)=="class")
	num_obs = data.rows
	num_vars = data.cols
	assert(dict_size > 0 & dict_size < .)
	assert ((num_vars > 1) + (`is_vector') == 1) // XOR
	dict = J(dict_size, 1, 0)
	levels = J(num_obs, 1, 0)
	keys = J(max_numkeys, num_vars, missingof(data))
	counts = J(max_numkeys, 1, 1) // keys are at least present once!

	j = 0 // counts the number of levels; at the end j == num_levels
	val = J(0, 0, .)
	num_collisions = 0
	last_key = J(0, 0, missingof(data))

	for (obs = 1; obs <= num_obs; obs++) {
		key = data[obs, .]

		// (optional) Speedup when dataset is already sorted
		// (at a ~10% cost for when it's not)
		if (last_key == key) {
			start_obs = obs
			do {
				obs++
			} while (obs <= num_obs ? data[obs, .] == last_key : 0 )
			levels[|start_obs \ obs - 1|] = J(obs - start_obs, 1, val)
			counts[val] = counts[val] + obs - start_obs
			if (obs > num_obs) break
			key = data[obs, .]
		}

		// Compute hash and retrieve the level the key is assigned to
		h = hash1(key, dict_size)
		val = dict[h]

		// (new key) The key has not been assigned to a level yet
		if (val == 0) {
			val = dict[h] = ++j
			keys[val, .] = key
		}
		else if (key == keys[val, .]) {
			counts[val] = counts[val] + 1
		}
		// (collision) Another key already points to the same dict slot
		else {
			// Look up for an empty slot in the dict

			// Linear probing, not very sophisticate...
			do {
				++num_collisions
				++h
				if (h > dict_size) h = 1
				val = dict[h]

				if (val == 0) {
					dict[h] = val = ++j
					keys[val, .] = key
					break
				}
				if (key == keys[val, .]) {
					counts[val] = counts[val] + 1
					break
				}
			} while (1)
		}

		levels[obs] = val
		last_key = key
	} // end for >>>

	dict = . // save memory

	if (save_keys | sort_levels) keys = keys[| 1 , 1 \ j , . |]
	counts = counts[| 1 \ j |]
	
	if (sort_levels & j > 1) {
		// bugbug: replace with binsort?
		p = order(keys, 1..num_vars) // this is O(K log K) !!!
		if (save_keys) keys = keys[p, .] // _collate(keys, p)
		counts = counts[p] // _collate(counts, p)
		levels = rows(levels) > 1 ? invorder(p)[levels] : 1
	}
	p = . // save memory


	if (verbose) {
		msg = "{txt}(%s hash collisions - %4.2f{txt}%%)\n"
		printf(msg, strofreal(num_collisions), num_collisions / num_obs * 100)
	}

	F = Factor()
	F.num_levels = j
	if (save_keys) swap(F.keys, keys)
	swap(F.levels, levels)
	swap(F.counts, counts)
	return(F)
}

end


end
