#! /bin/csh -f

echo $0 $*

#set echo

if ($?WORKFLOW_ROOT) then
  set WFCODE = $WORKFLOW_ROOT
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

# Call with gatename(s)

# set defaults and collect args

set gate_name = "NOT_SPECIFIED"

while ( $#argv > 0)
	set gate_name = $1
	cd $WFDIR/gates/$gate_name
	echo "HOLD" > gatestatus
	echo $gate_name on hold
	shift
end #while

