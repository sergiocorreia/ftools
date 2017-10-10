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


gen x = ""
levelsof x, loc(old)
flevelsof x, force loc(new)
assert r(num_levels)==0
assert (`"`old'"'==`"`new'"')

levelsof x, loc(old) missing
flevelsof x, force loc(new) missing
assert r(num_levels)==1
assert (`"`old'"'==`"`new'"')


gen y = .
levelsof y, loc(old)
flevelsof y, force loc(new)
assert r(num_levels)==0
assert (`"`old'"'==`"`new'"')

levelsof y, loc(old) missing
flevelsof y, force loc(new) missing
assert r(num_levels)==1
assert (`"`old'"'==`"`new'"')

levelsof turn if 0, loc(old)
return list
flevelsof turn if 0, force loc(new)
return list
assert r(num_levels)==0
di `"<`old'==`new'>"'
assert (`"`old'"'==`"`new'"')



exit
