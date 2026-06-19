#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

echo ACTIONTASK starting $0 $*

set echo

# script to stage dsds data based on DSDS day numbers from
# WANTLOW and WANTHIGH which are times


# get calling parameters from task instance directory

set WD = $cwd
if (!(-e ticket)) then
    echo FAILURE in $0, NO ticket
    echo Current Dir is $WD
    exit 1
endif

foreach ATTR (TYPE WANTLOW WANTHIGH)
     set ATTRVAL = `grep $ATTR ticket`
     if ($#ATTRVAL) set $ATTRVAL
end

set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set WANTLOW_t = `$TIME_CONVERT time=$WANTLOW`
set WANTLOW = `$TIME_CONVERT zone=TAI s=$WANTLOW_t`
set WANTHIGH_t = `$TIME_CONVERT time=$WANTHIGH`
set WANTHIGH = `$TIME_CONVERT zone=TAI s=$WANTHIGH_t`

set SPECIAL = `grep SPECIAL ticket`
foreach SPEC ($SPECIAL)
     if ($#SPEC) set $SPEC
end

# This cwd is the taskid dir.  The product name can be found in the associated
# gate dir.  Follow the tree back to the gate.

set gate = `cat ../../target`
set product = `cat $WORKFLOW_DATA/gates/$gate/product`
 
# UGH
# time_index is not in DRMS
# FIX times for DSDS time_index
set LOW = `time_index time=$WANTLOW -t`
set FDAY = `time_index time=$LOW -d`
set HIGH = `time_index time=$WANTHIGH -t`
set LDAY = `time_index time=$HIGH -d`

show_info -p $product'['$FDAY'-'$LDAY']' -i > show_info.log 

if ($?) then
   echo $0 $* FAILED
   exit 1
endif

