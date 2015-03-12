#! /bin/csh -f
# Script to make hmi.B_720s
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = k.q
  set QSUB = qsub2
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = HMIB
set qsubname = $timename$timestr

set TEMPLOG = $HERE/runlog
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set DIS = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/disambig_v3
set ARGS = "AMBNEQ=100 AMBTFCTR=0.98 OFFSET=50 AMBNPAD=200 AMBNTX=30 AMBNTY=30 AMBNAP=10 AMBSEED=4 errlog=$TEMPLOG" 

# make qsub scripts
#
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set HMIBstatus=6' >>&$TEMPCMD

foreach T ( `$SHOW_INFO JSOC_DBUSER=production hmi.M_720s'['$wantlow'-'$wanthigh']' -q key=T_REC` )
  echo "$DIS in=hmi.ME_720s_fd10'['$T']' out=hmi.B_720s $ARGS " >> $TEMPCMD
end
echo 'set HMIBstatus = $?' >>$TEMPCMD
echo 'if ($HMIBstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $HMIBstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
