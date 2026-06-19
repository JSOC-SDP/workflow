#! /bin/csh -f

echo $0 $*

#set echo

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

# Call with gatename(s)

# set defaults and collect args

set gate_name = "NOT_SPECIFIED"

while ( $#argv > 0)
	set gate_name = $1
	cd $WORKFLOW_DATA/gates/$gate_name
	echo "HOLD" > gatestatus
	echo $gate_name on hold
	shift
end #while

