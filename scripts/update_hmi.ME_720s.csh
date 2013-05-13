#! /bin/csh -f

set HERE = $cwd

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_ROOT
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
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
qsub -sync yes -e $TEMPLOG -o $TEMPLOG -q j.8 $TEMPCMD
#qsub2 -pe smp 8 -e $TEMPLOG -o $TEMPLOG 

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
#if ( $retstatus == 0 ) then
#  set SHP_TICKET = `$WFCODE/maketicket.csh gate=hmi.sharp wantlow=$wantlow wanthigh=$wanthigh action=5`
#endif

exit $retstatus

