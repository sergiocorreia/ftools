*! version 2.30.0 17jul2018
program ms_expand_varlist, rclass
	syntax [varlist(ts fv numeric default=none)] if
	fvexpand `varlist' `if'
	loc varlist  `r(varlist)'`'

	foreach part of local varlist {
		_ms_parse_parts `part'
		loc ok = r(omit) == 0
		loc mask `mask' `ok'
		if (`ok') {
			// BUGBUG: Not sure if this is actually useful...
			//di as error "BEFORE=[`part']"
			// AddBN `part'
			//di as error "AFTER=[`part']"
			loc selected_vars `selected_vars' `part'
		}
		//else {
		//	di as error "OMITTED/BASE: `part'"
		//}
	}

	return local fullvarlist	`varlist'
	return local varlist		`selected_vars'
	return local not_omitted	`mask'
end

capture program drop AddBN
program define AddBN
	loc part `0'

	loc re "^([0-9]+)b?([.LFSD])"
	loc match = regexm("`part'", `"`re'"')
	if (`match') {
		loc part = regexr("`part'", "`re'", regexs(1) + "bn" + regexs(2))
	}

	loc re "#([0-9]+)b?([.LFSD])"
	loc loop = strpos("`part'", "#")
	loc old `part'

	while (`loop') {	
		loc match = regexm("`part'", `"`re'"')
		if (`match') {
			loc part = regexr("`part'", "`re'", "#" + regexs(1) + "bn" + regexs(2))
		}
		loc loop = "`old'" != "`part'"
		loc old `part'
	}

	c_local part `part'
end
