reghdfe, reload
clear all
cls
sysuse auto, clear

ms_add_comma, loc(cmd) cmd("tab turn") opt()
di as text `"`cmd'"'
_assert `"`cmd'"' == "tab turn"

ms_add_comma, loc(cmd) cmd("tab turn") opt("sort")
di as text `"`cmd'"'
_assert `"`cmd'"' == "tab turn, sort"

ms_add_comma, loc(cmd) cmd("tab turn, nolabel") opt("sort")
di as text `"`cmd'"'
_assert `"`cmd'"' == "tab turn, nolabel sort"

ms_add_comma, loc(cmd) cmd(`"tab turn, nolabel bar(123) spam(`"asd"')"') opt(`"sort foo("bar")"')
di as text `"`cmd'"'
_assert `"`cmd'"' == `"tab turn, nolabel bar(123) spam(`"asd"') sort foo("bar")"'

