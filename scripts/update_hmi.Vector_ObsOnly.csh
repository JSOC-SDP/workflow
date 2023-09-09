#! /bin/csh -f
# Script to make HMI lev1.5 X_720s observables from HMI S_720s data
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test
set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j8.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a8.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set IQUVprogram = "${drms_bins_install_dir}"/HMI_IQUV_averaging
set HMIprogram = "${drms_bins_install_dir}"/HMI_observables
set HMI_segment = "${drms_bins_install_dir}"/hmi_segment_module
set HMI_patch = "${drms_bins_install_dir}"/hmi_patch_module

# set IQUV_args = "wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1 quicklook=0 dpath="${drms_src_install_dir}"/lev1.5_hmi/apps"
#set OBS_args = "levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1 dpath="${drms_src_install_dir}"/lev1.5_hmi/apps" 
set OBS_args = "levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1"
set SEG_args = "beta=0.7 alpha=[0,-4] T=[1,1,0.9,0] y=hmi.Marmask_720s"
set PATCH_args = "bb=hmi.Mpatch_720s"

# round times to a slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
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

# echo "$IQUVprogram begin="$wantlow"  end="$wanthigh $IQUV_args  ">>&$TEMPLOG" >>$TEMPCMD
# echo 'set IQUVstatus = $?' >>$TEMPCMD
echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$HMIprogram begin="$wantlow"  end="$wanthigh $OBS_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD
#echo "$HMI_segment xm=hmi.M_720s["$wantlow"-"$wanthigh"]" "xp=hmi.Ic_720s["$wantlow"-"$wanthigh"]" $SEG_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set SEGstatus = $?' >>$TEMPCMD
echo 'if ($SEGstatus) goto DONE' >>&$TEMPCMD
# echo "$HMI_patch x=hmi.Marmask_720s["$wantlow"-"$wanthigh"]" $PATCH_args  ">>&$TEMPLOG" >>$TEMPCMD
# echo 'set PATstatus = $?' >>$TEMPCMD
# echo 'if ($PATstatus) goto DONE' >>&$TEMPCMD
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
