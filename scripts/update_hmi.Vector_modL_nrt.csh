#! /bin/csh -f
# Script to make HMI lev1.5 720s nrt observables from HMI lev1_nrt data
#

# XXXXXXXXXX test
# set echo
# XXXXXXXXXX test
set noglob

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
  set QUE = p4.q,a8.q
  @ THREADS = 4
  set QSUB = qsub2
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
set HMI_limbdark = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_limbdark
set HMI_segment = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_segment_module
set JV2TS = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/jv2ts
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert

set IQUV_args = "wavelength=3 camid=0 cadence=90.0 npol=8 size=48 lev1=hmi.lev1_nrt quicklook=1 linearity=1"
set OBS_args = "-V levin=lev1p levout=lev15 wavelength=3 quicklook=1 camid=3 cadence=720.0 lev1=hmi.lev1_nrt smooth=1 linearity=1" 
set LD_args = "-cnxf NONE"

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
$ECLIPSEscript $wantlow $wanthigh nrt

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "setenv OMP_NUM_THREADS $THREADS" >>$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
#echo "$ECLIPSEscript $wantlow $wanthigh nrt >>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus=0' >>&$TEMPCMD
echo 'set OBSstatus=0' >>&$TEMPCMD
echo 'set LDstatus=0' >>&$TEMPCMD

echo "$IQUVprogram begin="$wantlow"  end="$wanthigh $IQUV_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus = $?' >>$TEMPCMD
echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$HMIprogram begin="$wantlow"  end="$wanthigh $OBS_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD
echo "$HMI_limbdark in=hmi.Ic_720s_nrt'['$wantlow'-'$wanthigh'][3]' out=hmi.Ic_noLimbDark_720s_nrt "$LD_args" >>&$TEMPLOG" >>$TEMPCMD
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

echo "/home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/resizemappingmag in=hmi.Ml_hiresmap_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Ml_remap_720s_nrt nbin=3 >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/resizemappingmag in=hmi.Mr_hiresmap_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Mr_remap_720s_nrt nbin=3 >>&$TEMPLOG" >>$TEMPCMD

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
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $TEMPCMD 

set FITS_TICKET = `$WFCODE/maketicket.csh gate=hmi.webFits_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
set MSK_TICKET = `$WFCODE/maketicket.csh gate=hmi.Marmask_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
set REMAP_TICKET = `$WFCODE/maketicket.csh gate=hmi.MrMap_latlon_720s_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
