#! /bin/csh -f

# the clock status task simply reflects the current time

# echo starting $0 $*

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

cd $WFDIR/gates/$1

set nowtxt = `date -u +%Y.%m.%d_%H:%M:%S`
set low = `cat low`
if ($low == "NaN") echo $nowtxt > low

echo $nowtxt > high
echo $nowtxt > lastupdate

rm -f statusbusy

