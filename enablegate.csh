#! /bin/csh -f

echo $0 $*

#set echo

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

# Call with gatename(s)

# set defaults and collect args

set gate_name = "NOT_SPECIFIED"

while ( $#argv > 0)
	set gate_name = $1
	cd $WFDIR/gates/$gate_name
	echo "ACTIVE" > gatestatus
	echo $gate_name enabled
	shift
end #while

