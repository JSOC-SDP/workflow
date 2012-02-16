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

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set IQUVprogram = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/HMI_IQUV_averaging
set HMIprogram = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/HMI_observables
set HMI_segment = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_segment_module
set HMI_patch = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/hmi_patch_module

set IQUV_args = "-L wavelength=3 camid=0 cadence=135.0 npol=6 size=36 lev1=hmi.lev1 quicklook=0"
set OBS_args = "-L levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1"
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

# make qsub script
echo "#! /bin/csh -f " >$TEMPCMD
echo "setenv OMP_NUM_THREADS 8" >>$TEMPCMD
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

### Launch tickets to make 1k fits files

#@ t1 = `time_convert time=$WANTLOW`
#@ t2 = `time_convert time=$WANTHIGH`
#@ t = $t1
#while ( $t <= $t2 ) 
#  @ end = $t + 3600
#  set WLO = `time_convert s=$t zone=tai`
#  set WHI = `time_convert s=$end zone=tai`
#  set FITS_TICKET = `$WFCODE/maketicket.csh gate=hmi.webFits wantlow=$WLO wanthigh=$WHI action=5`
#  @ t = $end + 1
#end

## Remove limb darkening/create marmask

echo "/home/phil/jsoc/bin/linux_x86_64/hmi_limbdark in=hmi.Ic_720s\["$wantlow"-"$wanthigh"]  out=hmi.Ic_noLimbDark_720s -cnxf NONE >>&$TEMPLOG" >>$TEMPCMD

## Remap/Resize mags for synoptic charts

echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/fdlos2radial in=hmi.M_720s\["$wantlow"-"$wanthigh"] out=hmi.Mr_720s >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/mag2helio MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 RMAXFLAG=1 MCORLEV=1 in=hmi.M_720s\["$wantlow"-"$wanthigh"] out=hmi.Ml_hiresmap_720s >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/mag2helio MAPMMAX=5402 SINBDIVS=2160 LGSHIFT=3 CARRSTRETCH=1 RMAXFLAG=1 in=hmi.Mr_720s\["$wantlow"-"$wanthigh"] out=hmi.Mr_hiresmap_720s >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/resizemappingmag in=hmi.Ml_hiresmap_720s\["$wantlow"-"$wanthigh"] out=hmi.Ml_remap_720s nbin=3 >>&$TEMPLOG" >>$TEMPCMD
echo "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/resizemappingmag in=hmi.Mr_hiresmap_720s\["$wantlow"-"$wanthigh"] out=hmi.Mr_remap_720s nbin=3 >>&$TEMPLOG" >>$TEMPCMD

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
qsub -sync yes -e $TEMPLOG -o $TEMPLOG -q j8.q $TEMPCMD >> runlog

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

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus
