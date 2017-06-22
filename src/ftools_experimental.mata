mata:

`Factor' __factor_hash_long(`DataFrame' data,
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
	`Matrix'				dict
	`Vector'				levels // new levels
	`Vector'				counts
	`Vector'				p
	`DataFrame'				keys
	`DataRow'				key, last_key
	`String'				msg

	`Matrix'				ranges
	
	//assert(dict_size > 0 & dict_size < .)
	//assert(cols(data)==1)
	//assert(round(data)==data)
	//assert(min(data)>0)
	//assert(max(data)<1.0x+035)
	
	// The largest integer that can be accurately represented is:
	// 1.0x+035 === 2^53 == 9,007,199,254,740,992
	// See: http://blog.stata.com/2012/04/02/the-penultimate-guide-to-precision
	// On principle, we can map multiple keys into one if it goes below this max

	// Use this to decide if we can represent the data in one column w/out keys
	//ranges = colminmax(data)
	//rowproduct(ranges[2,] - ranges[1,] :+ 1)

	num_obs = rows(data)
	dict = J(dict_size, 2, 0)
	levels = J(num_obs, 1, 0)
	
	//num_vars = 1
	//keys = J(max_numkeys, num_vars, missingof(data))
	//counts = J(max_numkeys, 1, 1) // keys are at least present once!

	val = j = 0
	obs = num_obs
	h = hash1(key = data[obs, 1], dict_size)
	// maybe start from 1 so levels has less weird reordering
	// maybe check for !obs

	while (1) {
		// (key already in dict)
		if (val==key) {
			dict[h, 2] = dict[h, 2] + 1
			if (obs==1) break
			val = dict[h = hash1(key = data[obs--], dict_size), 1] // update key, hash, and val
		}
		// (new key) The key has not been assigned to a level yet
		else if (!val) {
			dict[h] = key
			if (obs==1) break
			val = dict[h = hash1(key = data[obs--], dict_size), 1] // update key, hash, and val
		}
		// (collision) Another key already points to the same dict slot
		else {
			if (h == dict_size) h = 0
			h++
		}
	}

	keys = select(dict, dict)
	// sort keys,counts
	p = order(keys, 1)
	keys = keys[p]
	
	//counts = counts[| 1 \ num_levels |]
	counts = counts[p]

	F = Factor()
	F.num_levels = rows(keys)

	// we're missing levels
	F.levels = data

	//swap(F.levels, levels)
	//if (save_keys) swap(F.keys, keys)
	swap(F.keys, keys)
	swap(F.counts, counts)
	F.keys
	return(F)
}

end
