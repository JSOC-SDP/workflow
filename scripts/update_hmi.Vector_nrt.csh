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

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set ECLIPSEscript = /home/jsoc/pipeline/scripts/eclipse.pl
set IQUVprogram = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/HMI_IQUV_averaging
set HMIprogram = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/HMI_observables
set HMI_limbdark = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_limbdark
set HMI_segment = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_segment_module
#set HMI_patch = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_patch_module
set JV2TS = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/jv2ts
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert

#set IQUV_args = "wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1_nrt quicklook=1"
#set OBS_args = "levin=lev1p levout=lev15 wavelength=3 quicklook=1 camid=0 cadence=720.0 lev1=hmi.lev1_nrt"
##  CHANGED arguments 2012.10.16 for Sebastien's new observables code
set IQUV_args = "wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1_nrt quicklook=1 linearity=1"
set OBS_args = "levin=lev1p levout=lev15 wavelength=3 quicklook=1 camid=0 cadence=720.0 lev1=hmi.lev1_nrt smooth=1 linearity=1" 
set LD_args = "-cnxf NONE"
#set PATCH_args = "bb=hmi.Mpatch_720s_nrt"

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
echo "setenv OMP_NUM_THREADS 8" >>$TEMPCMD
echo "cd $HERE" >>$TEMPCMD
echo "hostname >>&$TEMPLOG" >>$TEMPCMD
echo "set echo >>&$TEMPLOG" >>$TEMPCMD
#echo "$ECLIPSEscript $wantlow $wanthigh nrt >>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus=0' >>&$TEMPCMD
echo 'set OBSstatus=0' >>&$TEMPCMD
#echo 'set PATstatus=0' >>&$TEMPCMD
echo 'set LDstatus=0' >>&$TEMPCMD

echo "$IQUVprogram begin="$wantlow"  end="$wanthigh $IQUV_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set IQUVstatus = $?' >>$TEMPCMD
echo 'if ($IQUVstatus) goto DONE' >>&$TEMPCMD
echo "$HMIprogram begin="$wantlow"  end="$wanthigh $OBS_args  ">>&$TEMPLOG" >>$TEMPCMD
echo 'set OBSstatus = $?' >>$TEMPCMD
echo 'if ($OBSstatus) goto DONE' >>&$TEMPCMD
echo "$HMI_limbdark in=hmi.Ic_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Ic_noLimbDark_720s_nrt "$LD_args" >>&$TEMPLOG" >>$TEMPCMD
echo 'set LDstatus = $?' >>$TEMPCMD
echo 'if ($LDstatus) goto DONE' >>&$TEMPCMD


## Remap/Resize mags for synoptic charts

echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/fdlos2radial in=hmi.M_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Mr_720s_nrt >>&$TEMPLOG" >>$TEMPCMD
#echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/mag2helio MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 RMAXFLAG=1 MCORLEV=1 in=hmi.M_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Ml_hiresmap_720s_nrt >>&$TEMPLOG" >> $TEMPCMD
#echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/mag2helio MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 RMAXFLAG=1 in=hmi.Mr_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Mr_hiresmap_720s_nrt >>&$TEMPLOG" >>$TEMPCMD

@ wantlow_s = `$TIME_CONVERT time=$wantlow`
@ wanthigh_s = `$TIME_CONVERT time=$wanthigh` 
@ diff = $wanthigh_s - $wantlow_s
set t = $diff's'
if ( $diff < 720s ) then
  set t = 720s
endif

echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 MCORLEV=1 in=hmi.M_720s_nrt\["$wantlow"/"$t"] v2hout=hmi.Ml_hiresmap_720s_nrt histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 >>&$TEMPLOG" >>$TEMPCMD
echo "$JV2TS MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 in=hmi.Mr_720s_nrt\["$wantlow"/"$t"] v2hout=hmi.Mr_hiresmap_720s_nrt histlink=none TSTART="$wantlow" TTOTAL="$t" TCHUNK="$t" MAPRMAX=0.998 MAPLGMAX=90.0 MAPLGMIN=-90 MAPBMAX=90.0 VCORLEV=0 NAN_BEYOND_RMAX=1 >>&$TEMPLOG" >>$TEMPCMD

echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/resizemappingmag in=hmi.Ml_hiresmap_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Ml_remap_720s_nrt nbin=3 >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/resizemappingmag in=hmi.Mr_hiresmap_720s_nrt\["$wantlow"-"$wanthigh"] out=hmi.Mr_remap_720s_nrt nbin=3 >>&$TEMPLOG" >>$TEMPCMD


# echo "$HMI_patch x=hmi.Marmask_720s_nrt["$wantlow"-"$wanthigh"]" "$PATCH_args" ">>&$TEMPLOG" >>$TEMPCMD
# echo 'set PATstatus = $?' >>$TEMPCMD
# echo 'if ($PATstatus) goto DONE' >>&$TEMPCMD

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
qsub -sync yes -e $TEMPLOG -o $TEMPLOG -q p8.q,j8.q $TEMPCMD 

set FITS_TICKET = `$WFCODE/maketicket.csh gate=hmi.webFits_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`
set MSK_TICKET = `$WFCODE/maketicket.csh gate=hmi.Marmask_nrt wantlow=$wantlow wanthigh=$wanthigh action=5`

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
