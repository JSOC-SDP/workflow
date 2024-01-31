#! /bin/csh -f
# Script to make HMI Marmask - Mag Acrive Region Mask 720s
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set HMI_SEGMENT = "${DRMS_BINS_INSTALL_DIR}"/hmi_segment_module

set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q,p.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`


set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

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

foreach trec ( `$SHOW_INFO -q hmi.M_720s'['$wantlow'-'$wanthigh']' key=t_rec` )
  echo "$HMI_SEGMENT xm=hmi.M_720s\["$trec"] xp=hmi.Ic_noLimbDark_720s\["$trec"] model=/builtin/hmi.M_Ic_noLimbDark_720s.production y=hmi.Marmask_720s >>&$TEMPLOG" >>$TEMPCMD
end
echo 'set SEGstatus = $?' >>$TEMPCMD
echo 'if ($SEGstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $SEGstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
