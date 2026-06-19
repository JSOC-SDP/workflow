#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

foreach task ( $WORKFLOW_DATA/tasks/* )
    foreach ticket ( `ls -1 $task/active/ | grep -v root` )
        ls -d $task/active/$ticket
    end
end
