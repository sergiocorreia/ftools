*! version 2.9.0 28mar2017
program ms_parse_varlist, rclass
	sreturn clear
	syntax anything(id="varlist" name=0 equalok)

	* SYNTAX: depvar indepvars [(endogvars = instruments)]
	* depvar		: 	dependent variable
	* indepvars		: 	included exogenous regressors
	* endogvars		: 	included endogenous regressors
	* instruments	: 	excluded exogenous regressors

	ParseDepvar `0' // depvar fe_format
	ParseIndepvars `0' // indepvars
	ParseEndogAndInstruments `0' // endogvars instruments
	loc varlist `depvar' `indepvars' `endogvars' `instruments'

	fvrevar `varlist', list
	loc basevars `r(varlist)'
	local basevars : list uniq basevars

	return loc fe_format `fe_format'
	return loc basevars `basevars'
	return loc varlist `varlist'
	return loc instruments `instruments'
	return loc endogvars `endogvars'
	return loc indepvars `indepvars'
	return loc depvar `depvar'
end


pr ParseDepvar
	gettoken depvar 0 : 0, bind
	fvexpand `depvar'
	loc depvar `r(varlist)'
	loc n : word count `depvar'
	_assert (`n'==1), msg("more than one depvar specified: `depvar'")
	_assert (!strpos("`depvar'", "o.")), msg("the values of depvar are omitted: `depvar'")
	c_local depvar `depvar'
	c_local 0 `0'

	* Extract format of depvar so we can format FEs like this
	fvrevar `depvar', list
	loc fe_format : format `r(varlist)' // The format of the FEs that will be saved
	c_local fe_format `fe_format'
end


pr ParseIndepvars
	if ("`0'" == "") exit
	while ("`0'" != "") {
		gettoken _ 0 : 0, bind match(parens)
		if ("`parens'" == "") {
			loc indepvars `indepvars' `_'
		}
		else {
			continue, break
		}
	}
	
	_assert "`0'" == "", msg("couldn't parse the end of the varlist: <`0'>")

	ms_fvunab indepvars : `indepvars'
	c_local indepvars `indepvars'
	if ("`parens'" != "") {
		c_local 0 "`_'"
	}
	else {
		c_local 0
	}
end


pr ParseEndogAndInstruments
	if ("`0'" == "") exit
	gettoken _ 0 : 0, bind parse("=")
	if ("`_'" != "=") {
		ms_fvunab endogvars : `_'
		c_local endogvars `endogvars'
		gettoken equalsign 0 : 0, bind parse("=")
	}
	ms_fvunab instruments : `0'
	c_local instruments `instruments'
	c_local 0
end
