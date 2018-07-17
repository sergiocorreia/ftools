program define ms_parse_varlist, rclass
	gettoken depvar 0 : 0, bind	
	fvexpand `depvar'
	loc depvar `r(varlist)'
	loc n : word count `depvar'
	_assert (`n'==1), msg("more than one depvar specified: `depvar'")
	_assert (!strpos("`depvar'", "o.")), msg("the values of depvar are omitted: `depvar'")
	c_local depvar `depvar'
	c_local 0 `0'

	return loc depvar `depvar'
	return loc fe_format `fe_format'
	return loc indepvars `indepvars'
end
