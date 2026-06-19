#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set QUE = k.q
set QSUBFLAGS = "-v JSOC_r10"
set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"

set CMD = $cwd/TEST.cmd
set LOG = $cwd/TEST.runlog

echo "echo sleeping" > $CMD
echo "sleep 60" >> $CMD
echo "echo done" >> $CMD

$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD


