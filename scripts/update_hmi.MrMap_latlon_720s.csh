#! /bin/csh -f
# Script to make HMI MrMap_latlon_720s - Mag Acrive Region Mask 720s
#

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set MAPROJ = "${DRMS_BINS_INSTALL_DIR}"/maproj

if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j.q
      set QSUB = qsub
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = k.q
    set QSUB = /SGE2/bin/lx-amd64/qsub
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

set MAPARGS = "-L cols=900 rows=900 scale=0.2 map=carree -R clat=0.0"

set timestr = `echo $WANTHIGH  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = MrMap
set qsubname = $timename$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

# make qsub script
echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >>$CMD
echo "hostname >>&$LOG" >>$CMD
echo "set echo >>&$LOG" >>$CMD
echo 'set retstatus=6' >>&$CMD

foreach T ( `$SHOW_INFO -q hmi.M_720s'['$WANTLOW'-'$WANTHIGH']' key=t_rec` )
  echo "$MAPROJ -v in=hmi.M_720s'['$T']' out=hmi.Mrmap_latlon_720s $MAPARGS" >> $CMD
end
echo 'set retstatus = $?' >>$CMD
echo 'if ($retstatus) goto DONE' >>&$CMD
echo 'DONE:' >>$CMD
echo 'echo $retstatus >retstatus' >>&$CMD

# execute qsub script
set LOG = `echo $LOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
