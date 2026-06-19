#! /bin/csh -f
# the clock status task simply reflects the current time

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

cd $WORKFLOW_DATA/gates/$1
set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
echo $NOW > high
echo $NOW > lastupdate
rm -f statusbusy
