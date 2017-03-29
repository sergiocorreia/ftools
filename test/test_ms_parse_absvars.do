// --------------------------------------------------------------------------
// Test a list of valid absvars
// --------------------------------------------------------------------------
clear all
cls
set trace off
set more off


sysuse auto, clear
set more off

mata:
string matrix clean_tokens(string scalar vars)
{
	string colvector ans
	real scalar i
	ans = tokens(vars)
	for (i=1; i<=cols(ans); i++) {
		ans[i] = invtokens(tokens(ans[i]))
	}
	return(ans)
}

end


local absvar1		turn
local G_1			1
mata: ivars_1 = ("turn")
mata: cvars_1 = ""
mata: target_1 = ""
mata: inter_1 = (1)
mata: numsl_1 = (0)

local absvar2		i.turn
local G_2			1
mata: ivars_2 = ("turn")
mata: cvars_2 = ""
mata: target_2 = ""
mata: inter_2 = (1)
mata: numsl_2 = (0)

local absvar3		tur
local G_3			1
mata: ivars_3 = ("turn")
mata: cvars_3 = ""
mata: target_3 = ""
mata: inter_3 = (1)
mata: numsl_3 = (0)

local absvar4		i.turn trunk
local G_4			2
mata: ivars_4 = ("turn", "trunk")
mata: cvars_4 = ("", "")
mata: target_4 = ("", "")
mata: inter_4 = (1, 1)
mata: numsl_4 = (0, 0)

local absvar5		trunk i.turn
local G_5			2
mata: ivars_5 = ("trunk", "turn")
mata: cvars_5 = ("", "")
mata: target_5 = ("", "")
mata: inter_5 = (1, 1)
mata: numsl_5 = (0, 0)

local absvar6		turn#trunk
local G_6			1
mata: ivars_6 = ("turn trunk")
mata: cvars_6 = ("")
mata: target_6 = ""
mata: inter_6 = (1)
mata: numsl_6 = (0)

local absvar7		i.turn#trunk
local G_7			1
mata: ivars_7 = ("turn trunk")
mata: cvars_7 = ("")
mata: target_7 = ""
mata: inter_7 = (1)
mata: numsl_7 = (0)

local absvar8		turn#i.trunk
local G_8			1
mata: ivars_8 = ("turn trunk")
mata: cvars_8 = ("")
mata: target_8 = ""
mata: inter_8 = (1)
mata: numsl_8 = (0)

local absvar9		i.turn#i.trunk
local G_9			1
mata: ivars_9 = ("turn trunk")
mata: cvars_9 = ("")
mata: target_9 = ""
mata: inter_9 = (1)
mata: numsl_9 = (0	)

local absvar10		i.turn#foreign#trunk
local G_10			1
mata: ivars_10 = ("turn foreign trunk")
mata: cvars_10 = ("")
mata: target_10 = ""
mata: inter_10 = (1)
mata: numsl_10 = (0)

local absvar11		turn for trunk disp mpg
local G_11			5
mata: ivars_11 = ("turn", "foreign", "trunk", "displacement", "mpg")
mata: cvars_11 = ("", "", "", "", "")
mata: target_11 = ("", "", "", "", "")
mata: inter_11 = (1, 1, 1, 1, 1)
mata: numsl_11 = (0, 0, 0, 0, 0)

local absvar12		turn trunk#c.gear
local G_12			2
mata: ivars_12 = ("turn", "trunk")
mata: cvars_12 = ("", "gear_ratio")
mata: target_12 = ("", "")
mata: inter_12 = (1, 0)
mata: numsl_12 = (0, 1)

local absvar13		turn trunk##c.gear
local G_13			2
mata: ivars_13 = ("turn", "trunk")
mata: cvars_13 = ("", "gear_ratio")
mata: target_13 = ("", "")
mata: inter_13 = (1, 1)
mata: numsl_13 = (0, 1)

local absvar14		turn foreign trunk#c.(gear)
local G_14			3
mata: ivars_14 = ("turn", "foreign", "trunk")
mata: cvars_14 = ("", "", "gear_ratio")
mata: target_14 = ("", "", "")
mata: inter_14 = (1, 1, 0)
mata: numsl_14 = (0, 0, 1)

local absvar15		turn##c.(gear weight)
local G_15			1
mata: ivars_15 = ("turn")
mata: cvars_15 = ("gear_ratio weight")
mata: target_15 = ""
mata: inter_15 = (1)
mata: numsl_15 = (2)

local absvar16		turn trunk#c.(gear weight length)
local G_16			2
mata: ivars_16 = ("turn", "trunk")
mata: cvars_16 = ("", "gear_ratio weight length")
mata: target_16 = ("", "")
mata: inter_16 = (1, 0)
mata: numsl_16 = (0, 3)

local absvar17		turn trunk#c.(gear weight length) foreign
local G_17			3
mata: ivars_17 = ("turn", "trunk", "foreign")
mata: cvars_17 = ("", "gear_ratio weight length", "")
mata: target_17 = ("", "", "")
mata: inter_17 = (1, 0, 1)
mata: numsl_17 = (0, 3, 0)

local absvar18		turn c.(gear weight length)#trunk
local G_18			2
mata: ivars_18 = ("turn", "trunk")
mata: cvars_18 = ("", "gear_ratio weight length")
mata: target_18 = ("", "")
mata: inter_18 = (1, 0)
mata: numsl_18 = (0, 3)

local absvar19		turn c.(gear weight length)#i.trunk
local G_19			2
mata: ivars_19 = ("turn", "trunk")
mata: cvars_19 = ("", "gear_ratio weight length")
mata: target_19 = ("", "")
mata: inter_19 = (1, 0)
mata: numsl_19 = (0, 3)

local absvar20		turn (c.gear c.weight c.length)#trunk
local G_20			2
mata: ivars_20 = ("turn", "trunk")
mata: cvars_20 = ("", "gear_ratio weight length")
mata: target_20 = ("", "")
mata: inter_20 = (1, 0)
mata: numsl_20 = (0, 3)

local absvar21		turn trunk#c.gear foreign##c.(weight length)
local G_21			3
mata: ivars_21 = ("turn", "trunk", "foreign")
mata: cvars_21 = ("", "gear_ratio", "weight length")
mata: target_21 = ("", "", "")
mata: inter_21 = (1, 0, 1)
mata: numsl_21 = (0, 1, 2)

local absvar22		FE1=turn foreign FE3=trunk
local G_22			3
mata: ivars_22 = ("turn", "foreign", "trunk")
mata: cvars_22 = ("", "", "")
mata: target_22 = ("", "", "")
mata: inter_22 = (1, 1, 1)
mata: numsl_22 = (0, 0, 0)
mata: target_22 = ("FE1", "", "FE3")

local absvar23		turn FE=foreign#c.gear
local G_23			2
mata: ivars_23 = ("turn", "foreign")
mata: cvars_23 = ("", "gear_ratio")
mata: target_23 = ("", "FE_Slope1")
mata: inter_23 = (1, 0)
mata: numsl_23 = (0, 1)

local absvar24		turn FE=foreign#c.(gear length)
local G_24			2
mata: ivars_24 = ("turn", "foreign")
mata: cvars_24 = ("", "gear_ratio length")
mata: target_24 = ("", "FE_Slope1 FE_Slope2")
mata: inter_24 = (1, 0)
mata: numsl_24 = (0, 2)

local absvar25		turn foreign, savefe
local G_25			2
local savefe_25 	1
mata: ivars_25 = ("turn", "foreign")
mata: cvars_25 = ("", "")
mata: target_25 = ("__hdfe1__", "__hdfe2__")
mata: inter_25 = (1, 1)
mata: numsl_25 = (0, 0)

local absvar26		FE1 = turn foreign FE3 = trunk
local G_26			3
mata: ivars_26 = ("turn", "foreign", "trunk")
mata: cvars_26 = ("", "", "")
mata: target_26 = ("FE1", "", "FE3")
mata: inter_26 = (1, 1, 1)
mata: numsl_26 = (0, 0, 0)

local absvar27		"FE1 	=	 turn foreign FE3	=trunk"
local G_27			3
mata: ivars_27 = ("turn", "foreign", "trunk")
mata: cvars_27 = ("", "", "")
mata: target_27 = ("FE1", "", "FE3")
mata: inter_27 = (1, 1, 1)
mata: numsl_27 = (0, 0, 0)



// --------------------------------------------------------------------------

set trace off
forval i = 1/30 {
	local absvar `absvar`i''
	if ("`absvar'"=="") continue
	di as input "[`i'] `absvar'"
	ms_parse_absvars `absvar'
	sreturn list

	local G = `G_`i''
	_assert `s(G)'==`G', msg("s(G)=`s(G)', expected `G'")
	di as text "x1 " _c
	mata: assert(tokens(`"`s(ivars)'"') == ivars_`i')
	di as text "x2 " _c	
	mata: assert(tokens(`"`s(cvars)'"') == cvars_`i')
	di as text "x3 " _c
	mata: assert(clean_tokens(`"`s(targets)'"') == target_`i')
	di as text "x4 " _c
	mata: assert(strtoreal(tokens(`"`s(intercepts)'"')) == inter_`i')
	di as text "x5 "	
	mata: assert(strtoreal(tokens(`"`s(num_slopes)'"')) == numsl_`i')
}
exit
