#! /bin/csh -f
# the offset clock status task simply reflects the current time offset by a fixed amount
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set OLD = $1
set OLD_t = `TIME_CONVERT time=$OLD`
set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
set NOW_t = `TIME_CONVERT time=$NOW`
@ OFFSET = $NOW_t - $OLD_t
echo $OFFSET
