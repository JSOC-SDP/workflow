#! /bin/csh -f
# Script to make HMI Marmask - Mag Acrive Region Mask 720s
#

# XXXXXXXXXX test
 set echo
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

if ($?WORKFLOW_DATA) then
  set WFDIR = $WORKFLOW_DATA
else
  echo Need WORKFLOW_DATA variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = p.q,j.q
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

set SHOW_INFO = "${drms_bins_install_dir}"/show_info
set HMI_segment = "${drms_bins_install_dir}"/hmi_segment_module


set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`

@ count = `$SHOW_INFO -qc hmi.M_720s_nrt'['$wantlow'-'$wanthigh'][? quality > 0 ?]'`
if ( $count == 0 ) then
  exit
endif

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

foreach trec ( `$SHOW_INFO -q hmi.M_720s_nrt'['$wantlow'-'$wanthigh'][? quality > 0 ?]' key=t_rec` )
  echo "$HMI_segment xm=hmi.M_720s_nrt\["$trec"] xp=hmi.Ic_noLimbDark_720s_nrt\["$trec"] model=/builtin/hmi.M_Ic_noLimbDark_720s.production y=hmi.Marmask_720s_nrt >>&$TEMPLOG" >>$TEMPCMD
end

#echo "$HMI_segment xm=hmi.M_720s_nrt\["$wantlow"-"$wanthigh"]" "xp=hmi.Ic_noLimbDark_720s_nrt\["$wantlow"-"$wanthigh"] model=/builtin/hmi.M_Ic_noLimbDark_720s.production y=hmi.Marmask_720s_nrt >>&$TEMPLOG" >>$TEMPCMD
echo 'set SEGstatus = $?' >>$TEMPCMD
echo 'if ($SEGstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $SEGstatus >retstatus' >>&$TEMPCMD

# execute qsub script
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD 

if (-e retstatus) set retstatus = `cat $HERE/retstatus`

exit $retstatus
