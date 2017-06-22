 // Hash tables
 // 1) hash0 - Perfect hashing (use the value as the hash)
 // 2) hash1 - Use hash1() with open addressing (linear probing)
 // 3) hashx - (Experimental)

mata:

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
	`RowVector'				min_val, max_val, offsets, has_mv
	`Matrix'				keys
	`Vector'				counts

	// assert(all(data:<=.)) // no .a .b ...

	num_obs = rows(data)
	K = cols(data)
	has_mv = (colmissing(data) :> 0)
	min_val = min_max[1, .]
	max_val = min_max[2, .] + has_mv

	// Build the hash
	
	// 2x speedup when K = 1 wrt the formula with [., K]
	if (K == 1) {
		// Maybe profile and have two cases based on the value of has_mv
		hashes = editmissing(data, max_val) :- (min_val - 1)
	}
	else {
		hashes = editmissing(data[., K], max_val[K]) :- (min_val[K] - 1)
	}

	offsets = J(1, K, 1)
	for (i = K - 1; i >= 1; i--) {
		offsets[i] = offsets[i+1] * (max_val[i+1] - min_val[i+1] + 1)
		hashes = hashes + (editmissing(data[., i], max_val[i]) :- min_val[i]) :* offsets[i]
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

	levels = `selectindex'(dict)

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
		// We need a builtin function that does: increment(counts, levels)
		// Using decrement+while saves us 10% time wrt increment+for
		counts = J(num_levels, 1, 0)
		i = num_obs + 1
		while (--i) {
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
			else if (key == keys[val]) {
				counts[val] = counts[val] + 1
			}
			// (collision) Another key already points to the same dict slot
			else {
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
	} // end else >>>

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
