#! /bin/csh -f

# echo starting $0 $*

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

foreach ATTR (TYPE WANTLOW WANTHIGH GATE)
 set ATTRTXT = `grep $ATTR ticket`
 set $ATTRTXT
end

set PRODUCT = `cat $WFDIR/gates/$GATE/product`

set_gaps_missing ds=$PRODUCT low=$WANTLOW high=$WANTHIGH

exit $status

