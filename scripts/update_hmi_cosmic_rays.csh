#! /bin/csh -f
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

# post processing flag.  Set to 1 for cosmic_rays to be made in su_production.cosmic_rays
# with cosmic_ray_post program used to merge and move to hmi.cosmic_rays
# set to 1 to enable, otherwise only hmi.cosmic_rays will be used.
set DO_POST = 0

date > $LOG

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

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
hostname >> $LOG
date >> $LOG
echo "wanthigh = " $wanthigh >> $LOG
echo "wantlow = " $wantlow >> $LOG
set ACTION = `grep ACTION ticket`
set $ACTION

set CAMERA = 0

# process SPECIAL ticket args
set FIXMISSING = 0
set SPECIAL = (`grep SPECIAL ticket`)
set $SPECIAL
set special = (`echo $SPECIAL | sed -e 's/,/ /g'`)
# now special contains a=b c=d
set NSPECARGS = $#special
set SPECARG = 1
while ($SPECARG <= $NSPECARGS)
  echo Extracting SPECIAL component $SPECARG which is $special[$SPECARG]
  if ($special[$SPECARG] == NONE) then
  else
    set $special[$SPECARG]
  endif
  @ SPECARG = $SPECARG + 1
end

if ($CAMERA > 0) then
  set CAMARG = '[? CAMERA='$CAMERA' ?]'
else
  set CAMARG
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

# get expected list of cosmic_ray records
show_info hmi.lev1'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000  AND HFTSACID < 2000 ?][? (QUALITY & '$QUALMASK') = 0 ?][? T_OBS > 0 ?]'"$CAMARG" -q key=FSN > FSN_lev1

set N_NOCR = 100000000
# unless a SPECIAL arg of FIXMISSING=1 is present, just wait here until all records are present.  I.e. convert to a proper action=3
if ($ACTION == 4 && $FIXMISSING == 0) then
  set loopcount = 0
  while ($N_NOCR > 0)
    show_info hmi.cosmic_rays'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? T_OBS > 0 ?]'"$CAMARG" -q key=FSN > FSN_cosmic
    comm -23 FSN_lev1 FSN_cosmic > NOCR
    set N_NOCR = `wc -l <NOCR`
    echo "Lev1 records without cosmic ray records count = " $N_NOCR >>$LOG
    if ($N_NOCR < 1) exit 0
    if ($loopcount > 576) then
      echo "FAIL - give up waiting after 4 days." >>$LOG
      echo "FAIL - give up waiting after 4 days." >>FAIL_reason
      cat N_NOCR >>FAIL_reason
      echo " " >>FAIL_reason
      set retstat = 9
      goto FAILUREEXIT
    endif
    sleep 600
    @ loopcount = $loopcount + 1
  end
endif

if ($ACTION == 4) then
  show_info hmi.cosmic_rays'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? T_OBS > 0 ?]'"$CAMARG" -q key=FSN > FSN_cosmic
  comm -23 FSN_lev1 FSN_cosmic > NOCR
  set N_NOCR = `wc -l <NOCR`
  echo "Lev1 records without cosmic ray records count = " $N_NOCR >>$LOG

  if ($N_NOCR < 1) exit 0

  set FIRST_FSN = `head -1 NOCR`
  set LAST_FSN = `tail -1 NOCR`
else # ACTION == 5
  set FIRST_FSN = $FFSN
  set LAST_FSN = $LFSN
endif

# increase range to allow preceeding and following filtergrams
@ FIRST_FSN = $FIRST_FSN - 96
#  set CHK_FSN1 = `show_info hmi.lev1'[? FSN = '$FIRST_FSN' ?]' n=-1 -q key=T_OBS`
  set CHK_FSN1 = `show_info hmi.lev1'[][$FIRST_FSN]' n=1 -q key=T_OBS_index`
    while ( $CHK_FSN1 < 0 ) 
#      @ FIRST_FSN =  $FIRST_FSN - 1
#      set CHK_FSN1 = `show_info hmi.lev1'[? FSN = '$FIRST_FSN' ?]' n=-1 -q key=T_OBS`
      @ FIRST_FSN =  $FIRST_FSN + 1
      set CHK_FSN1 = `show_info hmi.lev1'[][$FIRST_FSN]' n=1 -q key=T_OBS_index` 
    end

@ LAST_FSN = $LAST_FSN + 96
#  set CHK_FSN2 = `show_info hmi.lev1'[? FSN = '$LAST_FSN' ?]' n=-1 -q key=T_OBS`
  set CHK_FSN2 = `show_info hmi.lev1'[][$LAST_FSN]' n=1 -q key=T_OBS_index`
    while ( $CHK_FSN2 < 0 ) 
#      @ LAST_FSN =  $LAST_FSN + 1
#      set CHK_FSN2 = `show_info hmi.lev1'[? FSN = '$LAST_FSN' ?]' n=-1 -q key=T_OBS`
      @ LAST_FSN =  $LAST_FSN - 1
      set CHK_FSN2 = `show_info hmi.lev1'[][$LAST_FSN]' n=1 -q key=T_OBS_index`
    end


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
# set module_flatfield = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/module_flatfield
set module_flatfield = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/module_flatfield
set cosmic_ray_post = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/cosmic_ray_post

set QSUBCMD = CRY_$mmdd
set QSTAT = $HERE/CRY_status
touch $QSTAT
cat > $QSUBCMD <<ENDCAT
#
#\$ -cwd
set echo
echo $HOST 
setenv OMP_NUM_THREADS 8
ENDCAT

# Do these serially in a single node
# 135, camera=1
set FIDLIST_1 = (10054 10055 10056 10057 10058 10059 10074 10075 10076 10077 10078 10079 \
                 10094 10095 10096 10097 10098 10099 10114 10115 10116 10117 10118 10119 \
                 10134 10135 10136 10137 10138 10139 10154 10155 10156 10157 10158 10159) 
# 45s, camera=2
set FIDLIST_2 = (10058 10059 10078 10079 10098 10099 10118 10119 10138 10139 10158 10159)

# set ID = \$SGE_TASK_ID
set ID = 1
while ($ID <= 48)
  if ($ID <= 36) then
     set ID1 = $ID
     set cadence = "135s"
     set camera = 1
     set fid = $FIDLIST_1[$ID1]
  else
     @ ID2 = $ID - 36
     set cadence = "45s"
     set camera = 2
     set fid = $FIDLIST_2[$ID2]
  endif

  if ($DO_POST) then
    cat >>$QSUBCMD <<ENDCAT
$module_flatfield -L input_series=hmi.lev1 cadence=$cadence cosmic_rays=1 flatfield=0 fid=$fid camera=$camera fsn_first=$FIRST_FSN fsn_last=$LAST_FSN datum=$yyyymmdd >>& $CRLOG/$ID.log
if (\$status) echo  "$ID error" >> $QSTAT
ENDCAT
  else
    cat >>$QSUBCMD <<ENDCAT
$module_flatfield -L input_series=hmi.lev1 cosmic_ray_series=hmi.cosmic_rays cadence=$cadence cosmic_rays=1 flatfield=0 fid=$fid camera=$camera fsn_first=$FIRST_FSN fsn_last=$LAST_FSN datum=$yyyymmdd >>& $CRLOG/$ID.log
if (\$status) echo  "$ID error" >> $QSTAT
ENDCAT
  endif

  @ ID = $ID + 1
end

set LOG = `echo $LOG | sed "s/^\/auto//"`
$QSUB -q $QUE -o $LOG -e $LOG -sync yes $QSUBCMD
set QSUBSTATUS = $status
if ($QSUBSTATUS) then
  echo qsub failed with exit status $QSUBSTATUS >>$LOG
  set retstatus = 11
  echo qsub failure >>$FAIL_REASON
  goto FAILUREEXIT
endif

set QSTAT_errcnt = `wc -l < $QSTAT`
if ($QSTAT_errcnt) then
  echo $QSTAT_errcnt " status errors in module_flatfield" >>$LOG
  echo $QSTAT_errcnt " status errors in module_flatfield" >>$FAIL_reason
  set retstatus = 7
  goto FAILUREEXIT
endif

if ($DO_POST) then
# Now do the post processing
  set QSUBCMD = POS_$mmdd
  set QSTAT = $HERE/POS_status
  touch $QSTAT
  cat > $QSUBCMD <<ENDCAT
#
set echo
setenv OMP_NUM_THREADS 1
$cosmic_ray_post -L input_series=su_production.cosmic_rays fsn_first=$FIRST_FSN fsn_last=$LAST_FSN camera=1 >>& $CRLOG/post.log
if (\$status) echo  "Cam1 error" >> $QSTAT
$cosmic_ray_post -L input_series=su_production.cosmic_rays fsn_first=$FIRST_FSN fsn_last=$LAST_FSN camera=2 >>& $CRLOG/post.log
if (\$status) echo  "Cam2 error" >> $QSTAT
ENDCAT
set LOG = `echo $LOG | sed "s/^\/auto//"`
  $QSUB -q $QUE -o $LOG -e $LOG -sync yes $QSUBCMD

  set QSTAT_errcnt = `wc -l < $QSTAT`
  if ($QSTAT_errcnt) then
    echo $QSTAT_errcnt " status errors in cosmic_ray_post" >>$LOG
    echo $QSTAT_errcnt " status errors in cosmic_ray_post" >>$FAIL_reason
    set retstatus = 7
    goto FAILUREEXIT
  endif

endif # DO_POST

# verify make of cosmic ray records

show_info hmi.cosmic_rays'[]['$FFSN'-'$LFSN'][? FID >= 10050 AND FID < 11000 ?][? T_OBS > 0 ?]'"$CAMARG" -q key=FSN > FSN_cosmic
comm -23 FSN_lev1 FSN_cosmic > NOCR
set N_NOCR = `wc -l <NOCR`
echo "Lev1 records now without cosmic ray records count = " $N_NOCR >>$LOG

if ($N_NOCR > 10) then
  echo "$N_NOCR lev1 records are still missing matching cosmic_ray records. " >>FAIL_reason
  echo "The missing cosmic_ray records are FSNs: ">>FAIL_reason
  cat NOCR >>FAIL_reason
  echo " " >>FAIL_reason
  set retstatus = 3
  goto FAILUREEXIT
endif

exit 0

FAILUREEXIT:

echo "No CR records available" >>$LOG
exit $retstatus
