#! /bin/csh -f
# the offset clock status task simply reflects the current time offset by a fixed amount

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

cd $WORKFLOW_DATA/gates/$1
set NOW = `date +%Y.%m.%d_%H:%M:%S`
set NOW_t = `$TIME_CONVERT time=$NOW`
@ OLD_t = $NOW_t - 437752800
set OLD = `$TIME_CONVERT s=$OLD_t`
echo $OLD > high
echo $NOW > lastupdate
rm -f statusbusy
