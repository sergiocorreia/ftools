pr drop _all
clear all
set more off
set matadebug off
include "test_utils.do"
cls

// -------------------------
// Test egen internal command
	sysuse auto, clear

	egen long id0 = group(turn) if foreign
	fegen_group if foreign, name(id1) args(turn)
	fegen id2 = group(turn) if foreign
	assert id0 == id1
	assert id0 == id2
	drop id*

	egen long id0 = group(turn)
	fegen_group, name(id1) args(turn)
	fegen id2 = group(turn)
	assert id0 == id1
	assert id0 == id2
	drop id*

	egen long id0 = group(trunk foreign)
	fegen_group, name(id1) args(trunk foreign)
	fegen id2 = group(trunk foreign)
	assert id0 == id1
	assert id0 == id2
	drop id*

// -------------------------
// Test Stata part

	sysuse auto, clear
	loc vars turn foreign
	egen id1 = group(`vars')
	fegen id2 = group(`vars')
	fegen id3 = group(`vars'), method(mata)
	assert id1 == id2
	assert id1 == id3

	sysuse auto, clear
	loc vars m
	gen m = substr(make, 1, 2)
	egen id1 = group(`vars')
	fegen id2 = group(`vars')
	fegen id3 = group(`vars'), method(mata)
	assert id1 == id2
	assert id1 == id3

	sysuse auto, clear
	loc vars m for
	gen m = substr(make, 1, 2)
	egen id1 = group(`vars')
	fegen id2 = group(`vars')
	fegen id3 = group(`vars'), method(mata)
	assert id1 == id2
	assert id1 == id3

	sysuse auto, clear
	loc vars m for
	gen m = substr(make, 1, 2)
	egen id1 = group(`vars') if !foreign
	fegen id2 = group(`vars') if !foreign
	assert id1 == id2

exit
