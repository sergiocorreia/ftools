// Helper functions ----------------------------------------------------------
mata:

`Void' assert_msg(real scalar t, | string scalar msg)
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

end
