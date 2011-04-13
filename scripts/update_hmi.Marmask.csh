#! /bin/csh -f
# Script to make HMI Marmask - Mag Acrive Region Mask 720s
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

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set HMI_segment = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_segment_module
set HMI_patch = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_patch_module

set PATCH_args = "-L bb=hmi.Mpatch_720s"

# round times to a slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
# set timestr = `echo $wantlow  | sed -e 's/[._:]//g' -e 's/^.......//' -e 's/TAI//'`
set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = MSK
set qsubname = $timename$timestr

if ($indexhigh < $indexlow) then
   echo No data to process, $WANTLOW to $WANTHIGH > $HERE/runlog
   exit 0
endif

set TEMPLOG = $HERE/runlog
set babble = $HERE/babble
set TEMPCMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set SEGstatus=0' >>&$TEMPCMD
echo 'set PATstatus=0' >>&$TEMPCMD

echo "$HMI_segment xm=hmi.M_720s["$wantlow"-"$wanthigh"]" "xp=hmi.Ic_720s["$wantlow"-"$wanthigh"] beta=0.7 alpha=[0,-4] T=[1,1,0.9,0] y=hmi.Marmask_720s >>&$TEMPLOG" >>$TEMPCMD
echo 'set SEGstatus = $?' >>$TEMPCMD
echo 'if ($SEGstatus) goto DONE' >>&$TEMPCMD
echo "$HMI_patch x=hmi.Marmask_720s["$wantlow"-"$wanthigh"]" $PATCH_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set PATstatus = $?' >>$TEMPCMD
echo 'if ($PATstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $SEGstatus >SEGstatus' >>&$TEMPCMD
echo 'echo $PATstatus >PATstatus' >>&$TEMPCMD
echo '@ retstatus = $SEGstatus + $PATstatus' >>$TEMPCMD
echo 'echo $retstatus >retstatus' >>$TEMPCMD

# execute qsub script
qsub -sync yes -e $TEMPLOG -o $TEMPLOG -q j.q $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
