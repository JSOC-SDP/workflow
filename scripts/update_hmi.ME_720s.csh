#! /bin/csh -f

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set HERE = $cwd

set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j8.q
      set QSUB = "qsub $QSUBFLAGS"
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = a8.q
      set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    endif
endif

set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

set TEMPLOG = $HERE/runlog
set timestr = `echo $wantlow  | sed -e 's/[._:]//g' -e 's/^......//' -e 's/..TAI//'`
set TEMPCMD = $HERE/"VFISV"$timestr
echo 0 > retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
# UGH
# make_vfisv doesn't exist; I think this file is obsolete
echo "$WORKFLOW_DIR/scripts/make_vfisv -f $wantlow $wanthigh >>&$TEMPLOG"  >>$TEMPCMD
echo 'set retstatus = $?' >>$TEMPCMD
echo 'echo $retstatus >' "$HERE/retstatus" >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD

if (-e retstatus) set retstatus = `cat $HERE/retstatus`

exit $retstatus

