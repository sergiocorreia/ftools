cls
clear all
sysuse auto

sort price 

partition turn
return list
matrix list r(info)

exit


partition turn
return list

partition foreign
return list

matrix list r(info)
