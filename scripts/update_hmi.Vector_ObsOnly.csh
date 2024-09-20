#! /bin/csh -f
# Script to make HMI lev1.5 X_720s observables from HMI S_720s data
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test
set HERE = $cwd 

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set MAKE_TICKET = $WORKFLOW_DIR/maketicket.csh
set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set JV2TS = "${DRMS_BINS_INSTALL_DIR}"/jv2ts
set LIMBDARK = "${DRMS_BINS_INSTALL_DIR}"/hmi_limbdark
set OBSERVABLES = "${DRMS_BINS_INSTALL_DIR}"/HMI_observables
set RESIZE_MAPPING = "${DRMS_BINS_INSTALL_DIR}"/resizemappingmag
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set QSUBFLAGS = "-v JSOC_r10"
if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j8.q
      set QSUB = "qsub $QSUBFLAGS"
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = a8.q
      set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

set OBS_args = "levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1"
set SEG_args = "beta=0.7 alpha=[0,-4] T=[1,1,0.9,0] y=hmi.Marmask_720s"
set PATCH_args = "bb=hmi.Mpatch_720s"

# round times to a slot
set indexlow = `$INDEX_CONVERT ds=$product $key=$WANTLOW`
set indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `$INDEX_CONVERT ds=$product $key"_index"=$indexlow`
set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
# set timestr = `echo $wantlow  | sed -e 's/[._:]//g' -e 's/^.......//' -e 's/TAI//'`
set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = VEC
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
echo "setenv OMP_NUM_THREADS 8" >>$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus=0' >>&$TEMPCMD
echo 'set OBSstatus=0' >>&$TEMPCMD
echo 'set SEGstatus=0' >>&$TEMPCMD
echo 'set PATstatus=0' >>&$TEMPCMD

echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$OBSERVABLES begin="$wantlow"  end="$wanthigh $OBS_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD
echo 'set SEGstatus = $?' >>$TEMPCMD
echo 'if ($SEGstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $IQUVstatus >IQUVstatus' >>&$TEMPCMD
echo 'echo $OBSstatus >OBSstatus' >>&$TEMPCMD
echo 'echo $SEGstatus >SEGstatus' >>&$TEMPCMD
echo 'echo $PATstatus >PATstatus' >>&$TEMPCMD
echo '@ retstatus = $IQUVstatus + $OBSstatus + $SEGstatus + $PATstatus' >>$TEMPCMD
echo 'echo $retstatus >retstatus' >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
