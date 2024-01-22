#! /bin/csh -f

set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

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
set qsubname = VWV$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
echo 6 > $HERE/retstatus

set JREBINSMOOTH = "${drms_bins_install_dir}"/jrebinsmooth

set params = "out=hmi.vw_V_45s IBIN=1 NBIN=4 BIN_XOFF=14 BIN_YOFF=-1 BIN_FILL=nan IGAUSS=1 GAUSS_WID=10 GAUSS_SIG=2.8284271248 GAUSS_NSUB=5 GAUSS_XOFF=1 GAUSS_YOFF=1 GAUSS_FILL=nan -L"

# make qsub script

echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >> $CMD
echo "hostname >>&$LOG" >> $CMD
echo "" >> $CMD
echo "set echo" >> $CMD
echo "$JREBINSMOOTH in=hmi.V_45s'['$wantlow'-'$wanthigh']' $params" >> $CMD
echo 'set REBINstatus = $?' >> $CMD
echo 'echo $REBINstatus >retstatus' >>&$CMD

set LOG = `echo $LOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD 

set retstatus = `cat $HERE/retstatus`
exit $retstatus


