#! /bin/csh -f

source $HOME/.cshrc
source $HOME/.login

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

cd $WORKFLOW_DATA

# Cleanup old log files of successful tasks.
# gatekeeper need not be stopped for this process since
# only completed tasks will have old logs removed.

set NOW = `date +%Y%m%d_%H%M`
$WORKFLOW_DIR/cleanup.csh >& $WORKFLOW_DATA/cleanup_logs/cleanup_log.$NOW
