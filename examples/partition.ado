cap pr drop partition
program define partition, rclass
	syntax varlist, [Verbose]
	loc verbose = ("`verbose'" != "")
	mata: F = factor("`varlist'", "`touse'", `verbose', "", ., ., ., 0)
	mata: F.panelsetup()
	
	loc sortedby : sortedby
	if ("`sortedby'" != "`varlist'") {
		qui ds, has(type numeric)
		loc numvars `r(varlist)'
		
		qui ds, has(type string)
		loc strvars `r(varlist)'
		
		if ("`numvars'" != "") {
				mata: st_view(data = ., ., "`numvars'")
				mata: data[.,.] = F.sort(data)
		}

		if ("`strvars'" != "") {
				mata: st_sview(data = ., ., "`strvars'")
				mata: data[.,.] = F.sort(data)
		}
	}
	
	tempname num_levels info
	mata: st_numscalar("`num_levels'", F.num_levels)
	mata: st_matrix("`info'", F.info)
	mata: printf("{txt}(dataset sorted into %g partitions)\n", F.num_levels)
	mata: mata drop F
	return scalar num_levels = `num_levels'
	return matrix info = `info'
end

ftools, check
exit
