#! /bin/csh -f
# Script to make HMI lev1.5 720s nrt observables from HMI lev1_nrt data
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

set ECLIPSE = $WORKFLOW_DIR/scripts/eclipse.pl
set MAKE_TICKET = $WORKFLOW_DIR/maketicket.csh
set INDEX_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/index_convert
set IQUV_AVERAGING = "${DRMS_BINS_INSTALL_DIR}"/HMI_IQUV_averaging
set JV2TS = "${DRMS_BINS_INSTALL_DIR}"/jv2ts
set LIMBDARK = "${DRMS_BINS_INSTALL_DIR}"/hmi_limbdark
set OBSERVABLES = "${DRMS_BINS_INSTALL_DIR}"/HMI_observables
set RESIZE_MAPPING = "${DRMS_BINS_INSTALL_DIR}"/resizemappingmag
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

set noglob

if ( $?WORKFLOW_TEST ) then
    set QUE = k.q
    @ THREADS = 4
    set QSUB = "/SGE2/bin/lx-amd64/qsub -pe smp $THREADS"
else
    if ( $JSOC_MACHINE == "linux_x86_64" ) then
      set QUE = j.q
      @ THREADS = 1
      set QSUB = qsub
    else if ( $JSOC_MACHINE == "linux_avx" ) then
      set QUE = k.q
      @ THREADS = 4
      set QSUB = /SGE2/bin/lx-amd64/qsub
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

#set IQUV_args = "wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1_nrt quicklook=1"
#set OBS_args = "levin=lev1p levout=lev15 wavelength=3 quicklook=1 camid=0 cadence=720.0 lev1=hmi.lev1_nrt"
##  CHANGED arguments 2012.10.16 for Sebastien's new observables code
set IQUV_args = "wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1_nrt quicklook=1 linearity=1"
set OBS_args = "-V levin=lev1p levout=lev15 wavelength=3 quicklook=1 camid=0 cadence=720.0 lev1=hmi.lev1_nrt smooth=1 linearity=1" 
set LD_args = "-cnxf NONE"
#set PATCH_args = "bb=hmi.Mpatch_720s_nrt"

# round times to a slot
set indexlow = `$INDEX_CONVERT ds=$product $key=$WANTLOW`
set indexhigh = `$INDEX_CONVERT ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `$INDEX_CONVERT ds=$product $key"_index"=$indexlow`
set wanthigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
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
echo "setenv OMP_NUM_THREADS $THREADS" >>$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus=0' >>&$TEMPCMD
echo 'set OBSstatus=0' >>&$TEMPCMD
echo 'set LDstatus=0' >>&$TEMPCMD

echo "$IQUV_AVERAGING begin="$wantlow"  end="$wanthigh $IQUV_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus = $?' >>$TEMPCMD
echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$OBSERVABLES begin="$wantlow"  end="$wanthigh $OBS_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD
echo "$LIMBDARK in=hmi.Ic_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Ic_noLimbDark_720s_nrt "$LD_args" >>&$TEMPLOG" >>$TEMPCMD
echo 'set LDstatus = $?' >>$TEMPCMD
echo 'if ($LDstatus) goto DONE' >>&$TEMPCMD


## Remap/Resize mags for synoptic charts
@ wantlow_s = `$TIME_CONVERT time=$wantlow`
@ wanthigh_s = `$TIME_CONVERT time=$wanthigh` 
@ diff = $wanthigh_s - $wantlow_s
set t = $diff's'
if ( $diff < 720 ) then
  set t = 720s
endif

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=1 in=hmi.M_720s_nrt\["$wantlow"/"$t"] v2hout=hmi.Ml_hiresmap_720s_nrt histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 >>&$TEMPLOG" >>$TEMPCMD

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=2 in=hmi.M_720s_nrt\["$wantlow"/"$t"] v2hout=hmi.Mr_hiresmap_720s_nrt histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 >>&$TEMPLOG" >>$TEMPCMD

echo "$RESIZE_MAPPING in=hmi.Ml_hiresmap_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Ml_remap_720s_nrt nbin=3 >>&$TEMPLOG" >>$TEMPCMD
echo "$RESIZE_MAPPING in=hmi.Mr_hiresmap_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Mr_remap_720s_nrt nbin=3 >>&$TEMPLOG" >>$TEMPCMD

echo 'DONE:' >>$TEMPCMD
echo 'echo $IQUVstatus >IQUVstatus' >>&$TEMPCMD
echo 'echo $OBSstatus >OBSstatus' >>&$TEMPCMD
#echo 'echo $PATstatus >PATstatus' >>&$TEMPCMD
echo 'echo $LDstatus >LDstatus' >> &$TEMPCMD
echo '@ retstatus = $IQUVstatus + $OBSstatus + $LDstatus' >>$TEMPCMD

echo 'echo $retstatus >retstatus' >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -pe smp 4 -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD     # <---use this command if using k.q

if ( -e $HERE/retstatus) set retstatus = `cat $HERE/retstatus`
if ( ($retstatus == 0) ) then
  set MSK_TICKET = `$MAKE_TICKET gate=hmi.Marmask_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
  set REMAP_TICKET = `$MAKE_TICKET gate=hmi.MrMap_latlon_720s_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
endif

exit $retstatus
