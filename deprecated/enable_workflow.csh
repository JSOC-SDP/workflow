# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set npath = `echo $path | grep workflow | wc -l`
if ($npath < 8) set path = ($WORKFLOW_DIR $path)
