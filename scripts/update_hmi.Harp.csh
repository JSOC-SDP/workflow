#! /bin/csh -f
# Script to make HMI HARPS 
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set HARPS = /home/jsoc/cvs/Development/JSOC/proj/mag/harp/scripts/track_and_ingest_mharp.sh

set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

# round times to a slot
#set indexlow = `index_convert ds=$product $key=$WANTLOW`
#set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
#@ indexhigh = $indexhigh - 1
#set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
#set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
#set timestr = `echo $wantlow  | sed -e 's/[._:]//g' -e 's/^.......//' -e 's/TAI//'`
set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = HARP
set qsubname = $timename$timestr

#if ($indexhigh < $indexlow) then
#   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
#   exit 0
#endif

set TEMPLOG = $HERE/runlog
set babble = $HERE/babble
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set HARPstatus=0' >>&$TEMPCMD

echo "$HARPS /tmp22/HARPS/definitive 'hmi.Marmask_720s\["$wantlow"-"$wanthigh"]' hmi.Mharp_720s hmi.Mharp_log_720s >>&$TEMPLOG" >>$TEMPCMD
echo 'set HARPstatus = $?' >>$TEMPCMD
echo 'if ($HARPstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $HARPstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
qsub -sync yes -e $TEMPLOG -o $TEMPLOG -q j.q,p.q $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
