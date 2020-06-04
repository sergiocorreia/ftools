cap log close _all
log using benchmarks, replace

*do test_fmerge_recast // DISABLED UNTIL FIX

do test_mata
do test_stata
do test_fcollapse
do test_flevelsof

*do test_join
do test_join_bugs1
do test_join_bugs2

do benchmark

do benchmark_fcollapse
do test_fsort

log off
log close _all
exit
