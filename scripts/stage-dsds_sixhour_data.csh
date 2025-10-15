#! /bin/csh -f

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

echo ACTIONTASK starting $0 $*

set echo

# script to stage dsds data based on DSDS six hour numbers from
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

# Ugh
set TIME_INDEX = time_index

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
set LOW = `$TIME_INDEX time=$WANTLOW -t`
set FSIX = `$TIME_INDEX time=$LOW -6`
set HIGH = `$TIME_INDEX time=$WANTHIGH -t`
set LSIX = `$TIME_INDEX time=$HIGH -6`

show_info -p $product'['$FSIX'-'$LSIX']' -i > show_info.log 

if ($?) then
   echo $0 $* FAILED
   exit 1
endif
