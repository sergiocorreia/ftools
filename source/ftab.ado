program define ftab
	timer on 10
	syntax varname
	tempname table
	mata: ftab("`varlist'", "`table'")
	//set trace on
	Display, variable(`varlist') table(`table')
	timer off 10
end

cap pr drop Display
pr Display
	syntax, variable(name) table(name)
	tempname mytab


	loc label : var label `variable'
	loc cols : rownames `table' , quoted
	loc rows : colnames `table' , quoted
	
	// Raw
	matrix list `table', title(`label') format(%8.2g)

	// More detailed
	// TODO: WRAP HEADER
	di
	.`mytab' = ._tab.new, col(4) lmargin(2) comma
	.`mytab'.width 		13	|	12			12			12
	.`mytab'.pad    	 .    	2			2 			2
	.`mytab'.numfmt    	 .    	%8.0g		%8.0g 		%4.2f
	.`mytab'.titlefmt   %12s 	    %8s			%8s			%8s
	.`mytab'.sep, top
	.`mytab'.titles "`label'" `rows'
	// .`mytab'.row "" `table'[1, 1] `table'[1, 2] `table'[1, 3]

end

ftools check
findfile "ftools_type_aliases.mata"
include "`r(fn)'"

mata:
mata set matastrict on
void ftab(`Varname' var, `String' mat_name) {
	`Factor' F
	`Vector' sums, perc
	`Matrix' ans
	`StringMatrix' rowstripe, colstripe
	timer_on(11)
	F = factor(var, "", 1)
	timer_off(11)
	timer_on(12)
	sums = runningsum(F.counts)
	perc = sums :/ sums[rows(sums)] :* 100
	timer_off(12)
	timer_on(13)
	st_matrix(mat_name, (F.counts, sums, perc))
	timer_off(13)
	timer_on(14)
	rowstripe = J(rows(F.keys), 1, ""), (isreal(F.keys) ? strofreal(F.keys) : F.keys)
	colstripe = ("", "", "" \ "Freq.", "Percent", "Cum.")'
	st_matrixcolstripe(mat_name, colstripe)
	st_matrixrowstripe(mat_name, rowstripe)
	timer_off(14)
}
end


exit

* Tests
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/source")

clear all
sysuse auto
la var turn "this is a very very VERY long label"
tab turn
ftab turn

* Benchmark
