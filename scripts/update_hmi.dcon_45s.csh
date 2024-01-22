#! /bin/csh -f

# Script to make HMI lev1.5 45s observables from HMI lev1 that has been scatter light corrected.

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

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set SHOW_INFO = "${drms_bins_install_dir}"/show_info
set TIME_CONVERT = "${drms_bins_install_dir}"/time_convert
set LEV1 = "${drms_bins_install_dir}"/lev1_dcon
set OBS = "${drms_bins_install_dir}"/HMI_observables_dcon2

set LEV1_ARGS = "out=hmi.lev1_dcon psf=hmi.psf iter=25"
set OBS_ARGS = "levin=lev1 levout=lev1.5 wavelength=3 quicklook=0 camid=1 cadence=45.0 lev1=hmi.lev1_dcon smooth=1 rotational=0 linearity=1 -L"

set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
set timestr = `echo $wantlow  | sed -e 's/[.:_]//g' -e 's/^......//' -e 's/..TAI//'`

set name = DC45
set qsubname = $name'_'$timestr
@ THREADS = 4

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname

# make lev1

@ low_s = `$TIME_CONVERT time=$wantlow`
@ T1_s = $low_s - 300   
@ high_s = `$TIME_CONVERT time=$wanthigh`
@ T2_s = $high_s + 300
set T1 = `$TIME_CONVERT s=$T1_s zone=TAI`
set T2 = `$TIME_CONVERT s=$T2_s zone=TAI`

touch $HERE/qsub_running
@ lev1retstatus = 6
echo $lev1retstatus > $HERE/lev1retstatus

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
echo >> $CMD
echo "setenv OMP_NUM_THREADS $THREADS" >> $CMD
echo "$LEV1 in=hmi.lev1'['$T1'-'$T2']' $LEV1_ARGS" >> $CMD
echo 'set lev1retstatus = $?' >>$CMD
echo 'echo $lev1retstatus >' "$HERE/lev1retstatus" >>$CMD
echo 'if ($lev1retstatus) goto DONE' >> $CMD

# make observables

@ obsretstatus = 6
echo $obsretstatus > $HERE/obsretstatus

echo >> $CMD
echo "$OBS begin=$wantlow end=$wanthigh $OBS_ARGS" >> $CMD
echo 'set obsretstatus = $?' >>$CMD
echo 'echo $obsretstatus >' "$HERE/obsretstatus" >>$CMD

echo 'DONE:' >>$CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -sync yes -pe smp $THREADS -e $LOG -o $LOG -q $QUE $CMD
