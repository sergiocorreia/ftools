* -collapse- benchmark
* based on:
* https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping

clear all
cap cls
set more off
timer clear
set trace off
log close _all
log using bench_collapse, replace

* Prepare data

discard
cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, compile


cap pr drop crData
program define crData
	args N K
	loc N = `N'
	clear
	set obs `N'
	gen int id1 = ceil(runiform()*`K')
	gen int id2 = ceil(runiform()*`K')
	gen int id3 = ceil(runiform()*`K'/`N')
	gen str5 id5 = "x" + string(ceil(runiform()*`K'))
	gen byte v1 = ceil(runiform()*5)
	gen byte v2 = ceil(runiform()*5)
	gen double v3 = runiform()
end

timer clear
loc sizes 1e3 1e4 1e5 1e6 // 1e7 1e8
loc sizes 1e7

loc K 100
loc i 0
loc by id1 id2 // uses hash0 so after 100k obs we're faster
//loc by id5 // uses hash1 (strinG) so only after 1mm obs we're faster

foreach size of local sizes {
	//di as error "SIZE = `size'"
	loc ++i
	crData `size' `K'

	preserve

	timer on 1`i'
	collapse (sum) v1, by(`by') fast
	timer off 1`i'
	
	restore, preserve
	timer on 3`i'
	fcollapse (sum) v1, by(`by') fast v
	timer off 3`i'
	
	restore, preserve
	timer on 5`i'
	gcollapse (sum) v1, by(`by') fast v
	timer off 5`i'
	
	restore, preserve
	timer on 2`i'
	collapse (sum) v1, by(`by') fast
	timer off 2`i'
	su

	restore, preserve
	timer on 4`i'
	fcollapse (sum) v1, by(`by') fast v
	timer off 4`i'
	su
	
	restore, preserve
	timer on 6`i'
	gcollapse (sum) v1, by(`by') fast v
	timer off 6`i'
	su
	
	restore, not
	
	timer list // interim
}
timer list
log close _all
exit


/* RESULTS:

Obs (1000s)	coll (ms)	fcoll (ms)
      1		      3   		17   
     10			 19   		31   
    100			124   		96   
  1,000		  1,350   	   579   
 10,000		 18,844   	 6,087   
100,000		243,817   	74,038   

- At 100k obs, fcollapse is already faster than collapse
- At 10m obs, fcollapse is 3x faster (3.3x at 100m obs)

*/
