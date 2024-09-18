#! /bin/csh -f
# Script to make HMI lev1.5 720s observables from HMI lev1 data
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
set MEANPF = "${DRMS_BINS_INSTALL_DIR}"/meanpf
set RESIZE_MAPPING = "${DRMS_BINS_INSTALL_DIR}"/resizemappingmag
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert

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
      set QUE = p4.q
      @ THREADS = 4
      set QSUB = /SGE2/bin/lx-amd64/qsub
    endif
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

if ( $?WORKFLOW_TEST ) then
    set test_flag = "-t"
    set namespace = "hmi_test"
else
    set test_flag = ""
    set namespace = "hmi"
endif

set product = `cat $WORKFLOW_DATA/gates/$GATE/product`
set key = `cat $WORKFLOW_DATA/gates/$GATE/key`

#set IQUV_args = "-L wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1 quicklook=0"
#set OBS_args = "-L levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1"
## CHANGED on 2012.10.16 for Sebastien's new observables code
set IQUV_args = "-L wavelength=3 camid=0 cadence=90.0 npol=8 size=48 lev1=hmi.lev1 quicklook=0 linearity=1"
set OBS_args = "-L -V levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=3 cadence=720.0 lev1=hmi.lev1 smooth=1 linearity=1"
#set PATCH_args = "-L bb=hmi.Mpatch_720s"

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

# check for eclipse quality bits to be set in lev1_nrt
#$ECLIPSE $wantlow $wanthigh

# wait for cosmic ray completeness
@ lev1_N = `$SHOW_INFO hmi.lev1'['$wantlow'-'$wanthigh'][? hftsacid = 1022 ?]' -qc`
@ CR_N = `$SHOW_INFO hmi.cosmic_rays'['$wantlow'-'$wanthigh']' -qc`
while ( $CR_N < $lev1_N )
  sleep 1800
  touch $HERE/WAITING_FOR_CR
  @ lev1_N = `$SHOW_INFO hmi.lev1'['$wantlow'-'$wanthigh'][? hftsacid = 1022 ?]' -qc`
  @ CR_N = `$SHOW_INFO hmi.cosmic_rays'['$wantlow'-'$wanthigh']' -qc`
end

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
#echo "setenv OMP_NUM_THREADS 8" >>$TEMPCMD
echo "setenv OMP_NUM_THREADS $THREADS" >>$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus=0' >>&$TEMPCMD
echo 'set OBSstatus=0' >>&$TEMPCMD
#echo 'set PATstatus=0' >>&$TEMPCMD

echo "$IQUV_AVERAGING begin="$wantlow"  end="$wanthigh $IQUV_args $test_flag ">>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus = $?' >>$TEMPCMD
echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$OBSERVABLES begin="$wantlow"  end="$wanthigh $OBS_args $test_flag ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD

# Remove limb darkening/create marmask

echo "$LIMBDARK in=$namespace.Ic_720s'['$wantlow'-'$wanthigh'][3]'  out=$namespace.Ic_noLimbDark_720s -cnxf NONE >>&$TEMPLOG" >>$TEMPCMD
echo 'set LDstatus = $?' >>$TEMPCMD
echo "$MEANPF in=$namespace.M_720s\["$wantlow"-"$wanthigh"] >>&$TEMPLOG" >>$TEMPCMD

# Remap/Resize mags for synoptic charts

@ wantlow_s = `$TIME_CONVERT time=$wantlow`
@ wanthigh_s = `$TIME_CONVERT time=$wanthigh`
@ diff = $wanthigh_s - $wantlow_s
set t = $diff's'
if ( $diff < 1080 ) then
  set t = 1080s
endif

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=1 in=$namespace.M_720s\["$wantlow"/"$t"] v2hout=$namespace.Ml_hiresmap_720s histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 FORCEOUTPUT=1 >>&$TEMPLOG" >>$TEMPCMD

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=2 in=$namespace.M_720s\["$wantlow"/"$t"] v2hout=$namespace.Mr_hiresmap_720s histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 FORCEOUTPUT=1 >>&$TEMPLOG" >>$TEMPCMD

echo "$JV2TS MAPMMAX=1800 SINBDIVS=720 LGSHIFT=3 CARRSTRETCH=1 in=$namespace.Ic_noLimbDark_720s\["$wantlow"/"$t"] v2hout='$namespace.Ic_noLimbDark_remap_720s' histlink=none TSTART=$wantlow TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90. MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1" >>$TEMPCMD

echo "$RESIZE_MAPPING in=$namespace.Ml_hiresmap_720s\["$wantlow"-"$wanthigh"] out=$namespace.Ml_remap_720s nbin=3 >>&$TEMPLOG" >>$TEMPCMD
echo "$RESIZE_MAPPING in=$namespace.Mr_hiresmap_720s\["$wantlow"-"$wanthigh"] out=$namespace.Mr_remap_720s nbin=3 >>&$TEMPLOG" >>$TEMPCMD

# echo 'set PATstatus = $?' >>$TEMPCMD
# echo 'if ($PATstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $IQUVstatus >IQUVstatus' >>&$TEMPCMD
echo 'echo $OBSstatus >OBSstatus' >>&$TEMPCMD
echo 'echo $LFstatus >LDstatus' >>&$TEMPCMD
#echo 'echo $PATstatus >PATstatus' >>&$TEMPCMD
echo '@ retstatus = $IQUVstatus + $OBSstatus + $LDstatus' >>$TEMPCMD
echo 'echo $retstatus >retstatus' >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if ( -e $HERE/retstatus) set retstatus = `cat $HERE/retstatus`
if ( $retstatus == 0 ) then
  @ t1 = `$TIME_CONVERT time=$WANTLOW`
  @ t2 = `$TIME_CONVERT time=$WANTHIGH - 720`
  @ t = $t1
  while ( $t <= $t2 )
    @ end = $t + 3600
    set WLO = `$TIME_CONVERT s=$t zone=tai`
    set WHI = `$TIME_CONVERT s=$end zone=tai`
    set FITS_TICKET = `$MAKE_TICKET gate=hmi.webFits wantlow=$WLO wanthigh=$WHI action=5`
    @ t = $end + 1
  end
  set MSK_TICKET = `$MAKE_TICKET gate=hmi.Marmask wantlow=$wantlow wanthigh=$wanthigh action=5`
  set S_TICKET = `$MAKE_TICKET gate=hmi.S_5760s wantlow=$wantlow wanthigh=$wanthigh action=5`
  set vfisvhigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
  set VFISV_TICKET = `$MAKE_TICKET gate=hmi.ME_720s_fd10 wantlow=$wantlow wanthigh=$vfisvhigh action=5`
  set MEF_TICKET = `$MAKE_TICKET gate=hmi.MEF_720s_fd10 wantlow=$wantlow wanthigh=$vfisvhigh action=5`
  #@ indexhigh++
  set MrMaphigh = `$INDEX_CONVERT ds=$product $key"_index"=$indexhigh`
  set LATLON_TICKET = `$MAKE_TICKET gate=hmi.MrMap_latlon_720s wantlow=$WANTLOW wanthigh=$MrMaphigh action=5`
endif
exit $retstatus
