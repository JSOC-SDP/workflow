#! /bin/csh -f
# the offset clock status task simply reflects the current time offset by a fixed amount
set OLD = $1
set OLD_t = `time_convert time=$OLD`
set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
set NOW_t = `time_convert time=$NOW`
@ OFFSET = $NOW_t - $OLD_t
echo $OFFSET
