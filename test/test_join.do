* Setup

	clear all

/*	cap cls
	set more off
	timer clear

	discard
	cap ado uninstall ftools
	net install ftools, from("C:/git/ftools/src")
	ftools, compile
*/

* Create -using- dataset

	tempfile uuu uuu_short uuu_alt
	clear
	set obs 6
	
	gen byte foreign = ceil(_n / 2) - 1
	bys foreign: gen year = _n
	
	gen long xrate = foreign * 100 + year
	format %6.1f xrate
	
	gen long rand1 = ceil(runiform()*100000)
	la var rand1 "RANDOM()"
	gen long rand2 = ceil(runiform()*100000)
	
	gen byte bool = ceil(runiform())
	la def yesno 0 no 1 yes
	la val bool yesno

	gen byte const = 1
	note const: First note
	note const: Second note
	char const[somechar] A character
	char _dta[somechar] A dta char
	note: A dta note
	save "`uuu'", orphans

	drop if year != 1 // remove
	save "`uuu_short'", orphans

	use "`uuu'", clear
	gen long xrate2 = xrate * 100
	keep foreign year xrate2
	isid foreign year
	gen long idx = _n
	save "`uuu_alt'", orphans

* Create -master- dataset

	tempfile mmm mmm_short
	sysuse auto, clear
	replace foreign = 3 in 1
	gen long idx = _n
	gen byte d = 1
	char foreign[achar] "A foreign char"
	note foreign: note1!
	note foreign: note2!
	save "`mmm'"
	
	drop make
	save "`mmm_short'"

*  m:1 merge

	* benchmark
	use "`mmm'", clear
	merge m:1 for* using "`uuu_short'", keepus(xrate bool rand1) keep(match using)
	order bool, after(xrate) // reorder b/c merge ignores order in -keepusing-
	order rand1, after(bool)
	sort idx // sort back b/c merge undoes previous sort
	de
	mata: bench_hash = hash1(st_data(., .))

	* keep(match using)
	use "`mmm'", clear
	join xrate bool rand1, by(for*) from("`uuu_short'") keep(match using)
	mata: assert(bench_hash == hash1(st_data(., .)))

	* -if-
	use "`mmm'", clear
	join xrate bool rand1, by(for*) from("`uuu'" if year==1) keep(match using)
	mata: assert(bench_hash == hash1(st_data(., .)))

	* different -by- writing
	use "`mmm'", clear
	join xrate bool rand1, by(forei) from("`uuu_short'") keep(match using)
	mata: assert(bench_hash == hash1(st_data(., .)))

	* into()
	use "`uuu'" if year==1, clear
	keep xrate bool rand1 foreign
	order rand1, after(bool)
	join, by(foreign) into("`mmm'") keep(match using)
	de
	mata: assert(bench_hash == hash1(st_data(., .)))


	* 1:1
	use "`uuu_alt'", clear
	merge 1:1 foreign year using "`uuu_short'"
	sort idx // sort back b/c merge undoes previous sort
	mata: bench_hash = hash1(st_data(., .))

	use "`uuu_alt'", clear
	join, by(foreign year) from("`uuu_short'") uniquemaster
	mata: assert(bench_hash == hash1(st_data(., .)))

	use "`uuu_short'", clear
	join, by(foreign year) into("`uuu_alt'") uniquemaster
	mata: assert(bench_hash == hash1(st_data(., .)))

	* 1:1
	use "`uuu_alt'", clear
	merge 1:1 foreign year using "`uuu'"
	sort idx // sort back b/c merge undoes previous sort
	mata: bench_hash = hash1(st_data(., .))

	use "`uuu_alt'", clear
	join, by(foreign year) from("`uuu'") uniquemaster
	mata: assert(bench_hash == hash1(st_data(., .)))

	use "`uuu'", clear
	join, by(foreign year) into("`uuu_alt'") uniquemaster
	mata: assert(bench_hash == hash1(st_data(., .)))

	* 1:1
	use "`uuu_short'", clear
	gen long short_idx = _n
	merge 1:1 foreign year using "`uuu_alt'"
	sort short_idx // sort back b/c merge undoes previous sort
	drop short_idx
	mata: bench_hash = hash1(st_data(., .))

	use "`uuu_short'", clear
	join, by(foreign year) from("`uuu_alt'") uniquemaster
	mata: assert(bench_hash == hash1(st_data(., .)))

	use "`uuu_alt'", clear
	join, by(foreign year) into("`uuu_short'") uniquemaster
	mata: assert(bench_hash == hash1(st_data(., .)))


	* check with and without notes
	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") keep(match using)
	char list
	mata: assert(st_global("_dta[note2]")=="A dta note")
	mata: assert(st_global("const[note1]")=="First note")
	mata: assert(st_global("const[note2]")=="Second note")

	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") keep(match using) nonote
	mata: assert(st_global("_dta[note2]")=="")
	mata: assert(st_global("const[note1]")=="")
	mata: assert(st_global("const[note2]")=="")

	* check var labels and formats
	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") keep(match using) nolab nonotes
	mata: assert(st_varlabel("rand1")=="RANDOM()")
	mata: assert(st_varformat("xrate")=="%6.1f")
	mata: assert(st_varvaluelabel("bool")=="yesno")

	* check with and without val labels
	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") keep(match using)  nol
	mata: st_vlload("yesno", values=., text="")
	mata: assert(values==J(0,1,.))
	mata: assert(text==J(0,1,""))

	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") keep(match using)  nonote
	mata: st_vlload("yesno", values=., text="")
	mata: assert(values==(0,1)')
	mata: assert(text==("no", "yes")')

	* check _merge
	use "`mmm'", clear
	join, by(for*) from("`uuu_short'")
	conf var _merge

	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") nogen
	conf new var _merge

	use "`mmm'", clear
	join, by(for*) from("`uuu_short'") gen("_merge2")
	conf var _merge2

	* keep(variants)
	loc keeps `" "master" "match" "using" "master using" "master match" "" "master using match" "1 3 2" "using 1" "'
	foreach keep of local keeps {
		di as text "{bf:keep(`keep')}"
		qui use "`mmm'", clear
		merge m:1 for* using "`uuu_short'", keep(`keep') norep
		sort idx // sort back b/c merge undoes previous sort
		mata: bench_hash = hash1(st_data(., .))

		qui use "`mmm'", clear
		join, by(for*) from("`uuu_short'") keep(`keep') norep
		mata: assert(bench_hash == hash1(st_data(., .)))
	}

	* assert(variants)
	loc asserts `" "master" "match" "using" "master using" "match using" "master match" "" "master using match" "1 3 2" "using 1" "'
	foreach assert of local asserts {
		di as text "{bf:assert(`assert')}"
		qui use "`mmm'", clear
		cap noi merge m:1 for* using "`uuu_short'", assert(`assert') norep
		sort idx
		loc bench_rc = _rc
		mata: bench_hash = hash1(st_data(., .))
		di as text "---"

		qui use "`mmm'", clear
		cap noi join, by(for*) from("`uuu_short'") assert(`assert') norep
		if (c(rc)) {
			di as text "(checking if bench also gave error)"
			assert `bench_rc' 
		}
		else {
			di as text "(no error in join(); comparing results with bench)"
			mata: assert(bench_hash == hash1(st_data(., .)))
		}
		di as text "(ok)"
		di as text "==========="
	}


di as text "ALL TESTS SUCCESFUL!"
exit
