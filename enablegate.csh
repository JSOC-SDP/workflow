#! /bin/csh -f

echo $0 $*

#set echo
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

# Call with gatename(s)

# set defaults and collect args

set gate_name = "NOT_SPECIFIED"

while ( $#argv > 0)
	set gate_name = $1
	cd $WORKFLOW_DATA/gates/$gate_name
	echo "ACTIVE" > gatestatus
	echo $gate_name enabled
	shift
end #while
