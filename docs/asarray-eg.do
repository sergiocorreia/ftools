clear all
cls
set more off


// Create fake dataset with two identifiers
set obs 100000
gen long id1 = floor(runiform()*100)
gen long id2 = floor(runiform()*100)
su id*


mata:
mata set matastrict on

timer_clear()
vars = st_data(., .)

// Builtin asociative array
transmorphic scalar counter1(real matrix vars)
{
	real i, n, cols, dict_size, val
	real vector dict
	transmorphic matrix keys
	transmorphic rowvector key
	transmorphic scalar A
	
	cols = cols(vars)
	n = rows(vars)
	dict_size = 100000
	A = asarray_create("real", cols, dict_size)
	asarray_notfound(A, 0)

	// Fill asarray
	for (i=1; i<=n; i++) {
		val = asarray(A, vars[i, .])
		asarray(A, vars[i, .], val + 1)
	}
	return(A)
}

// Alternative asociative array; use linear probing
// (or quadratic probing, or any other open addressing strat)
void counter2(real matrix vars, real matrix dict, real matrix keys)
{
	real i, h, n, cols, dict_size, val
	transmorphic rowvector key
	cols = cols(vars)
	n = rows(vars)
	dict_size = 100000
	dict = J(dict_size, 1, 0)
	keys = J(dict_size, cols, .)
	for (i=1; i<=n; i++) {
		key = vars[i, .]
		h = hash1(key, dict_size)
		val = dict[h]
		
		// key not found before
		if (val == 0) {
			dict[h] = 1
			keys[h, .] = key
		}
		// key was found, no collision
		else if (key == keys[h, .]) {
			dict[h] = dict[h] + 1
		}
		// collision; increment pointer h until empty slot found
		else {
			do {
				++h
				if (h > dict_size) {
					h = 1
				}
				val = dict[h]
				
				if (val == 0) {
					dict[h] = 1
					keys[h, .] = key
					break
				}
				if (key == keys[h, .]) {
					dict[h] = dict[h] + 1
					break
				}
			} while (1)
		}
	}
}

real scalar get1(transmorphic scalar A, transmorphic matrix x)
{
	return(asarray(A, x))
}


real scalar get2(real vector dict, transmorphic matrix keys, transmorphic matrix x)
{
	real h, val, dict_size
	dict_size = 100000
	h = hash1(x, dict_size)
	do {
		val = dict[h]
		if (val==0) {
			return(0)
			break
		}
		else if (keys[h, .] == x) {
			return(val)
			break
		}
		else {
			++h
		}
	} while (1)
}

// Builtin
timer_on(1)
c1 = counter1(vars)
timer_off(1)

// Alternative
timer_on(2)
dict = keys = .
c2 = counter2(vars, dict, keys)
timer_off(2)

// Check that they give the same values
x = (1,1)
get1(c1, x)
get2(dict, keys, x)

timer()




// Done
end
