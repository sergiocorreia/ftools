ms_fvstrip.ado - Stata utility for factor variables.  Takes an expanded varlist with possible FVs and strips out b/n/o notation, and returns results in r(varlist).  Optionally also omits omittable FVs.  If varlist needs expansion, use the expand option.

Options:
   expand calls fvexpand on full varlist
   onebyone + expand calls fvexpand on elements of varlist
   dropomit omits omitted variables from stripped r(varlist)
   noisily displays the stripped r(varlist)

Examples:

fvexpand i.foreign =>
r(varlist) : "0b.foreign 1.foreign"

ms_fvstrip i.foreign, expand =>
r(varlist) : "0.foreign 1.foreign"

ms_fvstrip i.foreign, expand dropomit =>
r(varlist) : "1.foreign"
