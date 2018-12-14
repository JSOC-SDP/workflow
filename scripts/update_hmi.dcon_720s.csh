#! /bin/csh -f

# Script to make HMI lev1.5 observables from HMI lev1 data
# #
#
# # XXXXXXXXXX test
# # set echo
# # XXXXXXXXXX test


set HERE = $cwd 

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub

foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set S = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/stokes_dcon
set OBS =  /home/jsoc/cvs/Development/JSOC/bin/linux_avx/HMI_observables_dconS

# round times to a slot
set indexlow = `index_convert ds=$product $key=$WANTLOW`
set indexhigh = `index_convert ds=$product $key=$WANTHIGH`
@ indexhigh = $indexhigh - 1
set wantlow = `index_convert ds=$product $key"_index"=$indexlow`
set wanthigh = `index_convert ds=$product $key"_index"=$indexhigh`

# check to see if we need modC or modL observables

###########################################################################################
#   FSN                         MODE    DATE
#     4612150 -  88861016	modC	2010.05.01_00:00:00_TAI - 2015.05.05_21:08:57_TAI
#    88861017 -  88858906       modL    2015.05.05_21:08:59_TAI - 2015.05.05_20:03:01_TAI
#    88858907 -  89311496	modC    2015.05.05_20:03:03_TAI - 2015.05.15_21:01:27_TAI
#    89311497 -  89271149	modL	2015.05.15_21:01:29_TAI - 2015.05.15_00:00:37_TAI
#    89271150 - 103012715       modC	2015.05.15_00:00:39_TAI - 2016.03.08_11:31:27_TAI
#   103012716 - 102999325 	modL	2016.03.08_11:31:29_TAI - 2016.03.08_04:33:01_TAI
#   102999326 - 104683792	modC	2016.03.08_04:33:03_TAI - 2016.04.13_19:13:28_TAI
#   104683793 - present		modL	2016.04.13_19:13:31_TAI - present

# times in seconds

set C1 = (1051747200 1209935337)
set C2 = (1209931383 1210798887)
set C3 = (1210723239 1236511887)
set C4 = (1236486783 1239650008)

set L1 = (1209935339 1209931381)
set L2 = (1210798889 1210723237)
set L3 = (1236511889 1236486781)
set L4 = (1239650011 2303683200)

@ wantlow_s = `$TIME_CONVERT time=$wantlow`
@ wanthigh_s = `$TIME_CONVERT time=$wanthigh`

if ( ($wantlow_s >= $C1[1] && $wanthigh_s <= $C1[2]) || ($wantlow_s >= $C2[1] && $wanthigh_s <= $C2[2]) || ($wantlow_s >= $C3[1] && $wanthigh_s <= $C3[2]) || ($wantlow_s >= $C4[1] && $wanthigh_s <= $C4[2]) ) then
   # modC observables args
   set ARGS = "-L -V levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1 smooth=1 linearity=1"
else if ( ($wantlow_s >= $L1[1] && $wanthigh_s <= $L1[2]) || ($wantlow_s >= $L2[1] && $wanthigh_s <= $L2[2]) || ($wantlow_s >= $L3[1] && $wanthigh_s <= $L3[2]) || ($wantlow_s >= $L4[1] && $wanthigh_s <= $L4[2]) ) then
   # modL observables args
   set ARGS = "-L -V levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=3 cadence=720.0 lev1=hmi.lev1 smooth=1 linearity=1
else
  echo "Check times.  Your request may require separate runs for modC and modL."
  echo "FSN                         MODE    DATE"
  echo "  4612150 -  88861016       modC    2010.05.01_00:00:00_TAI - 2015.05.05_21:08:57_TAI"
  echo " 88861017 -  88858906       modL    2015.05.05_21:08:59_TAI - 2015.05.05_20:03:01_TAI"
  echo " 88858907 -  89311496       modC    2015.05.05_20:03:03_TAI - 2015.05.15_21:01:27_TAI"
  echo " 89311497 -  89271149       modL    2015.05.15_21:01:29_TAI - 2015.05.15_00:00:37_TAI"
  echo " 89271150 - 103012715       modC    2015.05.15_00:00:39_TAI - 2016.03.08_11:31:27_TAI"
  echo "103012716 - 102999325       modL    2016.03.08_11:31:29_TAI - 2016.03.08_04:33:01_TAI"
  echo "102999326 - 104683792       modC    2016.03.08_04:33:03_TAI - 2016.04.13_19:13:28_TAI"
  echo "104683793 - present         modL    2016.04.13_19:13:31_TAI - present"
  exit
endif

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = DC720
set qsubname = $timename$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
touch $HERE/qsub_running
echo 6 > $HERE/Sretstatus

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
echo "setenv OMP_NUM_THREADS 4" >>$CMD
echo "$S in=hmi.S_720s'['$wantlow'-'$wanthigh']' out=hmi.S_720s_dconS psf=hmi.psf " >> $CMD
echo 'set Sretstatus = $?' >>$CMD
echo 'echo $Sretstatus >' "$HERE/Sretstatus" >>$CMD
echo 'if ($Sretstatus) goto DONE' >> $CMD

echo "$OBS begin=$wantlow end=$wanthigh $ARGS" >> $CMD
echo 'set obsretstatus = $?' >>$CMD
echo 'echo $obsretstatus >' "$HERE/obsretstatus" >>$CMD

echo 'DONE:' >> $CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -pe smp 4 -e $LOG -o $LOG -q $QUE $CMD >> $LOG
