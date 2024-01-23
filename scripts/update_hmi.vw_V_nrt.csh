#! /bin/csh -f

set JREBINSMOOTH = "${DRMS_BINS_INSTALL_DIR}"/jrebinsmooth

set HERE = $cwd 

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

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

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set qsubname = NVWV$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
echo 6 > $HERE/retstatus



set params = "out=hmi.vw_V_45s_nrt IBIN=1 NBIN=4 BIN_XOFF=14 BIN_YOFF=-1 BIN_FILL=nan IGAUSS=1 GAUSS_WID=10 GAUSS_SIG=2.8284271248 GAUSS_NSUB=5 GAUSS_XOFF=1 GAUSS_YOFF=1 GAUSS_FILL=nan"

# make qsub script

echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >> $CMD
echo "hostname >>&$LOG" >> $CMD
echo "" >> $CMD
echo "set echo" >> $CMD
echo "$JREBINSMOOTH in=hmi.V_45s_nrt'['$wantlow'-'$wanthigh']' $params" >> $CMD
echo 'set REBINstatus = $?' >> $CMD
echo 'echo $REBINstatus >retstatus' >>&$CMD

set LOG = `echo $LOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD 

set retstatus = `cat $HERE/retstatus`
exit $retstatus
