#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

# Script to make HMI lev1.5 45s observables from HMI lev1 that has been scatter light corrected.
set HERE = $cwd 

set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
else
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set LEV1 = "${DRMS_BINS_INSTALL_DIR}"/lev1_dcon
set OBSERVABLES = "${DRMS_BINS_INSTALL_DIR}"/HMI_observables_dcon2
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set LEV1_ARGS = "out=hmi.lev1_dcon psf=hmi.psf iter=25"
set OBSERVABLES_ARGS = "levin=lev1 levout=lev1.5 wavelength=3 quicklook=0 camid=1 cadence=45.0 lev1=hmi.lev1_dcon smooth=1 rotational=0 linearity=1 -L"

set indexlow = `$INDEX_CONVERT ds=$product $key=$WANTLOW`
set indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `$INDEX_CONVERT ds=$product $key"_index"=$indexlow`
set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
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
echo "$$OBSERVABLES begin=$wantlow end=$wanthigh $OBSERVABLES_ARGS" >> $CMD
echo 'set obsretstatus = $?' >>$CMD
echo 'echo $obsretstatus >' "$HERE/obsretstatus" >>$CMD

echo 'DONE:' >>$CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -sync yes -pe smp $THREADS -e $LOG -o $LOG -q $QUE $CMD
