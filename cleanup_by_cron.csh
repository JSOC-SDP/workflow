#! /bin/csh -f

source $HOME/.cshrc
source $HOME/.login

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

cd $WORKFLOW_DATA

# Cleanup old log files of successful tasks.
# gatekeeper need not be stopped for this process since
# only completed tasks will have old logs removed.

set NOW = `date +%Y%m%d_%H%M`
$WORKFLOW_DIR/cleanup.csh >& $WORKFLOW_DATA/cleanup_logs/cleanup_log.$NOW
