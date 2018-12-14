#! /bin/csh -f

# Script to make HMI lev1.5 45s observables from HMI lev1 that has been scatter light corrected.

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

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set LEV1 = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/lev1_dcon
set OBS = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/HMI_observables_dcon2

set LEV1_ARGS = "out=hmi.lev1_dcon psf=hmi.psf iter=25"
set OBS_ARGS = "levin=lev1 levout=lev1.5 wavelength=3 quicklook=0 camid=1 cadence=45.0 lev1=hmi.lev1_dcon smooth=1 rotational=0 linearity=1 -L"

set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
set timestr = `echo $wantlow  | sed -e 's/[.:_]//g' -e 's/^......//' -e 's/..TAI//'`

set name = DCL45
set qsubname = $name'_'$timestr
set LOG = $HERE/runlog
set CMD = $HERE/$qsubname

# make lev1

@ low_s = `$TIME_CONVERT time=$wantlow`
@ T1_s = $low_s - 300   
@ high_s = `$TIME_CONVERT time=$wanthigh`
@ T2_s = $high_s + 300
set T1 = `$TIME_CONVERT s=$T1_s zone=TAI`
set T2 = `$TIME_CONVERT s=$T2_s zone=TAI`

set QUE = k.q
@ THREADS = 4

touch $HERE/qsub_running
echo 6 > $HERE/lev1retstatus

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
echo "setenv OMP_NUM_THREADS $THREADS" >> $CMD
echo "$LEV1 in=hmi.lev1'['$T1'-'$T2']' $LEV1_ARGS" >> $CMD
echo 'set lev1retstatus = $?' >>$CMD
echo 'echo $lev1retstatus >' "$HERE/lev1retstatus" >>$CMD
echo 'if ($lev1retstatus) goto DONE' >> $CMD

# make observables

echo 6 > $HERE/obsretstatus

echo "$OBS begin=$wantlow end=$wanthigh $OBS_ARGS" >> $CMD
echo 'set obsretstatus = $?' >>$CMD
echo 'echo $obsretstatus >' "$HERE/obs.retstatus" >>$CMD

echo 'DONE:' >>$CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -pe smp 4 -e $LOG -o $LOG -q $QUE $CMD >> $LOG
