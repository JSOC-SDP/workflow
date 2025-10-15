#! /bin/csh -f
# the offset clock status task simply reflects the current time offset by a fixed amount
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

cd $WORKFLOW_DATA/gates/$1
set NOW = `date +%Y.%m.%d_%H:%M:%S`
set NOW_t = `$TIME_CONVERT time=$NOW`
@ OLD_t = $NOW_t - 437752800
set OLD = `$TIME_CONVERT s=$OLD_t`
echo $OLD > high
echo $NOW > lastupdate
rm -f statusbusy
