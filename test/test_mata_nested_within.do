cap ado uninstall ftools
net install ftools, from("C:/git/ftools/src")
ftools, check
ftools, compile

cls
clear all
discard
sysuse auto
gen TURN = turn
gen c = 1

mata:
F = factor("turn")
data = st_data(., "TURN")
assert(F.nested_within(data))

F = factor("turn trunk")
data = st_data(., "TURN")
assert(F.nested_within(data))

F = factor("trunk turn")
data = st_data(., "TURN")
assert(F.nested_within(data))

F = factor("trunk")
data = st_data(., "TURN")
assert(!F.nested_within(data))

F = factor("trunk")
data = st_data(., "c")
assert(F.nested_within(data))

F = factor("c")
data = st_data(., "turn")
assert(!F.nested_within(data))

F = factor("c")
data = st_data(., "c")
assert(F.nested_within(data))

F = factor("make")
data = st_sdata(., "make")
assert(F.nested_within(data))
end

exit
