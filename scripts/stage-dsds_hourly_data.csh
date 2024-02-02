#! /bin/csh -f

echo ACTIONTASK starting $0 $*

set echo

# script to stage dsds data based on DSDS hour numbers from
# WANTLOW and WANTHIGH which are times

set echo

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
set FHOUR = `time_index time=$LOW -h`
set HIGH = `time_index time=$WANTHIGH -t`
set LHOUR = `time_index time=$HIGH -h`

show_info -p $product'['$FHOUR'-'$LHOUR']' -i > show_info.log 

if ($?) then
   echo $0 $* FAILED
   exit 1
endif

