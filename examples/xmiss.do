**** Example ****
* Alternative implementation of -xmiss- (count missing values per variable)

* Setup
cap ado uninstall xmiss
ssc install xmiss
cap ado uninstall ftools
net install ftools, from(https://github.com/sergiocorreia/ftools/raw/master/src/)
ftools, compile

clear
sysuse nlsw88

xmiss race union

mata:
	f = factor("race")
	mask = rowmissing(st_data(., "union"))
	f.panelsetup()
	missings = panelsum(f.sort(mask), f.info)
	missings, f.counts
end


**** Benchmark ****
clear
set obs 10000000
gen byte id = ceil(runiform()*10)
gen y = rnormal() if runiform() > 0.1

timer clear
timer on 1
xmiss id y
timer off 1
timer on 2
mata:
	f = factor("id")
	mask = rowmissing(st_data(., "y"))
	f.panelsetup()
	missings = panelsum(f.sort(mask), f.info)
	missings, f.counts
end
timer off 2

timer on 3
bysort id: missings report y, percent
timer off 3


**** Results ****
timer list
/*
. timer list
   1:     67.29 /        1 =      67.2880
   2:      7.92 /        1 =       7.9170
*/

exit
