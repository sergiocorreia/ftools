// --------------------------------------------------------------------------
// Code for bipartite graphs
// - For simplicity, assume the graph represent (firm, ceo) pairs
// --------------------------------------------------------------------------
mata:


// --------------------------------------------------------------------------
// init_zigzag()
// --------------------------------------------------------------------------
//   Construct -queue- and -stack- vectors that allow zigzag iteration
//   
//   queue: firm and CEOs that will be processed, in the required order
//   	   note: negative values indicate CEOs
//   
//   stack: for each firm/CEO, the list of nodes it connects to
//          note: stacks are zero-separated
//   
//   If we only care about -num_subgraph_id-, call it with stack==queue==.
// --------------------------------------------------------------------------

`Real' init_bipartite_zigzag(`Factor' F1,
                   `Factor' F2,
				   `Factor' F12,
				   `Factor' F12_1,
				   `Factor' F12_2,
				   `Vector' queue,
				   `Vector' stack,
				   `Vector' subgraph_id,
				   `Boolean' cores,
				   `Boolean' verbose)
{
	`Integer' N1 			// Number of firms
	`Integer' N2 			// Number of CEOs
	`Integer' M 			// Number of firms and CEOs
	`Integer' i_queue
	`Integer' id 			// firm number if id>0; error if id=0; ceo number if id<0
	`Integer' j 			// firm # (or viceversa)
	`Integer' k 			// ceo # (or viceversa)
	`Integer' c 			// temporary counter
	`Integer' i 			// temporary iterator
	`Integer' i_stack		// use to process the queue
	`Integer' last_i		// use to fill out the queue
	`Integer' start_j		// use to search for firms to start graph enumeration
	`Integer' num_subgraphs
	`Boolean' save_subgraphs
	
	`Vector' counter1
	`Vector' counter2
	`Vector' keys1_by_2
	`Vector' keys2_by_1
	`Vector' done1
	`Vector' done2
	`Matrix' matches // list of CEOs that matched with firm j (or viceversa)

	`Vector' orphan1, orphan2


	if (verbose) printf("{txt} - initializing zigzag iterator for bipartite graphs\n")

	// Run this because we use F.info
	F12_1.panelsetup()
	F12_2.panelsetup()
	
	// F12 must be created from F1.levels and F2.levels (not from the original keys)
	// This is set automatically by join_factors() with the correct flag:
	//			F12 = join_factors(F1, F2, ., ., 1)
	// But you can also run 
	//			F12 = _factor( (F1.levels, F2.levels) )
	//			asarray(F12.extra, "levels_as_keys", 1)
	assert(asarray(F12.extra, "levels_as_keys") == 1)

	N1 = F1.num_levels
	N2 = F2.num_levels
	M = N1 + N2
	i_stack = 0
	last_i = 0
	start_j = 1
	num_subgraphs = 0
	
	queue = J(M, 1, 0)
	stack = J(F12.num_levels + M, 1, .) // there are M zeros
	counter1 = J(N1, 1, 0)
	counter2 = J(N2, 1, 0)
	keys1_by_2 = F12_2.sort(F12.keys[., 1])
	keys2_by_1 = F12_1.sort(F12.keys[., 2])
	done1 = J(N1, 1, 0) // if a firm is already on the queue
	done2 = J(N2, 1, 0) // if a CEO is already on the queue

	// If subgraph_id (mobility groups) is anything BUT zero, we will save them
	save_subgraphs = (subgraph_id != 0)
	if (save_subgraphs) {
		subgraph_id = J(N2, 1, .)
	}

	// Use -j- for only for firms and -k- only for CEOs
	// Use -i_queue- to iterate over the queue and -i_stack- over the stack
	// Use -last_i- to fill out the queue (so its the last filled value)
	// Use -i- to iterate arbitrary vectors
	// Use -id- to indicate a possible j or k (negative for k)
	// Use -start_j- to remember where to start searching for new subgraphs
	
	for (i_queue=1; i_queue<=M; i_queue++) {
		id = queue[i_queue] // >0 if firm ; <0 if CEO; ==0 if nothing yet
		j = k = . // just to avoid bugs
		
		// Pick starting point (useful if the graph is disjoint!)
		if (id == 0) {
			assert(last_i + 1 == i_queue)
			for (j=start_j; j<=N1; j++) {
				if (!done1[j]) {
					queue[i_queue] = id = j
					start_j = j + 1
					++last_i
					break
				}
			}
			// printf("{txt} - starting subgraph with firm %g\n", j)
			++num_subgraphs
			assert(id != 0) // Sanity check
		}

		if (id > 0) {
			// It's a firm
			j = id
			done1[j] = 1
			matches = panelsubmatrix(keys2_by_1, j, F12_1.info)
			for (i=1; i<=rows(matches); i++) {
				k = matches[i]
				c = counter2[k]
				counter2[k] = c + 1
				if (!done2[k]) {
					if (!c) {
						queue[++last_i] = -k
					}
				 	stack[++i_stack] = k
				}
			}
			stack[++i_stack] = 0
		}
		else {
			// It's a CEO
			k = -id
			done2[k] = 1
			matches = panelsubmatrix(keys1_by_2, k, F12_2.info)
			for (i=1; i<=rows(matches); i++) {
				j = matches[i]
				c = counter1[j]
				counter1[j] = c + 1
				if (!done1[j]) {
					if (!c) {
						queue[++last_i] = j
					}
					stack[++i_stack] = j
				}
			}
			stack[++i_stack] = 0
			if (save_subgraphs) subgraph_id[k] = num_subgraphs
		}
	}

	// Sanity checks
	assert(counter1 == F12_1.counts)
	assert(counter2 == F12_2.counts)
	assert(!anyof(queue, 0)) // queue can't have zeros at the end
	assert(allof(done1, 1))
	assert(allof(done2, 1))
	assert(!missing(queue))
	assert(!missing(stack))

	if (save_subgraphs) {
		subgraph_id = subgraph_id[F2.levels]
	}
	
	if (verbose) printf("{txt}   (%g disjoint subgraphs found)\n", j)

	// Compute vertex core numbers (for k-core prunning)
	compute_core_numbers(F12_1, F12_2, keys1_by_2, keys2_by_1, 0, 1)



	return(num_subgraphs)
}



// Compute core numbers of each vertex
// This allows us to run k-core prunning
// Based on: https://arxiv.org/abs/cs/0310049

`Vector' compute_core_numbers(`Factor' F12_1,
                              `Factor' F12_2,
                              `Vector' keys1_by_2,
                              `Vector' keys2_by_1,
                              `Vector' drop_order,
                              `Boolean' verbose)
{
// v, u, w are vertices; <0 for CEOs and >0 for firms
// vert is sorted by degree; deg is unsorted
// pos[i] goes from sorted to unsorted, so:
// 		vert[i] === original_vert[ pos[i] ]
// invpos goes from unsorted to sorted, so:
//		vert[invpos[j]] === original_vert[j]

// i_u represents the pos. of u in the sorted tables
// pu represents the pos. of u in the unsorted/original tables


	`Factor'				Fbin
	`Boolean'				is_firm
	`Integer'				N, M, ND, N1, j
	`Integer'				i_v, i_u, i_w
	`Integer'				pv, pu, pw
	`Integer'				v, u, w
	`Integer'				dv, du
	`Vector'				bin, deg, pos, invpos, vert, neighbors

	assert(F12_1.panel_is_setup==1)
	assert(F12_2.panel_is_setup==1)
	
	N1 = F12_1.num_levels
	N = F12_1.num_levels + F12_2.num_levels

	deg = F12_1.counts \ F12_2.counts
	ND = max(deg) // number of degrees
	
	Fbin = _factor(deg, 1, verbose)
	Fbin.panelsetup()

	bin = J(ND, 1, 0)
	bin[Fbin.keys] = Fbin.counts
	bin = runningsum(1 \ bin[1..ND-1])
	
	pos = Fbin.p
	invpos = invorder(Fbin.p)

	vert = Fbin.sort(F12_1.keys \ -F12_2.keys)
	
	for (i_v=1; i_v<=N; i_v++) {
		v = vert[i_v]
		is_firm = (v > 0)
			
		neighbors = is_firm ? panelsubmatrix(keys2_by_1, v, F12_1.info) : panelsubmatrix(keys1_by_2, -v, F12_2.info)
		M = rows(neighbors)
		
		for (j=1; j<=M; j++) {	
			pv = pos[i_v]
			pu = is_firm ? N1 + neighbors[j] : neighbors[j] // is_firm is *not* for the neighbor
			dv = deg[pv]
			du = deg[pu]
		
			if (dv < du) {
				i_w = bin[du]
				w = vert[i_w]
				u = is_firm ? -j : j // is_firm is *not* for the neighbor
				if (u != w) {
					pw = pos[i_w]
					i_u = invpos[pu]
					pos[i_u] = pw
					pos[i_w] = pu
					vert[i_u] = w
					vert[i_w] = u
					invpos[pu] = i_w
					invpos[pw] = i_u
				}
				bin[du] = bin[du] + 1
				deg[pu] = deg[pu] - 1
				// add order part here
			}
		} // end for neighbor u (u ~ v)
	} // end for each node v

	return(deg)
	// ((F1.keys \ F2.keys), (F12_1.keys \ -F12_2.keys))[selectindex(deg:==1), .]
}


end
