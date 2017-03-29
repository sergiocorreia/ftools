
* Setup
	cap cls
	clear all
	discard
	pr drop _all

* Some examples
	ms_get_version regress // *! version ... (SYNTAX A)
	di as text "`package_version'"
	
	ms_get_version ivreg2 // *! ivreg2 ... (SYNTAX B)
	di as text "`package_version'"

	ms_get_version reghdfe // *! version ... (SYNTAX A)
	di as text "`package_version'"

	cap noi ms_get_version foobar // program does not exist
	cap noi ms_get_version ms_get_version // no version

exit
