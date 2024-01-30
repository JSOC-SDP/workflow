#! /bin/csh -f
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

foreach task ( $WORKFLOW_DATA/tasks/* )
    foreach ticket ( `ls -1 $task/active/ | grep -v root` )
        ls -d $task/active/$ticket
    end
end
