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
//   If we only care about -num_subgraphs-, call it with stack==queue==.
// --------------------------------------------------------------------------

`Real' init_zigzag(`Factor' F1,
                   `Factor' F2,
				   `Factor' F12,
				   `Factor' F12_1,
				   `Factor' F12_2,
				   `Vector' queue,
				   `Vector' stack,
				   `Vector' connected_group,
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
	
	`Vector' counter1
	`Vector' counter2
	`Vector' keys1_by_2
	`Vector' keys2_by_1
	`Vector' done1
	`Vector' done2

	`Matrix' matches // list of CEOs that matched with firm j (or viceversa)

	if (verbose) printf("{txt} - initializing zigzag iterator for bipartite graphs\n")

	// Run this because we use F.info
	F12_1.panelsetup()
	F12_2.panelsetup()
	
	// F12 must be created from F1.levels and F2.levels (not the original keys)
	// This is set automatically by join_factors() with the correct flag
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
	
	if (verbose) printf("{txt}   (%g disjoint subgraphs found)\n", j)
	return(num_subgraphs)
}
end
