clear all
cls
set more off

set obs 200000

gen long id = floor(runiform() * 10000)
forv i=1/5	 {
	gen x`i' = runiform()
}

timer clear

cap ado uninstall ftools
net install ftools, from("c:\git\ftools\src")

ftools, compile

mata:
mata set matastrict on
real colvector aggregate_panelsum(class Factor F, real vector data, real vector weights)
{
	return(length(weights) ? panelsum(data, weights, F.info) : panelsum(data, F.info))
	//return(panelsum(data, F.info))
}
end


preserve

forv i=1/5 {
	timer on 1
	fcollapse (sum) x*, by(id) fast v
	timer off 1

	restore, preserve

	timer on 2
	fcollapse (panelsum) x*, by(id) fast v register(panelsum)
	timer off 2

	restore, preserve
}

timer list

exit

mata: F = factor("id")
mata: data = F.sort(st_data(., "x*"))
mata: ans = panelsum(data, 1, F.info)
