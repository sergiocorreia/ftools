clear
sysuse auto

gen double asd = int(runiform()*100000000)

flevelsof turn, sep("-") loc(new) force
levelsof turn, sep("-") loc(old)
assert ("`old'"=="`new'")

levelsof asd in 1/5
flevelsof asd in 1/5, force
assert (`"`old'"'==`"`new'"')

levelsof make in 1/5, sep("-") clean
flevelsof make in 1/5, sep("-") clean force
assert (`"`old'"'==`"`new'"')

exit
