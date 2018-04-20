clear all
cls
reghdfe, reload
pr drop _all

sysuse auto
set more off
cls

sysuse auto
keep if trunk == 11
keep make price headroom foreign
order foreign make
su price if foreign // 4951.75
su price // 4715.875

sort foreign
list, sepby(foreign)

fcollapse (mean) avg_p=price avg_h=headroom, by(foreign) merge fast
list, sepby(foreign)
de avg_p avg_h price head // avg_* must now be double

fcollapse (mean) price headroom, by(foreign) append fast
fcollapse (mean) price headroom, append fast
format %12.3fc price headroom

gsort foreign -make
list, sepby(foreign)

exit
