/***************************************************************************************************
To run the script, download the following packages:
ssc install distinct
ssc install reghdfe
ssc install fastxtile
ssc install ftools
***************************************************************************************************/
/* set options */
drop _all
set processors 2 // only have 2 cores on laptop 4
ftools, compile
set matastrict off
set more off

/* create the file to merge with */
//import delimited using merge.csv
use merge.dta
		fegen _id1 = group(id1)
		fegen _id2 = group(id2)
		fegen _id3 = group(id3)
drop id1 id2 id3
rename _id* id*
save merge.dta, replace

/***************************************************************************************************
mata
***************************************************************************************************/
mata: 
	void loop_sum(string scalar y, real scalar first, real scalar last){
		real scalar index, a, obs
		index =  st_varindex(y)
		a = 0
		for (obs = first ; obs <= last ; obs++){
			a = a + _st_data(obs, index) 
		}
	}


mata:
	void loop_generate(string scalar newvar, real scalar first, real scalar last){
		real scalar index, obs
		index = st_addvar("float", newvar)
		for (obs = first ; obs <= last ; obs++){
			st_store(obs, index, 1) 
		}
	}

end

mata:
	void m_invert(string scalar vars){
		st_view(V, ., vars)
		cross(V, V)
	}
end
/***************************************************************************************************

***************************************************************************************************/

/* timer helpers */
cap pr drop Tic
program define Tic
syntax, n(integer)
	timer on `n'
end

cap pr drop Toc
program define Toc
syntax, n(integer) 
	timer off `n'
end

/* benchmark */
cap pr drop benchmark
program define benchmark
	qui {
		local file `0'
		local i 0
		local j 30
		local h 90
		
		/* write and read */
		import delimited using `file'.csv, clear
		save `file'.dta, replace
		
		/* encode strings to int */
		Tic, n(`++h')
		fegen _id1 = group(id1)
		fegen _id2 = group(id2)
		fegen _id3 = group(id3)
		drop id1 id2 id3
		rename _id* id*
		Toc, n(`h')
		save `file', replace

		//use `file', clear
		//keep in 1/100000
		
		
		/* sort  */
		preserve
		
		Tic, n(`++i')
		sort id3
		Toc, n(`i')

		restore, preserve
		
		Tic, n(`++j')
		fsort id3
		Toc, n(`j')

		restore, preserve
		
		Tic, n(`++i')
		sort id6
		Toc, n(`i')

		restore, preserve
		
		Tic, n(`++j')
		fsort id6
		Toc, n(`j')

		restore, preserve

		Tic, n(`++i')
		sort v3
		Toc, n(`i')
		
		restore, preserve

		Tic, n(`++j')
		fsort v3
		Toc, n(`j')
		
		restore, preserve

		Tic, n(`++i')
		sort id1 id2 id3 id4 id5 id6
		Toc, n(`i')

		restore, preserve

		Tic, n(`++j')
		fsort id1 id2 id3 id4 id5 id6
		Toc, n(`j')
		
		
		Tic, n(`++i')
		distinct id3
		Toc, n(`i')

		Tic, n(`++j')
		//distinct id3
		mata: F = factor("id3")
		mata: F.num_levels
		mata: mata drop F
		Toc, n(`j')


		Tic, n(`++i')
		distinct id1 id2 id3, joint
		Toc, n(`i')

		Tic, n(`++j')
		//distinct id1 id2 id3
		mata: F = factor("id1 id2 id3")
		mata: F.num_levels
		mata: mata drop F
		Toc, n(`j')

		
		Tic, n(`++i')
		//duplicates drop id2 id3, force
		Toc, n(`i')

		Tic, n(`++j')
		//duplicates drop id2 id3, force
		// TODO
		Toc, n(`j')

		
		/* merge */
		use `file'.dta, clear
		drop v*
		Tic, n(`++i')
		merge m:1 id1 id3 using merge, keep(master matched) nogen keepusing(v*)
		Toc, n(`i')

		use `file'.dta, clear
		drop v*
		Tic, n(`++j')
		//fmerge m:1 id1 id3 using merge, keep(master matched) nogen v keepusing(v*)
		//set trace off
		join v*, from(merge) by(id1 id3) keep(master matched) assert()  nogenerate
		Toc, n(`j')

		/* functions */

		Tic, n(`++i')
		egen temp = group(id1 id2 id3)
		Toc, n(`i')
		drop temp

		Tic, n(`++j')
		fegen temp = group(id1 id2 id3)
		Toc, n(`j')
		drop temp

		
		/* split apply combine */ 
		Tic, n(`++i')
		egen temp = sum(v3), by(id1)
		Toc, n(`i')
		drop temp

		Tic, n(`++i')
		egen temp = sum(v3), by(id3)
		Toc, n(`i')
		drop temp

		Tic, n(`++i')
		egen temp = mean(v3), by(id6)
		Toc, n(`i')
		drop temp

		Tic, n(`++i')
		egen temp = mean(v3),by(id1 id2 id3)
		Toc, n(`i')
		drop temp

		Tic, n(`++i')
		egen temp = sd(v3), by(id3)
		Toc, n(`i')
		drop temp


		Tic, n(`++j')
		//egen temp = sum(v3), by(id1)
		fcollapse (sum) temp=v3, by(id1) merge fast
		Toc, n(`j')
		drop temp

		Tic, n(`++j')
		//egen temp = sum(v3), by(id3)
		fcollapse (sum) temp=v3, by(id3) merge fast
		Toc, n(`j')
		drop temp

		Tic, n(`++j')
		//egen temp = mean(v3), by(id6)
		fcollapse (mean) temp=v3, by(id6) merge fast
		Toc, n(`j')
		drop temp

		Tic, n(`++j')
		//egen temp = mean(v3),by(id1 id2 id3)
		fcollapse (mean) temp=v3, by(id1 id2 id3) merge fast
		Toc, n(`j')
		drop temp

		Tic, n(`++j')
		//egen temp = sd(v3), by(id3)
		fcollapse (sd) temp=v3, by(id3) merge fast
		Toc, n(`j')
		drop temp

		
		use `file'.dta, clear

		
		Tic, n(`++i')
		collapse (mean) v1 v2 (sum) v3,  by(id1) fast
		Toc, n(`i')

		use `file'.dta, clear


		Tic, n(`++j')
		fcollapse (mean) v1 v2 (sum) v3,  by(id3) fast
		Toc, n(`j')

		use `file'.dta, clear


		Tic, n(`++i')
		collapse (mean) v1 v2 (sum) v3,  by(id1) fast
		Toc, n(`i')

		use `file'.dta, clear

		Tic, n(`++j')
		fcollapse (mean) v1 v2 (sum) v3,  by(id3) fast
		Toc, n(`j')

	}
end

/***************************************************************************************************
Execute program
***************************************************************************************************/

timer clear
benchmark 2e6
timer list

timer clear
benchmark 1e7
timer list

//timer clear
//benchmark 1e8
//timer list

