#! /bin/csh -f

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub

set CMD = $cwd/TEST.cmd
set LOG = $cwd/TEST.runlog

echo "echo sleeping" > $CMD
echo "sleep 60" >> $CMD
echo "echo done" >> $CMD

$QSUB -e $LOG -o $LOG -q $QUE $CMD


