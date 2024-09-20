#! /bin/csh -f
setenv WORKFLOW_ROOT "${DRMS_SRC_INSTALL_DIR}"/workflow

set QUE = k.q
set QSUBFLAGS = "-v JSOC_r10"
set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"

set CMD = $cwd/TEST.cmd
set LOG = $cwd/TEST.runlog

echo "echo sleeping" > $CMD
echo "sleep 60" >> $CMD
echo "echo done" >> $CMD

$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD


