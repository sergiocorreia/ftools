**** Example ****
* Alternative implementation of -unique- (count number of unique values)

* Setup
cap ado uninstall unique
ssc install unique
cap ado uninstall ftools
net install ftools, from(https://github.com/sergiocorreia/ftools/raw/master/src/)
ftools, compile

clear
sysuse auto

unique turn

mata:
	f = factor("turn")
	f.num_levels, f.num_obs
end


**** Benchmark ****
clear
set obs 10000000
gen byte id = ceil(runiform()*10)

timer clear
timer on 1
unique id
timer off 1
timer on 2
mata:
	f = factor("id")
	f.num_levels, f.num_obs
end
timer off 2

timer on 3
tab id
timer off 3

timer on 4
mata:
	f = factor("id", "", ., "", 0, 0)
	f.num_levels, f.num_obs
end
timer off 4

**** Results ****
timer list
/*
. timer list
1:	31.92	/	1	=	31.9160
2:	3.70	/	1	=	3.7000
3:	1.38	/	1	=	1.3750
4:	0.69	/	1	=	0.6940
*/

* Summary:
* ftools is 10x faster than unique, but still slower than a simple tab
* with the optimization flags is faster though...
exit
