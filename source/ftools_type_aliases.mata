// Type aliases --------------------------------------------------------------
	local Boolean 				real scalar
	local Integer 				real scalar
	local Real 					real scalar
	local Vector				real colvector
	local RowVector				real rowvector
	local Matrix				real matrix
	local Variable				real colvector	// N*1
	local Variables				real matrix		// N*K
	local String 				string scalar	// Arbitrary string
	local Varname 				string scalar
	local Varlist 				string rowvector // used after tokens()
	local StringVector			string colvector
	local StringRowVector		string rowvector
	local StringMatrix			string matrix
	local Anything				transmorphic matrix
	local DataFrame				transmorphic matrix
	local DataRow				transmorphic rowvector
	local DataCol				transmorphic colvector
	local Dict					transmorphic scalar
	local Factor				class Factor scalar
