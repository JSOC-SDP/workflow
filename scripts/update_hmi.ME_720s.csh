#! /bin/csh -f

set HERE = $cwd

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_ROOT
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j8.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a8.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
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
echo "$WFDIR/scripts/make_vfisv $wantlow $wanthigh >>&$TEMPLOG"  >>$TEMPCMD
echo 'set retstatus = $?' >>$TEMPCMD
echo 'echo $retstatus >' "$HERE/retstatus" >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
#if ( $retstatus == 0 ) then
#  set SHP_TICKET = `$WFCODE/maketicket.csh gate=hmi.sharp wantlow=$wantlow wanthigh=$wanthigh action=5`
#endif

exit $retstatus

