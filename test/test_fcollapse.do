noi cscript "ftools: fcollapse simple usage" adofile fcollapse

* [TEST] Simple collapse
	sysuse auto, clear
	collapse (sum) price, by(turn)
	mata: X = st_data(., .)

	sysuse auto, clear
	fcollapse (sum) price, by(turn)
	mata: Y = st_data(., .)
	mata: assert(X==Y)

* [TEST] Complex collapse
	sysuse auto, clear
	collapse (sum) x=price y=length (mean) gear, by(turn foreign)
	mata: X = st_data(., .)

	sysuse auto, clear
	fcollapse (sum) x=price y=length (mean) gear, by(turn foreign)
	mata: Y = st_data(., .)
	mata: assert(mreldif(X, Y) <= 1e-6)


* [TEST] Complex collapse w/ freq. weights
	sysuse auto, clear
	collapse (sum) x=price y=length (mean) gear (max) length (median) disp [fw=trunk], by(turn foreign)
	mata: X = st_data(., .)

	sysuse auto, clear
	fcollapse (sum) x=price y=length (mean) gear (max) length (median) disp [fw=trunk], by(turn foreign)
	mata: Y = st_data(., .)
	mata: assert(mreldif(X, Y) <= 1e-7)

* [TEST] Complex collapse w/ prob. weights
	sysuse auto, clear
	collapse (sum) x=price y=length (mean) gear (max) length (median) disp [pw=trunk], by(turn foreign)
	mata: X = st_data(., .)

	sysuse auto, clear
	fcollapse (sum) x=price y=length (mean) gear (max) length (median) disp [pw=trunk], by(turn foreign)
	mata: Y = st_data(., .)
	mata: assert(mreldif(X, Y) <= 1e-7)

* [TEST] Collapse w/ missings
	sysuse auto, clear
	collapse (sum) rep (mean) x=rep (max) y=rep, by(turn foreign)
	mata: X = st_data(., .)

	sysuse auto, clear
	fcollapse (sum) rep (mean) x=rep (max) y=rep, by(turn foreign)
	mata: Y = st_data(., .)
	mata: assert(mreldif(X, Y) <= 1e-7)

* [TEST] Collapse w/ merge
	sysuse auto, clear
	egen double x = max(price), by(turn)
	egen double y = mean(rep), by(turn)
	egen double z = median(weight), by(turn)
	keep turn x y z
	mata: X = st_data(., .)

	sysuse auto, clear
	fcollapse (max) x=price (mean) y=rep (median) z=weight, by(turn) merge
	keep turn x y z
	mata: Y = st_data(., .)
	// mata: X, Y
	mata: assert(mreldif(X, Y) <= 1e-7)

exit
