#! /bin/csh -f

set WFDIR = $WORKFLOW_DATA

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
set WANTLOW_t = `time_convert time=$WANTLOW`
set WANTLOW = `time_convert zone=TAI s=$WANTLOW_t`
set WANTHIGH_t = `time_convert time=$WANTHIGH`
set WANTHIGH = `time_convert zone=TAI s=$WANTHIGH_t`

set SPECIAL = `grep SPECIAL ticket`
foreach SPEC ($SPECIAL)
     if ($#SPEC) set $SPEC
end

# This cwd is the taskid dir.  The product name can be found in the associated
# gate dir.  Follow the tree back to the gate.

set gate = `cat ../../target`
set product = `cat $WFDIR/gates/$gate/product`
 
# FIX times for DSDS time_index
set LOW = `time_index time=$WANTLOW -t`
set FSIX = `time_index time=$LOW -6`
set HIGH = `time_index time=$WANTHIGH -t`
set LSIX = `time_index time=$HIGH -6`

show_info -p $product'['$FSIX'-'$LSIX']' -i > show_info.log 

if ($?) then
   echo $0 $* FAILED
   exit 1
endif

