#! /bin/csh -f
# the offset clock status task simply reflects the current time offset by a fixed amount

set WFDIR = $WORKFLOW_DATA

cd $WFDIR/gates/$1
set NOW = `date +%Y.%m.%d_%H:%M:%S`
set NOW_t = `time_convert time=$NOW`
@ OLD_t = $NOW_t - 437752800
set OLD = `time_convert s=$OLD_t`
echo $OLD > high
echo $NOW > lastupdate
rm -f statusbusy
