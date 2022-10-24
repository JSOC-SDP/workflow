#! /bin/csh -f

echo ACTIONTASK starting $0 $*

set echo

# script to stage data based on FSN with SUMS tape file ordering
# WANTLOW and WANTHIGH are exptected to be in FSN already.

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

set SPECIAL = `grep SPECIAL ticket`
foreach SPEC ($SPECIAL)
     if ($#SPEC) set $SPEC
end

# This cwd is the taskid dir.  The product name can be found in the associated
# gate dir.  Follow the tree back to the gate.

set gate = `cat ../../target`
set product = `cat $WORKFLOW_DATA/gates/$gate/product`
 
$WORKFLOW_ROOT/scripts/stage_tapes_in_order.csh 10 $product'['$WANTLOW'-'$WANTHIGH']' >& stage_tapes.log

if ($?) then
   echo $0 $* FAILED
   exit 1
endif

exit 0
