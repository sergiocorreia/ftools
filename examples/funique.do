* Prototype of -unique-

cap mata: mata drop funique()

cap pr drop funique
program funique
	syntax varlist [if] [in], [Detail]
	
	mata: funique("`varlist'", "`detail'"!="")
end



mata:
mata set matastrict off
void funique(string scalar varlist, real scalar detail)
{
	class Factor scalar F
	F = factor(varlist)
	printf("{txt}Number of unique values of turn is {res}%-11.0f{txt}\n", F.num_levels)
	printf("{txt}Number of records is {res}%-11.0f{txt}\n", F.num_obs)
	if (detail) {
		(void) st_addvar("long", tempvar=st_tempname())
		st_store(1::F.num_levels, tempvar, F.counts)
		st_varlabel(tempvar, "Records per " + invtokens(F.varlist))
		stata("su " + tempvar + ", detail")
	}
}
end


funique turn, det
unique turn, det
