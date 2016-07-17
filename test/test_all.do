cap log close _all
log using benchmarks, replace

do test_mata
do test_stata
do benchmark

do test_fcollapse
do test_fsort

log off
log close _all
exit
