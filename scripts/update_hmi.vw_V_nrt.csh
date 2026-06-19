#! /bin/csh -f
set HERE = $cwd

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set JREBINSMOOTH = "${DRMS_BINS_INSTALL_DIR}"/jrebinsmooth

set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j.q,p.q
      set QSUB = "qsub $QSUBFLAGS"
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = a.q
      set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    endif
endif

if ( $?WORKFLOW_TEST ) then
  set namespace = "hmi_test"
else
  set namespace = "hmi"
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
set qsubname = NVWV$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

set params = "out=$namespace.vw_V_45s_nrt IBIN=1 NBIN=4 BIN_XOFF=14 BIN_YOFF=-1 BIN_FILL=nan IGAUSS=1 GAUSS_WID=10 GAUSS_SIG=2.8284271248 GAUSS_NSUB=5 GAUSS_XOFF=1 GAUSS_YOFF=1 GAUSS_FILL=nan"

# make qsub script

echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >> $CMD
echo "hostname >>&$LOG" >> $CMD
echo "" >> $CMD
echo "set echo" >> $CMD
echo "$JREBINSMOOTH in=$namespace.V_45s_nrt'['$wantlow'-'$wanthigh']' $params" >> $CMD
echo 'set REBINstatus = $?' >> $CMD
echo 'echo $REBINstatus >retstatus' >>&$CMD

set LOG = `echo $LOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD 

set retstatus = `cat $HERE/retstatus`
exit $retstatus
