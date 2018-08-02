// Helper functions ----------------------------------------------------------
mata:

`Void' assert_msg(`Boolean' t, | `String' msg, `Integer' rc)
{
	if (args()<2 | msg=="") msg = "assertion is false"
	if (args()<3 | rc==.) rc = 3498
	if (t==0) _error(rc, msg)
}


`Void' assert_in(`DataCell' value, `DataRow' valid_values, | string scalar msg)
{
	if (args()<2 | msg=="") msg = "assertion is false; value not in list"
	// "anyof(valid_values, value)"  <==> "value in valid_values" [Python]
	if (!anyof(valid_values, value)) _error(msg)
}


`Void' assert_boolean(`DataCell' value, | string scalar msg)
{
	if (args()<2 | msg=="") msg = "assertion is false; value not boolean"
	assert_in(value, (0,1), msg)
}


// mask: a dummy variable indicating selection (like -touse-)
// Example usage:
// mata: idx = (1,2,5,9)'
// mata: m = create_mask(12, 0, idx, 1)
// mata: update_mask(m, idx, 2)
// mata: update_mask(m, (1,3)', 10)

`Void' update_mask(`Variable' mask, `Vector' index, `Real' value)
{
	mask[index] = J(rows(index), 1, value)
}


`Variable' create_mask(`Integer' obs, `Real' default_value, `Vector' index, `Real' value)
{
	`Variable'		mask
	mask = J(obs, 1, default_value)
	update_mask(mask, index, value)
	return(mask)
}


`DataFrame' __fload_data(`Varlist' varlist,
                       | `DataCol' touse,
                         `Boolean' touse_is_selectvar)
{
	`Integer'				num_vars
	`Boolean'				is_num
	`Integer'				i
	`DataFrame'				data

	if (args()<2) touse = .
	if (args()<3) touse_is_selectvar = 1 // can be selectvar (a 0/1 mask) or an index vector

	varlist = tokens(invtokens(varlist)) // accept both types
	num_vars = cols(varlist)
	is_num = st_isnumvar(varlist[1])
	for (i = 2; i <= num_vars; i++) {
		if (is_num != st_isnumvar(varlist[i])) {
			_error(999, "variables must be all numeric or all strings")
		}
	}
	//     idx   = touse_is_selectvar ?   .   : touse
	// selectvar = touse_is_selectvar ? touse :   .
	if (is_num) {
		data =  st_data(touse_is_selectvar ? . : touse , varlist, touse_is_selectvar ? touse : .)
	}
	else {
		data = st_sdata(touse_is_selectvar ? . : touse , varlist, touse_is_selectvar ? touse : .)
	}
	return(data)
}


`Void' __fstore_data(`DataFrame' data,
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


// Based on Nick Cox's example
// https://www.statalist.org/forums/forum/general-stata-discussion/general/1330558-product-of-row-elements?p=1330561#post1330561
`Matrix' rowproduct(`Matrix' X)
{
	`Integer' i, k
	`Matrix' prod
	k = cols(X)
	if (k==1) return(X)
	prod = X[,1]
	for(i = 2; i<=k; i++) {
		prod = prod :* X[,i]
	}
	return(prod)
}


end
