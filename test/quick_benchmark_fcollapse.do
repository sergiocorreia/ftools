* Quick benchmark for the -compress- option of fcollapse

loc N = 1e6 * 10

* Num of obs:
di %12.0fc `N'

set trace off
clear all
cls

* Warmup
sysuse auto
collapse (sum) price, by(turn)
fcollapse (sum) price, by(turn)
gcollapse (sum) price, by(turn)
clear
cls

set obs `N'
gen float x = int(runiform()*1000)
gen float y = int(runiform())
gen long id = int(runiform()*100) // 100 or 100k groups

set rmsg on

* Benchmark
preserve
collapse (count) n=x (max) max_x=x max_y=y (min) min_x=x min_y=y (sum) x y, by(id) fast
su
de
mata: x = hash1(st_data(., .))
restore, preserve

* Faster
fcollapse (count) n=x (max) max_x=x max_y=y (min) min_x=x min_y=y (sum) x y, by(id) fast nocompress
compress
su
de
restore, preserve

* Save space
fcollapse (count) n=x (max) max_x=x max_y=y (min) min_x=x min_y=y (sum) x y, by(id) fast compress
compress
su
de
mata: assert(x==hash1(st_data(., .)))
restore, preserve

* Benchmark w/gcollapse
gcollapse (count) n=x (max) max_x=x max_y=y (min) min_x=x min_y=y (sum) x y, by(id) fast
su
de
mata: assert(x==hash1(st_data(., .)))


exit

* TIME AND MEMORY OF FINAL DATASET, BY COMMAND:

* 1mm obs and 100 categories +-+-
**************************************************
* collapse:						5.20s	3.774b
* fcollapse, nocompress			0.62s	3,774b
* fcollapse, compress			0.63s	1,530b
* gcollapse						0.28s	3,774b

* 10mm obs and 100k categories
**************************************************
* collapse:						47.25s	4,000,000b
* fcollapse, nocompress			10.04s	4,000,000b
* fcollapse, compress			 8.65s	1,700,000b
* gcollapse						 4.05s	4,000,000b
