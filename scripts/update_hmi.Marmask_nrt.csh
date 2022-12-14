#! /bin/csh -f
# Script to make HMI Marmask - Mag Acrive Region Mask 720s
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

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = p.q,j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set HMI_segment = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_segment_module


set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

@ count = `$SHOW_INFO -qc hmi.M_720s_nrt'['$wantlow'-'$wanthigh'][? quality > 0 ?]'`
if ( $count == 0 ) then
  exit
endif

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = MSK
set qsubname = $timename$timestr

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

foreach trec ( `$SHOW_INFO -q hmi.M_720s_nrt'['$wantlow'-'$wanthigh'][? quality > 0 ?]' key=t_rec` )
  echo "$HMI_segment xm=hmi.M_720s_nrt\["$trec"] xp=hmi.Ic_noLimbDark_720s_nrt\["$trec"] model=/builtin/hmi.M_Ic_noLimbDark_720s.production y=hmi.Marmask_720s_nrt >>&$TEMPLOG" >>$TEMPCMD
end

#echo "$HMI_segment xm=hmi.M_720s_nrt\["$wantlow"-"$wanthigh"]" "xp=hmi.Ic_noLimbDark_720s_nrt\["$wantlow"-"$wanthigh"] model=/builtin/hmi.M_Ic_noLimbDark_720s.production y=hmi.Marmask_720s_nrt >>&$TEMPLOG" >>$TEMPCMD
echo 'set SEGstatus = $?' >>$TEMPCMD
echo 'if ($SEGstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $SEGstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD 

if (-e retstatus) set retstatus = `cat $HERE/retstatus`

#set ME_TICKET = `$WFCODE/maketicket.csh gate=hmi.ME_720s_fd10_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`

exit $retstatus
