#
# Script to generate or fill in HMI cosmic ray tables
#
# this is run in the task instance directory where there is a 'ticket' file that specifies
# the request.

# XXXXXXXXXX test
 set echo
# XXXXXXXXXX test

set HERE = $cwd 
set LOG = $HERE/runlog
set BABBLE = $HERE/babble

date > $LOG

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set. >>$LOG
env >>$LOG
  exit 1
endif

set wantlow = `cat wantlow`
set wanthigh = `cat wanthigh`
echo "wanthigh = " $wanthigh >> $LOG
echo "wantlow = " $wantlow >> $LOG

set special = `grep SPECIAL ticket`
if ($#special > 0) then
echo variable special is $special >> $LOG
  set $special
echo variable SPECIAL is $SPECIAL >> $LOG
  if ($SPECIAL == NONE) then
    set CAMERA = 2
  else
    set $SPECIAL
echo now variable SPECIAL is $SPECIAL >> $LOG
  endif
else
  set CAMERA = 2
endif

# new way
set CAMERA=2
set special = `grep SPECIAL ticket`
if ($#special > 0) then
echo variable special is $special >> $LOG
  set $special
endif

# set QUALMASK = 0x2F000
set QUALMASK = 192512
set FFSN = `show_info hmi.lev1'['$wantlow'-'$wanthigh'][? (QUALITY & '$QUALMASK') = 0 ?]' n=1 -q key=FSN`
set LFSN = `show_info hmi.lev1'['$wantlow'-'$wanthigh'][? (QUALITY & '$QUALMASK') = 0 ?]' n=-1 -q key=FSN`

if ($LFSN <= $FFSN) then
  echo No good records to process between $wantlow and $wanthigh >>$LOG
  echo Allow OK status to let higher level code generate missing records. >>$LOG
  set retstatus = 0
  goto FAILUREEXIT
endif

show_info hmi.lev1'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? (QUALITY & '$QUALMASK') = 0 ?][? CAMERA = '$CAMERA' ?][? T_OBS > 0 ?]' -q key=FSN > FSN_lev1
show_info hmi.cosmic_rays'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? CAMERA = '$CAMERA' ?][? T_OBS > 0 ?]' -q key=FSN > FSN_cosmic
comm -23 FSN_lev1 FSN_cosmic > NOCR
set N_NOCR = `wc -l <NOCR`
echo "Lev1 records without cosmic ray records count = " $N_NOCR >>$LOG

if ($N_NOCR < 1) exit 0

set FIRST_FSN = `head -1 NOCR`
set LAST_FSN = `tail -1 NOCR`
# increase range to allow preceeding and following filtergrams
@ FIRST_FSN = $FIRST_FSN - 96
@ LAST_FSN = $LAST_FSN + 96

# get day of first FSN

# note that there may be a missing T_OBS along with a good T_OBS for a given FSN
set LFSNDAY = `show_info key=T_OBS -q hmi.lev1'[]['$LAST_FSN'][? T_OBS > 0 ?]'`
set yyyymmdd = `printf "%.10s" $LFSNDAY`
set mmdd = `echo $yyyymmdd | sed -e "s/.....//" -e "s/://" `

# For now assume that the list of missing CR records is contiguous, later use show_coverage key=FSN for
# special conditions on FIDs and do only the UNKs.

# Run Richard's flat field program in cosmic_rays only mode
# modified from module_flatfield_daily_qsub_48_CRonly2_PZT_FSN.pl

mkdir CRlogs
set CRLOG = $HERE/CRlogs
set module_flatfield = /home/production/cvs/JSOC/bin/linux_x86_64/module_flatfield
set cosmic_ray_post = /home/production/cvs/JSOC/bin/linux_x86_64/cosmic_ray_post

set QSUBCMD = CRY_$mmdd
cat > $QSUBCMD <<END
#
set echo
# 135, camera=1
set FIDLIST_1 = (10054 10055 10056 10057 10058 10059 10074 10075 10076 10077 10078 10079 \
                 10094 10095 10096 10097 10098 10099 10114 10115 10116 10117 10118 10119 \
                 10134 10135 10136 10137 10138 10139 10154 10155 10156 10157 10158 10159) 
# 45s, camera=2
set FIDLIST_2 = (10058 10059 10078 10079 10098 10099 10118 10119 10138 10139 10158 10159)

set ID = \$SGE_TASK_ID
if (\$ID <= 36) then
   set ID1 = \$ID
   set cadence = "135s"
   set camera = 1
   set fid = \$FIDLIST_1[\$ID1]
else
   @ ID2 = \$ID - 36
   set cadence = "45s"
   set camera = 2
   set fid = \$FIDLIST_2[\$ID2]
endif

$module_flatfield input_series=hmi.lev1 cadence=\$cadence cosmic_rays=1 flatfield=0 fid=\$fid camera=\$camera fsn_first=$FIRST_FSN fsn_last=$LAST_FSN datum=$yyyymmdd >>& $CRLOG/\$ID.log
END

qsub -q j.q -o $LOG -e $LOG -t 1-48 -sync yes $QSUBCMD

# Now do the post processing
set QSUBCMD = POS_$mmdd
cat > $QSUBCMD <<END
#
set echo
$cosmic_ray_post fsn_first=$FIRST_FSN fsn_last=$LAST_FSN camera=1 >>& $CRLOG/post.log
$cosmic_ray_post fsn_first=$FIRST_FSN fsn_last=$LAST_FSN camera=2 >>& $CRLOG/post.log
END
qsub -q j.q -o $LOG -e $LOG -sync yes $QSUBCMD

if ($status) then
  echo >>$LOG "Failure in at least one FID module_flatfield run"
  echo >>$LOG "But leave it to higher level code to deal with missing CR records"
  # set retstatus = 4
  # goto FAILUREEXIT
endif

# verify make of cosmic ray records

show_info hmi.cosmic_rays'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? CAMERA = '$CAMERA' ?][? T_OBS > 0 ?]' -q key=FSN > FSN_cosmic
comm -23 FSN_lev1 FSN_cosmic > NOCR
set N_NOCR = `wc -l <NOCR`
echo "Lev1 records now without cosmic ray records count = " $N_NOCR >>$LOG

if ($N_NOCR > 10) then
  echo "$N_NOCR lev1 records are missing matching cosmic_ray records. " >>FAIL_reason
  echo "The missing cosmic_ray records are FSNs: ">>FAIL_reason
  cat NOCR >>FAIL_reason
  echo " " >>FAIL_reason
  # set retstatus = 3
  # goto FAILUREEXIT
endif

exit 0

FAILUREEXIT:

echo "No CR records available" >>$LOG
exit $retstatus
