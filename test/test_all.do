cap log close _all
log using benchmarks, replace

do test_mata
do test_stata
do test_fcollapse
do test_flevelsof
do test_bug_join

do benchmark

do benchmark_fcollapse
do test_fsort

log off
log close _all
exit
