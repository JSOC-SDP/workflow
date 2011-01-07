#

setenv WORKFLOW_ROOT /home/phil/cvs/JSOC/proj/workflow
setenv WORKFLOW_DATA /home/jsoc/pipeline

set npath = `echo $path | grep workflow | wc -l`
if ($npath < 8) set path = ($WORKFLOW_ROOT $path)
