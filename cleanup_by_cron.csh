#! /bin/csh -f

source $HOME/.cshrc
source $HOME/.login

setenv WORKFLOW_DATA /home/jsoc/pipeline
#setenv WORKFLOW_ROOT /home/phil/jsoc/proj/workflow
setenv WORKFLOW_ROOT /home/jsoc/cvs/Development/JSOC/proj/workflow

cd $WORKFLOW_DATA

# Cleanup old log files of successful tasks.
# gatekeeper need not be stopped for this process since
# only completed tasks will have old logs removed.

set NOW = `date +%Y%m%d_%H%M`
$WORKFLOW_ROOT/cleanup.csh >& $WORKFLOW_DATA/cleanup_log.$NOW
