#! /bin/csh -f
# Script to make HMI lev1.5 720s observables from HMI lev1 data
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test

set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  @ THREADS = 1
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = p4.q
  @ THREADS = 4
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set ECLIPSEscript = /home/jsoc/pipeline/scripts/eclipse.pl
set IQUVprogram = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/HMI_IQUV_averaging
set HMIprogram = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/HMI_observables
set PolarF = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/meanpf
set HMI_segment = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_segment_module
set HMI_patch = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_patch_module
set JV2TS = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/jv2ts
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert

#set IQUV_args = "-L wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1 quicklook=0"
#set OBS_args = "-L levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1"
## CHANGED on 2012.10.16 for Sebastien's new observables code
set IQUV_args = "-L wavelength=3 camid=0 cadence=90.0 npol=8 size=48 lev1=hmi.lev1 quicklook=0 linearity=1"
set OBS_args = "-L -V levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=3 cadence=720.0 lev1=hmi.lev1 smooth=1 linearity=1"
#set PATCH_args = "-L bb=hmi.Mpatch_720s"

# round times to a slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`
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
#$ECLIPSEscript $wantlow $wanthigh

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

echo "$IQUVprogram begin="$wantlow"  end="$wanthigh $IQUV_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus = $?' >>$TEMPCMD
echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$HMIprogram begin="$wantlow"  end="$wanthigh $OBS_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD

# Remove limb darkening/create marmask

echo "/home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_limbdark in=hmi.Ic_720s'['$wantlow'-'$wanthigh'][3]'  out=hmi.Ic_noLimbDark_720s -cnxf NONE >>&$TEMPLOG" >>$TEMPCMD
echo "$PolarF in=hmi.M_720s\["$wantlow"-"$wanthigh"] >>&$TEMPLOG" >>$TEMPCMD

# Remap/Resize mags for synoptic charts

#echo "/home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/fdlos2radial in=hmi.M_720s'['$wantlow'-'$wanthigh']' out=hmi.Mr_720s >>&$TEMPLOG" >>$TEMPCMD

@ wantlow_s = `$TIME_CONVERT time=$wantlow`
@ wanthigh_s = `$TIME_CONVERT time=$wanthigh`
@ diff = $wanthigh_s - $wantlow_s
set t = $diff's'
if ( $diff < 720 ) then
  set t = 720s
endif

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=1 in=hmi.M_720s\["$wantlow"/"$t"] v2hout=hmi.Ml_hiresmap_720s histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 FORCEOUTPUT=1 >>&$TEMPLOG" >>$TEMPCMD

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=2 in=hmi.M_720s\["$wantlow"/"$t"] v2hout=hmi.Mr_hiresmap_720s histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 FORCEOUTPUT=1 >>&$TEMPLOG" >>$TEMPCMD

echo "$JV2TS MAPMMAX=1800 SINBDIVS=720 LGSHIFT=3 CARRSTRETCH=1 in=hmi.Ic_noLimbDark_720s\["$wantlow"/"$t"] v2hout='hmi.Ic_noLimbDark_remap_720s' histlink=none TSTART=$wantlow TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90. MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1" >>$TEMPCMD

echo "/home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/resizemappingmag in=hmi.Ml_hiresmap_720s\["$wantlow"-"$wanthigh"] out=hmi.Ml_remap_720s nbin=3 >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/resizemappingmag in=hmi.Mr_hiresmap_720s\["$wantlow"-"$wanthigh"] out=hmi.Mr_remap_720s nbin=3 >>&$TEMPLOG" >>$TEMPCMD

# echo 'set PATstatus = $?' >>$TEMPCMD
# echo 'if ($PATstatus) goto DONE' >>&$TEMPCMD
echo 'DONE:' >>$TEMPCMD
echo 'echo $IQUVstatus >IQUVstatus' >>&$TEMPCMD
echo 'echo $OBSstatus >OBSstatus' >>&$TEMPCMD
#echo 'echo $PATstatus >PATstatus' >>&$TEMPCMD
echo '@ retstatus = $IQUVstatus + $OBSstatus' >>$TEMPCMD
echo 'echo $retstatus >retstatus' >>$TEMPCMD
echo "rm -f $HERE/qsub_running" >>$TEMPCMD

# execute qsub script
touch $HERE/qsub_running
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD >> runlog

if ( -e $HERE/retstatus) set retstatus = `cat $HERE/retstatus`
if ( $retstatus == 0 ) then
  @ t1 = `time_convert time=$WANTLOW`
  @ t2 = `time_convert time=$WANTHIGH - 720`
  @ t = $t1
  while ( $t <= $t2 )
    @ end = $t + 3600
    set WLO = `time_convert s=$t zone=tai`
    set WHI = `time_convert s=$end zone=tai`
    set FITS_TICKET = `$WFCODE/maketicket.csh gate=hmi.webFits wantlow=$WLO wanthigh=$WHI action=5`
    @ t = $end + 1
  end
  set MSK_TICKET = `$WFCODE/maketicket.csh gate=hmi.Marmask wantlow=$wantlow wanthigh=$wanthigh action=5`
#  @ indexhigh++
#  set vfisvhigh = `index_convert ds=$product $key"_index"=$indexhigh`
  @ tv = `time_convert time=$WANTHIGH + 360`
  set vfishigh = `time_convert s=$tv zone=tai`
  set VFISV_TICKET = `$WFCODE/maketicket.csh gate=hmi.ME_720s_fd10 wantlow=$wantlow wanthigh=$vfisvhigh action=5`
  set LATLON_TICKET = `$WFCODE/maketicket.csh gate=hmi.MrMap_latlon_720s wantlow=$wantlow wanthigh=$wanthigh action=5`
endif
exit $retstatus
