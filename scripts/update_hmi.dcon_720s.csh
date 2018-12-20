#! /bin/csh -f

# Script to make HMI lev1.5 720s observables from scattered light corrected stokes.
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
#     4612150 -  88858905	modC	2010.05.01_00:00:00_TAI - 2015.05.05_19:54:44_TAI
#    88858906 -  88861017       modL    2015.05.05_20:03:01_TAI - 2015.05.05_21:08:59_TAI
#    88861018 -  89271148	modC    2015.05.05_21:11:16_TAI - 2015.05.15_00:00:35_TAI
#    89271149 -  89311497	modL	2015.05.15_00:00:37_TAI - 2015.05.15_21:01:29_TAI
#    89311498 - 102999324       modC	2015.05.15_21:02:16_TAI - 2016.03.08_04:32:59_TAI
#   102999325 - 103012716	modL	2016.03.08_04:33:01_TAI - 2016.03.08_11:31:29_TAI
#   103012717 - 104683792	modC	2016.03.08_11:33:01_TAI - 2016.04.13_19:13:28_TAI
#   104683793 - present		modL	2016.04.13_19:13:31_TAI - present

# times in seconds

set C1 = (1051747200 1209930884)
set C2 = (1209935476 1210723235)
set C3 = (1210798936 1236486779)
set C4 = (1236511981 1239650008)

set L1 = (1209931381 1209935339)
set L2 = (1210723237 1210798889)
set L3 = (1236486781 1236511889)
set L4 = (1239650011 2303683200)

@ wantlow_s = `$TIME_CONVERT time=$wantlow`
@ wanthigh_s = `$TIME_CONVERT time=$wanthigh`

set timestr = `echo $wantlow  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = DC720
set qsubname = $timename$timestr

set LOG = $HERE/runlog
set CMD = $HERE/$qsubname
touch $HERE/qsub_running
echo 6 > $HERE/Sretstatus

if ( ($wantlow_s >= $C1[1] && $wanthigh_s <= $C1[2]) || ($wantlow_s >= $C2[1] && $wanthigh_s <= $C2[2]) || ($wantlow_s >= $C3[1] && $wanthigh_s <= $C3[2]) || ($wantlow_s >= $C4[1] && $wanthigh_s <= $C4[2]) ) then
   # modC observables args
   set mod = C
   set ARGS = "-L -V levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=0 cadence=720.0 lev1=hmi.lev1 smooth=1 linearity=1"
else if ( ($wantlow_s >= $L1[1] && $wanthigh_s <= $L1[2]) || ($wantlow_s >= $L2[1] && $wanthigh_s <= $L2[2]) || ($wantlow_s >= $L3[1] && $wanthigh_s <= $L3[2]) || ($wantlow_s >= $L4[1] && $wanthigh_s <= $L4[2]) ) then
   # modL observables args
   set mod = L
   set ARGS = "-L -V levin=lev1p levout=lev15 wavelength=3 quicklook=0 camid=3 cadence=720.0 lev1=hmi.lev1 smooth=1 linearity=1"
else
  set mod = NOOP
  echo "Check times.  Your request may require separate runs for modC and modL." >> $LOG
  echo "FSN                         MODE    DATE" >> $LOG
  echo "  4612150 -  88861016       modC    2010.05.01_00:00:00_TAI - 2015.05.05_21:08:57_TAI" >> $LOG
  echo " 88861017 -  88858906       modL    2015.05.05_21:08:59_TAI - 2015.05.05_20:03:01_TAI" >> $LOG
  echo " 88858907 -  89311496       modC    2015.05.05_20:03:03_TAI - 2015.05.15_21:01:27_TAI" >> $LOG
  echo " 89311497 -  89271149       modL    2015.05.15_21:01:29_TAI - 2015.05.15_00:00:37_TAI" >> $LOG
  echo " 89271150 - 103012715       modC    2015.05.15_00:00:39_TAI - 2016.03.08_11:31:27_TAI" >> $LOG
  echo "103012716 - 102999325       modL    2016.03.08_11:31:29_TAI - 2016.03.08_04:33:01_TAI" >> $LOG
  echo "102999326 - 104683792       modC    2016.03.08_04:33:03_TAI - 2016.04.13_19:13:28_TAI" >> $LOG
  echo "104683793 - present         modL    2016.04.13_19:13:31_TAI - present" >> $LOG
  echo 10 > $HERE/Sretstatus
  exit 10
endif

echo "hostname >>&$LOG" >$CMD
echo "set echo >>&$LOG" >>$CMD
echo "setenv OMP_NUM_THREADS 4" >>$CMD
echo "$S in=hmi.S_720s'['$wantlow'-'$wanthigh'][? quality = 0 ?]' out=hmi.S_720s_dconS psf=hmi.psf " >> $CMD
echo 'set Sretstatus = $?' >>$CMD
echo 'echo $Sretstatus >' "$HERE/Sretstatus" >>$CMD
echo 'if ($Sretstatus) goto DONE' >> $CMD

if ( $mod == C ) then
  echo "echo Making ModC observables" >> $CMD
else if ( $mod == L ) then
  echo "echo Making ModL observables" >> $CMD
endif
echo "$OBS begin=$wantlow end=$wanthigh $ARGS" >> $CMD
echo 'set obsretstatus = $?' >>$CMD
echo 'echo $obsretstatus >' "$HERE/obsretstatus" >>$CMD

echo 'DONE:' >> $CMD
echo "rm -f $HERE/qsub_running" >>$CMD

$QSUB -sync yes -pe smp 4 -e $LOG -o $LOG -q $QUE $CMD >> $LOG

