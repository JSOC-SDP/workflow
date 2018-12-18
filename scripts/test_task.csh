#! /bin/csh -f

setenv WORKFLOW_ROOT /home/jsoc/cvs/Development/JSOC/proj/workflow

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub

set CMD = $cwd/TEST.cmd
set LOG = $cwd/TEST.runlog

echo "echo sleeping" > $CMD
echo "sleep 60" >> $CMD
echo "echo done" >> $CMD

$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD


