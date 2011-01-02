#! /bin/csh -f

# echo starting $0 $*

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

foreach ATTR (TYPE WANTLOW WANTHIGH GATE)
 set ATTRTXT = `grep $ATTR ticket`
 set $ATTRTXT
end

set PRODUCT = `cat $WFDIR/gates/$GATE/product`

set_gaps_missing ds=$PRODUCT low=$WANTLOW high=$WANTHIGH

exit $status

