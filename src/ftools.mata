// ---------------------------------------------------------------------------
// Mata Code: Efficiently compute levels of variables (factors/categories)
// ---------------------------------------------------------------------------
// Project URL: https://github.com/sergiocorreia/ftools


// Miscellanea ---------------------------------------------------------------
	findfile "ftools_type_aliases.mata"
	include "`r(fn)'"
	set matadebug off

	mata: mata clear
	mata: mata set matastrict on
	mata: mata set mataoptimize on
	mata: mata set matalnum off

	// selectindex() appeared on Stata 13
	// For lower versions, we'll use a slower alternative
	// (how much slower?!)
	if (c(stata_version) < 13) {
		loc selectindex "select(1::rows(dict), dict)"
	}
	else {
		loc selectindex "selectindex(dict)"
	}

// Versioning ---------------------------------------------------------------
	ms_get_version ftools // moresyntax package
	assert("`package_version'" != "")
    mata: string scalar ftools_version() return("`package_version'")
    mata: string scalar ftools_stata_version() return("`c(stata_version)'")
    mata: string scalar ftools_joint_version() return("`package_version'|`c(stata_version)'")


mata:

// Main class ----------------------------------------------------------------

class Factor
{
	`Integer'				num_levels			// Number of levels
	`Integer'				num_obs				// Number of levels
	`Varname'				touse				// Name of touse variable
	`Varlist'				varlist				// Variable names of keys
	`Varlist'				varformats, varlabels, varvaluelabels, vartypes
	`Dict'					vl
	`Vector'				levels				// levels that match the keys
	`DataRow'				keys				// Set of keys found
	`Vector'				counts				// Count of the levels/keys
	`Matrix'				info
	`Vector'				p
	`Vector'				inv_p				// inv_p = invorder(p)
	`String'				method				// Hash fn used
	//`Vector'				sorted_levels
	`Boolean'				is_sorted			// Is varlist==sorted(varlist)?
	`String'				sortedby			// undocumented; save sort order of dataset
	`Boolean'				panel_is_setup

	void					new()
	void					panelsetup()		// aux. vectors
	void					store_levels()		// Store levels in the dta
	void					store_keys()		// Store keys & format/lbls
	`DataFrame'				sort()				// Initialize panel view
	void					_sort()				// as above but in-place
	`DataFrame'				invsort()			// F.invsort(F.sort(x))==x

	`Boolean'				nested_within()		// True if nested within a var
	`Boolean'				equals()			// True if F1 == F2

	void					__inner_drop()		// Adjust to dropping obs.
	`Vector'				drop_singletons()	// Adjust to dropping obs.
	void					drop_obs()			// Adjust to dropping obs.
	void					keep_obs()			// Adjust to dropping obs.
	void					drop_if()			// Adjust to dropping obs.
	void					keep_if()			// Adjust to dropping obs.
	`Boolean'				is_id()				// 1 if all(F.counts:==1)

	`Dict'					extra				// extra information
}


void Factor::new()
{
	keys = J(0, 1, .)
	varlist = J(1, 0, "")
	info = J(0, 2, .)
	counts = J(0, 1, .)
	p = J(0, 1, .)
	inv_p = J(0, 1, .)
	touse = ""
	panel_is_setup = 0
	extra = asarray_create("string", 1, 20)
}


void Factor::panelsetup()
{
	// Fill out F.info and F.p
	`Integer'				level
	`Integer'				obs
	`Vector'				index

	if (panel_is_setup) return

	if (counts == J(0, 1, .)) {
		_error(123, "panelsetup() requires the -counts- vector")
	}

	if (num_levels == 1) {
		info = 1, num_obs
		p = 1::num_obs
		panel_is_setup = 1
		return
	}

	// Equivalent to -panelsetup()- but faster (doesn't require a prev sort)
	info = runningsum(counts)
	index = 0 \ info[|1 \ num_levels - 1|]
	info = index :+ 1 , info

	assert_msg(rows(info) == num_levels & cols(info) == 2, "invalid dim")
	assert_msg(rows(index) == num_levels & cols(index) == 1, "invalid dim")

	if (!is_sorted) {
		// Compute permutations. Notes:
		// - Uses a counting sort to achieve O(N) instead of O(N log N)
		//   See https://www.wikiwand.com/en/Counting_sort
		// - A better implementation can make this parallel for num_levels small

		p = J(num_obs, 1, .)
		for (obs = 1; obs <= num_obs; obs++) {
			level = levels[obs]
			p[index[level] = index[level] + 1] = obs
		}
	}
	panel_is_setup = 1
}


`DataFrame' Factor::sort(`DataFrame' data)
{
	if (is_sorted) return(data)
	panelsetup()
	assert_msg(rows(data) ==  num_obs, "invalid data rows")

	// For some reason, this is much faster that doing it in-place with collate
	return(cols(data)==1 ? data[p] : data[p, .])
}


void Factor::_sort(`DataFrame' data)
{
	if (is_sorted) return(data)
	panelsetup()
	assert_msg(rows(data) ==  num_obs, "invalid data rows")
	_collate(data, p)
}


`DataFrame' Factor::invsort(`DataFrame' data)
{
	if (is_sorted) return(data)
	panelsetup()
	if (inv_p == J(0, 1, .)) inv_p = invorder(p)
	assert_msg(rows(data) ==  num_obs, "invalid data rows")

	// For some reason, this is much faster that doing it in-place with collate
	return(cols(data)==1 ? data[inv_p] : data[inv_p, .])
}


void Factor::store_levels(`Varname' newvar)
{
	`String'				type
	type = (num_levels<=100 ? "byte" : (num_levels <= 32740 ? "int" : "long"))
	__fstore_data(levels, newvar, type, touse)
}


void Factor::store_keys(| `Integer' sort_by_keys)
{
	`String'				lbl
	`Integer'				i
	`StringRowVector'		lbls
	`Vector'				vl_keys
	`StringVector'			vl_values
	if (sort_by_keys == .) sort_by_keys = 0
	if (st_nobs() != 0 & st_nobs() != num_levels) {
		_error(198, "cannot save keys in the original dataset")
	}
	if (st_nobs() == 0) {
		st_addobs(num_levels)
	}
	assert(st_nobs() == num_levels)

	// Add label definitions
	lbls = asarray_keys(vl)
	for (i = 1; i <= length(lbls); i++) {
		lbl = lbls[i]
		vl_keys = asarray(asarray(vl, lbl), "keys")
		vl_values = asarray(asarray(vl, lbl), "values")
		st_vlmodify(lbl, vl_keys, vl_values)
	}

	// Add variables
	if (substr(vartypes[1], 1, 3) == "str") {
		st_sstore(., st_addvar(vartypes, varlist, 1), keys)
	}
	else {
		st_store(., st_addvar(vartypes, varlist, 1), keys)
	}

	// Add formats, var labels, value labels
	for (i = 1; i <= length(varlist); i++) {
		st_varformat(varlist[i], varformats[i])
		st_varlabel(varlist[i], varlabels[i])
		if (st_isnumvar(varlist[i])) {
			st_varvaluelabel(varlist[i], varvaluelabels[i])
		}
	}

	// Sort
	if (sort_by_keys) {
		stata(sprintf("sort %s", invtokens(varlist)))
	}
}


`Boolean' Factor::nested_within(`DataCol' x)
{
	`Integer'				i, j
	`Real'					val, prev_val
	`Vector'				y

	y = J(num_levels, 1, .)
	assert(rows(x) == num_obs)
	assert(!hasmissing(x))

	for (i = 1; i <= num_obs; i++) {
		val = x[i]
		j = levels[i]
		prev_val = y[j]
		if (prev_val != val) {
			if (prev_val != .) {
				return(0)
			}
			y[j] = val
		}
	}
	return(1)
}


`Boolean' Factor::equals(`Factor' F)
{
	if (num_obs != F.num_obs) return(0)
	if (num_levels != F.num_levels) return(0)
	if (keys != F.keys) return(0)
	if (counts != F.counts) return(0)
	if (levels != F.levels) return(0)
	return(1)
}


void Factor::keep_if(`Vector' mask)
{
	drop_obs(selectindex(!mask))
}


void Factor::drop_if(`Vector' mask)
{
	drop_obs(selectindex(mask))
}


void Factor::keep_obs(`Vector' idx)
{
	`Vector'				tmp
	tmp = J(num_obs, 1, 1)
	tmp[idx] = J(rows(idx), 1, 0)
	drop_obs(selectindex(tmp))
}


void Factor::drop_obs(`Vector' idx)
{
	`Integer'				i, j, num_dropped_obs
	`Vector'				offset

	assert(all(idx :>0))
	assert(all(idx :<=num_obs))

	if (counts == J(0, 1, .)) {
		_error(123, "drop_obs() requires the -counts- vector")
	}

	num_dropped_obs = rows(idx)

	// Decrement F.counts to reflect dropped observations
	offset = levels[idx] // warning: variable will be reused later
	assert(rows(offset)==num_dropped_obs)
	for (i = 1; i <= num_dropped_obs; i++) {
		j = offset[i]
		counts[j] = counts[j] - 1
	}
	assert(all(counts :>= 0))
	
	// Update contents of F based on just idx and the updated F.counts
	__inner_drop(idx)
}


// This is an internal method that updates F based on 
// i) the list of dropped obs, ii) the *already updated* F.counts
void Factor::__inner_drop(`Vector' idx)
{
	`Vector'				dropped_levels, offset
	`Integer'				num_dropped_obs, num_dropped_levels

	num_dropped_obs = rows(idx)

	// Levels that have a count of 0 are now dropped
	dropped_levels = selectindex(!counts) // select i where counts[i] == 0
	num_dropped_levels = rows(dropped_levels)

	// Need to decrement F.levels to reflect that we have fewer levels
	// (This is the trickiest part)
	offset = J(num_levels, 1, 0)
	offset[dropped_levels] = J(num_dropped_levels, 1, 1)
	offset = runningsum(offset)
	levels = levels - offset[levels]

	// Remove the obs of F.levels that were dropped
	levels[idx] = J(num_dropped_obs, 1, .)
	levels = select(levels, levels :!= .)

	// Update the remaining properties
	num_obs = num_obs - num_dropped_obs
	num_levels = num_levels - num_dropped_levels
	keys = select(keys, counts)
	counts = select(counts, counts) // must be at the end!

	// Clear these out to prevent mistakes
	p = J(0, 1, .)
	inv_p = J(0, 1, .)
	info = J(0, 2, .)
}


`Vector' Factor::drop_singletons()
{
	`Integer'				num_singletons
	`Vector'				mask, idx

	if (counts == J(0, 1, .)) {
		_error(123, "drop_singletons() requires the -counts- vector")
	}

	mask = (counts :== 1)
	num_singletons = sum(mask)
	if (num_singletons == 0) return(J(0, 1, .))
	counts = counts - mask
	idx = selectindex(mask[levels])
	
	// Update contents of F based on just idx and the updated F.counts
	__inner_drop(idx)
	return(idx)
}


`Boolean' Factor::is_id()
{
	if (counts == J(0, 1, .)) {
		_error(123, "is_id() requires the -counts- vector")
	}
	return(allof(counts, 1))
}


// Main functions -------------------------------------------------------------

`Factor' factor(`Varlist' varnames,
              | `DataCol' touse, // either string varname or a numeric index
                `Boolean' verbose,
                `String' method,
                `Boolean' sort_levels,
                `Boolean' count_levels,
                `Integer' hash_ratio,
                `Boolean' save_keys)
{
	`Factor'				F
	`Varlist'				vars
	`DataFrame'				data
	`Integer'				i
	`Boolean'				integers_only
	`Boolean'				touse_is_mask
	`String'				type, var, lbl
	`Dict'					map
	`Vector'				keys
	`StringVector'			values

	if (args()<2 | touse == "") touse = .

	if (strlen(invtokens(varnames))==0) {
		printf("{err}factor() requires a variable name: %s")
		exit(102)
	}

	vars = tokens(invtokens(varnames))

	// touse is a string with the -touse- variable, unless
	// we use an undocumented feature where it is an observation index
	if (eltype(touse) == "string") {
		assert_msg(orgtype(touse) == "scalar", "touse must be a scalar string")
		assert_msg(st_isnumvar(touse), "touse " + touse + " must be a numeric variable")
		touse_is_mask = 0
	}
	else {
		touse_is_mask = 1
	}
	data = __fload_data(vars, touse, touse_is_mask)

	// Are the variables integers (so maybe we can use the fast hash)?
	integers_only = 1
	for (i=1; i<=cols(vars); i++) {
		type = st_vartype(vars[i])
		if (!anyof(("byte", "int", "long"), type)) {
			integers_only = 0
			break
		}
	}
	
	F = _factor(data, integers_only, verbose, method,
	            sort_levels, count_levels, hash_ratio,
	            save_keys,
	            vars, touse)
	F.sortedby = st_macroexpand("`" + ": sortedby" + "'")
	F.is_sorted = strpos(F.sortedby, invtokens(vars))==1
	F.varlist = vars
	if (touse_is_mask) F.touse = touse
	F.varformats = F.varlabels = F.varvaluelabels = F.vartypes = J(1, cols(vars), "")
	F.vl = asarray_create("string", 1)
	
	for (i = 1; i <= cols(vars); i++) {
		var = vars[i]
		F.varformats[i] = st_varformat(var)
		F.varlabels[i] = st_varlabel(var)
		F.vartypes[i] = st_vartype(var)
		F.varvaluelabels[i] = lbl = st_varvaluelabel(var)
		if (lbl != "") {
			if (st_vlexists(lbl)) {
				pragma unset keys
				pragma unset values
				st_vlload(lbl, keys, values)
				map = asarray_create("string", 1)
				asarray(map, "keys", keys)
				asarray(map, "values", values)
				asarray(F.vl, lbl, map)
			}
		}
	}
	return(F)
}


`Factor' _factor(`DataFrame' data,
               | `Boolean' integers_only,
                 `Boolean' verbose,
                 `String' method,
                 `Boolean' sort_levels,
                 `Boolean' count_levels,
                 `Integer' hash_ratio,
                 `Boolean' save_keys,
                 `Varlist' vars, 			// hack
                 `DataCol' touse)		 	// hack
{
	`Factor'				F, F1, F2
	`Integer'				num_obs, num_vars
	`Integer'				i
	`Integer'				limit0
	`Integer'				size0, size1, dict_size, max_numkeys1
	`Matrix'				min_max
	`RowVector'				delta
	`String'				msg, base_method

	if (integers_only == .) integers_only = 0
	if (verbose == .) verbose = 0
	if (method == "") method = "mata"
	if (sort_levels == .) sort_levels = 1
	if (count_levels == .) count_levels = 1
	if (save_keys == .) save_keys = 1
	
	// Note: Pick a sensible hash ratio; smaller means more collisions
	// but faster lookups and less memory usage

	base_method = method
	msg = "invalid method"
	assert_msg(anyof(("mata", "hash0", "hash1"), method), msg)

	num_obs = rows(data)
	num_vars = cols(data)
	assert_msg(num_obs > 0, "no observations")
	assert_msg(num_vars > 0, "no variables")
	assert_msg(count_levels == 0 | count_levels == 1, "count_levels")
	assert_msg(save_keys == 0 | save_keys == 1, "save_keys")

	// Compute upper bound for number of levels
	if (integers_only) {
		min_max = colminmax(data)
		delta = 1 :+ min_max[2, .] - min_max[1, .]
		for (i = size0 = 1; i <= num_vars; i++) {
			size0 = size0 * delta[i]
		}
		// Fall back to hash1 if there are MVs
		// On principle I could assign a special value to MVs (max + #)
		// While increasing the reported max value;
		// but it seems like too much work...
		if (hasmissing(data)) {
			size0 = .
		}
	}
	else {
		size0 = .
	}


	max_numkeys1 = min((size0, num_obs))
	if (hash_ratio == .) {
		if (size0 < 2 ^ 16) hash_ratio = 5.0
		else if (size0 < 2 ^ 20) hash_ratio = 3.0
		else hash_ratio = 1.5
	}
	msg = sprintf("invalid hash ratio %5.1f", hash_ratio)
	assert_msg(hash_ratio > 1.0, msg)
	size1 = ceil(hash_ratio * max_numkeys1)

	if (size0 == .) {
		if (method == "hash0") {
			printf("{txt}method hash0 cannot be applied, using hash1\n")
		}
		method = "hash1"
	}
	else if (method == "mata") {
		limit0 = 2 ^ 26 // 2 ^ 28 is 1GB; be careful with memory!!!
		// Pick hash0 if it uses less space than hash1
		// (b/c it has no collisions and is sorted at no extra cost)
		method = (size0 < limit0) | (size0 <  size1) ? "hash0" : "hash1"
	}

	dict_size = (method == "hash0") ? size0 : size1
	// Mata hard coded limit! (2,147,483,647 rows)
	assert_msg(dict_size <= 2 ^ 31, "dict size exceeds Mata limits")

	// Hack: alternative approach
	if (base_method == "mata" & method == "hash1" & integers_only & num_vars > 1 & cols(vars)==num_vars) {
		F1 = factor(vars[1], touse, verbose, "hash0", sort_levels, 1, ., save_keys)
		F2 = factor(vars[2..num_vars], touse, verbose, "mata", sort_levels, count_levels, ., save_keys)
		F = join_factors(F1, F2, count_levels, save_keys)
		F1 = F2 = Factor() // clear
		method = "join"
	}
	else if (method == "hash0") {
		F = __factor_hash0(data, verbose, dict_size, count_levels, min_max, save_keys)
	}
	else {
		F = __factor_hash1(data, verbose, dict_size, sort_levels, max_numkeys1, save_keys)
		if (!count_levels) F.counts = J(0, 1, .)
	}
	
	F.method = method

	F.num_obs = num_obs
	assert_msg(rows(F.levels) == F.num_obs & cols(F.levels) == 1, "levels")
	if (save_keys==1) assert_msg(rows(F.keys) == F.num_levels, "keys")
	if (count_levels) {
		assert_msg(rows(F.counts)==F.num_levels & cols(F.counts)==1, "counts")
	}
	if (verbose) {
		msg = "{txt}(obs: {res}%s{txt}; levels: {res}%s{txt};"
		printf(msg, strofreal(num_obs, "%12.0g"), strofreal(F.num_levels))
		msg = "{txt} method: {res}%s{txt}; dict size: {res}%s{txt})\n"
		printf(msg, method, strofreal(dict_size, "%12.0g"))
	}
	F.is_sorted = 0
	return(F)
}


// Perfect hashing (with limitations) -----------------------------------------
// Use this for properly encoded byte/int/long variables

`Factor' __factor_hash0(`Matrix' data,
                        `Boolean' verbose,
                        `Integer' dict_size,
                        `Boolean' count_levels,
                        `Matrix' min_max,
                        `Boolean' save_keys)
{
	`Factor'				F
	`Integer'				K, i, num_levels, num_obs, j
	`Vector'				hashes, dict, levels
	`RowVector'				min_val, max_val, offsets
	`Matrix'				keys
	`Vector'				counts

	num_obs = rows(data)
	K = cols(data)
	min_val = min_max[1, .]
	max_val = min_max[2, .]

	// Build the hash
	
	// 2x speedup when K = 1 wrt the formula with [., K]
	if (K == 1) {
		hashes = data :- (min_val - 1)
	}
	else {
		hashes = data[., K] :- (min_val[K] - 1)
	}

	offsets = J(1, K, 1)
	for (i = K - 1; i >= 1; i--) {
		offsets[i] = offsets[i+1] * (max_val[i+1] - min_val[i+1] + 1)
		hashes = hashes + (data[., i] :- min_val[i]) :* offsets[i]
	}
	assert(offsets[1] * (max_val[1] - min_val[1] + 1) == dict_size)
	
	// Build the new keys
	dict = J(dict_size, 1, 0)
	// It's faster to do dict[hashes] than dict[hashes, .],
	// but that fails if dict is 1x1
	if (length(dict) > 1) {
		dict[hashes] = J(num_obs, 1, 1)
	}
	else {
		dict = 1
	}

	levels = `selectindex'

	num_levels = rows(levels)
	dict[levels] = 1::num_levels

	if (save_keys) {
		if (K == 1) {
			keys = levels :+ (min_val - 1)
		}
		else {
			keys = J(num_levels, K, .)
			levels = levels :- 1
			for (i = 1; i <= K; i++) {
				keys[., i] = floor(levels :/ offsets[i])
				levels = levels - keys[., i] :* offsets[i]
			}
			keys = keys :+ min_val
		}
	}

	// faster than "levels = dict[hashes, .]"
	levels = rows(dict) > 1 ? dict[hashes] : hashes

	hashes = dict = . // Save memory

	if (count_levels) {
		counts = J(num_levels, 1, 0)
		for (i = 1; i <= num_obs; i++) {
			j = levels[i]
			counts[j] = counts[j] + 1
		}
	}

	F = Factor()
	F.num_levels = num_levels
	if (save_keys) swap(F.keys, keys)
	swap(F.levels, levels)
	swap(F.counts, counts)
	return(F)
}


// Open addressing hash function (linear probing) ----------------------------
// Use this for non-integers (2.5, "Bank A") and big ints (e.g. 2014124233573)

`Factor' __factor_hash1(`DataFrame' data,
                        `Boolean' verbose,
                        `Integer' dict_size,
                        `Boolean' sort_levels,
                        `Integer' max_numkeys,
                        `Boolean' save_keys)
{
	`Factor'				F
	`Integer'				h, num_collisions, j, val
	`Integer'				obs, start_obs, num_obs, num_vars
	`Boolean'				single_col
	`Vector'				dict
	`Vector'				levels // new levels
	`Vector'				counts
	`Vector'				p
	`DataFrame'				keys
	`DataRow'				key, last_key
	`String'				msg
	
	assert(dict_size > 0 & dict_size < .)

	num_obs = rows(data)
	num_vars = cols(data)
	dict = J(dict_size, 1, 0)
	levels = J(num_obs, 1, 0)
	keys = J(max_numkeys, num_vars, missingof(data))
	counts = J(max_numkeys, 1, 1) // keys are at least present once!
	single_col = num_vars == 1

	j = 0 // counts the number of levels; at the end j == num_levels
	val = J(0, 0, .)
	num_collisions = 0
	last_key = J(0, 0, missingof(data))

	// The branching below duplicates lots of code but hopefully
	// gives a ~15% speedup (a good compiler would just do the same)
	// (The only diff is replacing "[obs, .]" for "[obs]")
	if (single_col) {
		for (obs = 1; obs <= num_obs; obs++) {
			key = data[obs]

			// (optional) Speedup when dataset is already sorted
			// (at a ~10% cost for when it's not)
			if (last_key == key) {
				start_obs = obs
				do {
					obs++
				} while (obs <= num_obs ? data[obs] == last_key : 0 )
				levels[|start_obs \ obs - 1|] = J(obs - start_obs, 1, val)
				counts[val] = counts[val] + obs - start_obs
				if (obs > num_obs) break
				key = data[obs]
			}

			// Compute hash and retrieve the level the key is assigned to
			h = hash1(key, dict_size)
			val = dict[h]

			// (new key) The key has not been assigned to a level yet
			if (val == 0) {
				val = dict[h] = ++j
				keys[val] = key
			}
			// (collision) Another key already points to the same dict slot
			else if (key != keys[val]) {
				// Look up for an empty slot in the dict

				// Linear probing, not very sophisticate...
				do {
					++num_collisions
					++h
					if (h > dict_size) h = 1
					val = dict[h]

					if (val == 0) {
						dict[h] = val = ++j
						keys[val] = key
						break
					}
					if (key == keys[val]) {
						counts[val] = counts[val] + 1
						break
					}
				} while (1)
			}
			else {
				counts[val] = counts[val] + 1
			}

			levels[obs] = val
			last_key = key
		} // end for >>>
	} // end if >>>
	else {
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
			// (collision) Another key already points to the same dict slot
			else if (key != keys[val, .]) {
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
			else {
				counts[val] = counts[val] + 1
			}

			levels[obs] = val
			last_key = key
		} // end for >>>
	} // end else >>>

	dict = . // save memory

	if (save_keys | sort_levels) keys = keys[| 1 , 1 \ j , . |]
	counts = counts[| 1 \ j |]
	
	if (sort_levels & j > 1) {
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


`Factor' join_factors(`Factor' F1,
                      `Factor' F2, 
                    | `Boolean' count_levels,
                      `Boolean' save_keys)
{
	`Factor'				F
	`Varlist'				vars
	`Boolean'				is_sorted // is sorted by (F1.varlist F2.varlist)
	`Integer'				num_levels, old_num_levels, N, M, i, j
	`Integer'				levels_start, levels_end
	`Integer'				v, last_v, c
	`Integer'				num_keys1, num_keys2
	`RowVector'				key_idx
	`Vector'				Y, p, y, levels, counts, idx
	`DataFrame'				keys

	if (save_keys == .) save_keys = 1
	if (count_levels == .) count_levels = 1

	//if (save_keys & (F1.keys == J(0, 1, .) | F2.keys == J(0, 1, .))) {
	if (save_keys & !( rows(F1.keys) & rows(F2.keys)) ) {
		_error(123, "join_factors() with save_keys==1 requires the -keys- vector")
	}

	vars = invtokens((F1.varlist, F2.varlist))
	is_sorted = (F1.sortedby == F2.sortedby) & (strpos(F2.sortedby, vars)==1)

	F1.panelsetup()
	Y = F1.sort(F2.levels)
	levels = J(F1.num_obs, 1, 0)
	if (count_levels | save_keys) counts = J(F1.num_obs, 1, 1)

	if (save_keys) {
		num_keys1 = cols(F1.keys)
		num_keys2 = cols(F2.keys)
		key_idx = (num_keys1 + 1)..(num_keys1 + num_keys2)
		keys = J(F1.num_obs, num_keys1 + num_keys2, missingof(F1.keys))
	}
	N = F1.num_levels
	levels_end = num_levels = 0

    for (i = 1; i <= N; i++) {
    	y = panelsubmatrix(Y, i, F1.info)
    	M = rows(y)
    	old_num_levels = num_levels

    	if (M == 1) {
    		levels[++levels_end] = ++num_levels
    		if (save_keys) keys[num_levels, .] = F1.keys[i, .] , F2.keys[y, .]
    		// no need to update counts as it's ==1
    	}
    	else {
    		// Compute F.levels
    		if (!is_sorted) {
		    	p = order(y, 1)
		    	y = y[p]
    		}
    		idx = runningsum(1 \ (y[2::M] :!= y[1::M-1]))
	    	levels_start = levels_end + 1
	    	levels_end = levels_end + M
	    	if (!is_sorted) {
	    		levels[|levels_start \ levels_end |] = num_levels :+ idx[invorder(p)]
	    	}
	    	else {
	    		levels[|levels_start \ levels_end |] = num_levels :+ idx
	    	}

	    	// Compute F.counts
	    	if (count_levels | save_keys) {
		    	last_v = y[1]
		    	c = 1
		    	for (j=2; j<=M; j++) {
		    		v = y[j]
		    		if (v==last_v) {
		    			c++
		    		}
		    		else {
		    			counts[++num_levels] = c
		    			c = 1
		    			if (save_keys) keys[num_levels , key_idx] = F2.keys[last_v, .]
		    		}
		    		last_v = v // swap?
		    	}
		    	if (c) {
		    		counts[++num_levels] = c
		    		if (save_keys) keys[num_levels , key_idx] = F2.keys[y[M], .]
		    	}
	    	}
	    	else {
	    		num_levels = num_levels + idx[M]
	    	}

	    	// Compute F.keys
	    	if (save_keys) {
	    		keys[| old_num_levels + 1 , 1 \ num_levels , num_keys1 |] = J(idx[M], 1, F1.keys[i, .])
	    	}

    	}
    }

	F = Factor()
	F.num_obs = F1.num_obs
    F.num_levels = num_levels
    F.method = "join"
    F.sortedby = F1.sortedby
    F.varlist = tokens(vars)

    if (!is_sorted) levels = F1.invsort(levels)
    if (count_levels) counts = counts[| 1 \ num_levels |]
    swap(F.levels, levels)
    if (save_keys) {
    	keys = keys[| 1 , 1 \ num_levels , . |]
    	swap(F.keys, keys)
    }
    swap(F.counts, counts)

    // Extra stuff (labels, etc)
    return(F)
}


// Helper functions ----------------------------------------------------------

void assert_msg(real scalar t, | string scalar msg)
{
	if (args()<2 | msg=="") msg = "assertion is false"
        if (t==0) _error(msg)
}

`DataFrame' __fload_data(`Varlist' varlist,
                       | `DataCol' touse,
                         `Boolean' touse_is_mask)
{
	`Integer'				num_vars
	`Boolean'				is_num
	`Integer'				i
	`DataFrame'				data

	if (args()<2) touse = .
	if (args()<3) touse_is_mask = 1

	varlist = tokens(invtokens(varlist)) // accept both types
	num_vars = cols(varlist)
	is_num = st_isnumvar(varlist[1])
	for (i = 2; i <= num_vars; i++) {
		if (is_num != st_isnumvar(varlist[i])) {
			_error(999, "variables must be all numeric or all strings")
		}
	}
	//   mask    = touse_is_mask ? touse :   .
	// selectvar = touse_is_mask ?   .   : touse
	if (is_num) {
		data =  st_data(touse_is_mask ? touse : . , varlist, touse_is_mask ? . : touse)
	}
	else {
		data = st_sdata(touse_is_mask ? touse : . , varlist, touse_is_mask ? . : touse)
	}
	return(data)
}

void __fstore_data(`DataFrame' data,
                   `Varname' newvar,
                   `String' type,
                 | `String' touse)
{
	`RowVector'				idx
	idx = st_addvar(type, newvar)
	if (substr(type, 1, 3) == "str") {
		if (touse == "") st_sstore(., idx, data)
		else st_sstore(., idx, touse, data)
	}
	else {
		if (touse == "") st_store(., idx, data)
		else st_store(., idx, touse, data)
	}
}
end


// Possible Improvements
// ----------------------
// 1) Do this in a C plugin; perhaps using khash (MIT-lic) like Pandas
// 2) Use a faster hash function like SpookyHash or CityHash (both MIT-lic)
// 3) Use double hashing instead of linear/quadratic probing
// 4) Compute the hashes in parallel
