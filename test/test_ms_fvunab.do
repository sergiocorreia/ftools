cls
clear all
set more off

sysuse auto
ms_fvunab F2.pri   tu##c.L.trun#ibn.foreign (pri	= tu##for#c.pri) weigh
sreturn list
	
ms_fvunab FE=turn#tru, target
sreturn list

ms_fvunab pri tru#turn#fo A=ibn.pri, noi target
sreturn list

ms_fvunab make            turn, noi stringok
sreturn list

exit
