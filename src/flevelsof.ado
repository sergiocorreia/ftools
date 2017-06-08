*! version 2.11.0 08jun2017
program define flevelsof, rclass
	syntax varname [if] [in] [, Separate(str) MISSing loc(str) Clean Verbose FORCEmata]

	* Use -levelsof- for small datasets
	if (c(N)<1e6) & ("`forcemata'"=="") {
		levelsof `0'
		exit
	}

	
	_assert (c(N)), msg("no observations") rc(2000)
	if ("`separate'" == "") loc separate " "
	if ("`missing'" != "") loc novarlist "novarlist"
	marksample touse, strok `novarlist'
	loc isnum = strpos("`: type `varlist''", "str")==0 // Will fail if we have 2+ variables
	loc clean = ("`clean'"!="")
	loc verbose = ("`verbose'" != "")

	mata: flevelsof("`varlist'", "`touse'", "`separate'", `isnum', `clean', `c(max_macrolen)', `verbose')
	//di as err "macro length exceeded"
	//exit 1000

	di as txt `"`vals'"'
	return local levels `"`vals'"'
	if ("`loc'" != "") {
		c_local `loc' `"`vals'"'
	}
end


ftools, check
findfile "ftools_type_aliases.mata"
include "`r(fn)'"

mata:
mata set matastrict on

void flevelsof(`String' varlist,
                        `String' touse,
                        `String' sep,
                        `Boolean' isnum,
                        `Boolean' clean,
                        `Integer' maxlen,
                        `Boolean' verbose)
{
	`Factor'				F
	`DataRow'				keys
	`String'				ans
	F = factor(varlist, touse, verbose, "", 1, 0)
	keys = F.keys'
	if (isnum) keys = strofreal(keys, "%40.10g")
	if (!isnum & !clean) keys = (char(96) + char(34)) :+ keys :+ (char(34) + char(39))
	ans = invtokens(keys, sep)
	if (strlen(ans)>maxlen) {
		printf("{err}macro length exceeded\n")
		exit(1000)
	}
	else {
		123
	}
	st_local("vals", ans)
}

end

exit
