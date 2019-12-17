#! /bin/csh -f

###
### MHarps MUST be processed in order.  It's OK to have a gap, but
### NOT OK to process them out of order.  If a problem arises, they
### must be restarted from the last good record.  To do that:
###
### 1.  mv /tmp28/jsocprod/HARPS/nrt/ /tmp28/jsocprod/HARPS/nrt.<DATE>
### 2.  mkdir -p /tmp28/jsocprod/HARPS/nrt/Tracks/jsoc
### 3.  set dir = `show_info -p hmi.Mharp_log_720s_nrt\[<LAST GOOD T_REC>]`
### 4.  cp $dir/track-post.mat /tmp28/jsocprod/HARPS/nrt/Tracks/jsoc/track-prior.mat
### 5.  rerun harps by hand to catch up:  /home/jeneen/campaigns/scripts/hmi/do_Mharps_by_hand.csh <START> <END>
###     example:  /home/jeneen/campaigns/scripts/hmi/do_Mharps_by_hand.csh 2012.03.01_10:12:00_TAI 2012.03.01_14:24:00_TAI 
### 6.  restart NRT HARPs pipeline:  /home/jsoc/cvs/Development/JSOC/proj/workflow/maketicket.csh gate=repeat_harps_nrt wantlow=<NEXT TREC> wanthigh=<NEXT TREC> action=5
### 7.  Note that the <NEXT TREC> in #6 can be any date, since the script ignores that date so you can't accidentally make it do bad, out of order things.
###
### If things go REALLY bad and you want to scrap all existing harps and start over,
### you need to remove the existing records and seed the series with the first harp and then rerun them by hand and/or
### restart the pipeline:
###
### 1.  create_series -f /home/jsocprod/turmon/new_nrt/hmi.Mharp_log_720s_nrt.jsd
### 2.  create_series -f /home/jsocprod/turmon/new_nrt/hmi.Mharp_720s_nrt.jsd
### 3.  edit /home/jsocprod/turmon/old/test_nrt.csh with correct starting time
### 4.  run:  qsub -e turmon/old/nrt.elog -o turmon/old/nrt.olog -q o.q test_nrt.csh
### 5.  Note that the o.q in #5 is the only queue that has matlab, and so the only place you can run harp processing
### 4.  run by hand to catch up, if necessary:   /home/jeneen/campaigns/scripts/hmi/do_Mharps_by_hand.csh <START> <END>
### 5.  restart pipeline:  /home/jsoc/cvs/Development/JSOC/proj/workflow/maketicket.csh gate=repeat_harps_nrt wantlow=<NEXT TREC> wanthigh=<NEXT TREC> action=5
### 6.  Note that the <NEXT TREC> in #5 can be any date, since the script ignores that date so you can't accidentally make it do bad, out of order things.
###
### If the harps pipeline is running amok for some reason, shut down the gate:
### 
### 1.  vi /home/jsoc/pipeline/gates/repeat_harp_nrt/gatestatus and change "ACTIVE" to "HOLD"
### 2.  don't change it back to ACTIVE unless you're absolutely sure everything has been cleaned up.
###


set noglob
set HERE = $cwd
set TEMPLOG = $HERE/runlog
set CMD = $HERE/MHarp_nrt
#echo 6 > $HERE/retstatus

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = p.q,j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q
  set QSUB = /SGE2/bin/lx-amd64/qsub
endif

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set MHarp = /home/jsoc/cvs/Development/JSOC/proj/mag/harp/scripts/track_and_ingest_mharp.sh

# Make sure there isn't a runaway process happening.  There should NEVER be more than one
# harps nrt job running at one time!  If there is, put a hold on the gate, clean up and
# start again.

@ i = 0
set num_running = `ls -1 $WFDIR/tasks/update_hmi.harp_nrt/active | grep -v root | wc -l` 
while ( $num_running > 1 ) 
  @ i++
  if ( $i == 5 ) then
    echo HOLD > $WORKFLOW_DATA/gates/repeat_harp_nrt/gatestatus
    exit
  else
    echo HOLD > $WORKFLOW_DATA/gates/repeat_harp_nrt/gatestatus
    mv $HERE/active/update_hmi.harp_nrt-2* $HERE/done/
    rm $WFDIR/gates/repeat_harp_nrt/new_tickets/*
    echo ACTIVE > $WORKFLOW_DATA/gates/repeat_harp_nrt/gatestatus
    sleep 30
    set num_running = `ls -1 $WFDIR/tasks/update_hmi.harp_nrt/active | grep -v root | wc -l`
    if ( $num_running == 0 ) then
      $WFCODE/maketicket.csh gate=repeat_harp_nrt wantlow=2013.01.01 wanthigh=2013.01.01 action=5
      exit
    endif
  endif
end
  
foreach ATTR (WANTLOW WANTHIGH GATE)
  set ATTRTXT = `grep $ATTR ticket`
  set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

# NOTE:  there may be 720s mags without masks due to quality bits in the VEC data.

#set echo

# Look for harps that need to be processed

set last_mask = `$SHOW_INFO -q hmi.Marmask_720s_nrt\[\$] key=t_rec`
@ last_mask_s = `$TIME_CONVERT time=$last_mask`

# Check to make sure there is good M record

set maskMag = `$SHOW_INFO -q hmi.M_720s_nrt'['$last_mask']' key=t_obs`
@ maskMag_s = `$TIME_CONVERT time=$maskMag`
@ i = 1
@ next_mag_s = $last_mask_s + 720
set next_mag = `$TIME_CONVERT s=$next_mag_s`
#set last_harp = `$SHOW_INFO -q 'hmi.MHarp_720s_nrt[][]' key=t_rec n=-1000 | sort -u | tail -1`
set last_harp = `$SHOW_INFO -q 'hmi.MHarp_720s_nrt[][$]' key=t_rec n=-1`


while ( $i <= 270 )  # 9 hours, allowing for long maneuvers 
  @ last_mask_recnum = `$SHOW_INFO hmi.marmask_720s_nrt'[$]' -rq`
  @ prev_mask_recnum = $last_mask_recnum - 1
  @ good_mags = `$SHOW_INFO hmi.marmask_720s_nrt'[:#'$prev_mask_recnum'/2][? quality > 0 ?]' -qc`
  set last_T = `$SHOW_INFO hmi.marmask_720s_nrt'[:#'$last_mask_recnum'/2][? quality > 0 ?]' -q key=t_obs`
  set prev_T = `$SHOW_INFO hmi.marmask_720s_nrt'[:#'$prev_mask_recnum'/2][? quality > 0 ?]' -q key=t_obs`
  @ last_T_s = `$TIME_CONVERT time=$last_T`
  @ prev_T_s = `$TIME_CONVERT time=$prev_T`
  @ Tdiff = $last_T_s - $prev_T_s
  if ( ($good_mags < 2) && ($Tdiff == 720) ) then   
    echo "$i"/"270 good_mags:  $good_mags  last mask:  $last_mask  last harp:  $last_harp" > $HERE/NO_GOOD_DATA
    sleep 120
    @ i++
  else
    @ i = 271
  endif
end

rm $HERE/NO_GOOD_MAG

#set last_harp = `$SHOW_INFO -q 'hmi.MHarp_720s_nrt[][]' key=t_rec n=-1000 | sort -u | tail -1` 
set last_harp = `$SHOW_INFO -q 'hmi.MHarp_720s_nrt[][$]' key=t_rec n=-1`
@ last_harp_s = `$TIME_CONVERT time=$last_harp`
@ harp_lag = $last_mask_s - $last_harp_s
@ last_processed = `cat $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/last_processed`
@ process_lag = $last_mask_s - $last_processed
set last_mag = `$SHOW_INFO -q 'hmi.M_720s_nrt[]' key=t_rec n=-1`
set last_good_mag = `$SHOW_INFO -q 'hmi.M_720s_nrt[][? quality > 0 ?]' key=t_rec n=-1`
@ last_mag_s = `$TIME_CONVERT time=$last_mag`
@ last_good_mag_s = `$TIME_CONVERT time=$last_good_mag`
@ mag_lag = $last_mag_s - $last_good_mag_s 
set last_two_good_mag_r = `$SHOW_INFO -q 'hmi.M_720s_nrt[][? quality > 0 ?]' -r n=-2`
@ rdiff = $last_two_good_mag_r[2] - $last_two_good_mag_r[1]
set last_mask = `$SHOW_INFO -q hmi.Marmask_720s_nrt\[\$] key=t_rec`
@ last_mask_s = `$TIME_CONVERT time=$last_mask`

#while ( ($harp_lag < 1440) || (-e $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING) || ($mag_lag > 0) || ($rdiff != 1) )
while ( ($harp_lag < 1440) || ($process_lag < 1440) || (-e $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING) || ($mag_lag > 0) || ($rdiff != 1) )
  if ( $harp_lag < 1440) then
    echo $harp_lag > $HERE/WAITING_HARP_LAG
  else if ( $process_lag < 1440 && `cat $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/numHarps` == 0 ) then
    echo $process_lag > $HERE/NO_HARPS
  else if ( -e $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING) then
    touch $HERE/WAITING_QSUB_RUNNING
  else if ( $mag_lag > 0 ) then
    echo $mag_lag > $HERE/WAITING_MAG_LAG
  endif
  sleep 120
#  set last_harp = `$SHOW_INFO -q 'hmi.MHarp_720s_nrt[][]' key=t_rec n=-1000 | sort -u | tail -1`
  set last_harp = `$SHOW_INFO -q 'hmi.MHarp_720s_nrt[][$]' key=t_rec n=-1`
  @ last_harp_s = `$TIME_CONVERT time=$last_harp`
  set last_mask = `$SHOW_INFO -q hmi.Marmask_720s_nrt\[\$] key=t_rec`
  @ last_mask_s = `$TIME_CONVERT time=$last_mask`
  @ harp_lag = $last_mask_s - $last_harp_s
  @ last_processed = `cat $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/last_processed`
  @ process_lag = $last_mask_s - $last_processed
  set last_mag = `$SHOW_INFO -q 'hmi.M_720s_nrt[]' key=t_rec n=-1`
  set last_good_mag = `$SHOW_INFO -q 'hmi.M_720s_nrt[][? quality > 0 ?]' key=t_rec n=-1`
  @ last_mag_s = `$TIME_CONVERT time=$last_mag`
  @ last_good_mag_s = `$TIME_CONVERT time=$last_good_mag`
  @ mag_lag = $last_mag_s - $last_good_mag_s
  set last_two_good_mag_r = `$SHOW_INFO -q 'hmi.M_720s_nrt[][? quality > 0 ?]' -r n=-2`
  @ rdiff = $last_two_good_mag_r[2] - $last_two_good_mag_r[1]
end

rm $HERE/WAITING*


if ( $harp_lag >= 3600 ) then
  @ check_next_s = $last_mask_s - 3600
  while ( $check_next_s <= $last_mask_s )
    set check_next = `$TIME_CONVERT zone=tai s=$check_next_s`
    @ check_next_count = `$SHOW_INFO -q hmi.Marmask_720s_nrt\[$check_next] -c`
    if ( $check_next_count == 1 ) then
      set t = $check_next
      @ check_next_s = $last_mask_s + 1
    else
      @ check_next_s = $check_next_s + 720
    endif
  end
  set WANTLOW = $t
  set WANTHIGH = $last_mask
  set nextH = `$SHOW_INFO -q hmi.Marmask_720s_nrt\[$t'-'$last_mask] key=t_rec n=1`
  @ nextH_s = `$TIME_CONVERT time=$nextH` + 720
#  @ nextH_s = `$TIME_CONVERT time=$nextH
else
  @ nextH_s = $last_harp_s + 720
#   @ nextH_s = $last_harp_s
endif

# make qsub script

echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >>$CMD
echo "hostname >>&$TEMPLOG" >>$CMD
echo "set echo" >>$CMD

echo "setenv TMPDIR /tmp28/jsocprod/HARPS/nrt/" >>$CMD
echo "set MHarpstatus = 0" >>&$CMD
set Htimes

while ( $nextH_s < $last_mask_s )
  if ( `cat $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/numHarps` == 0 ) then
    @ nextH_s = $last_mask_s - 720
  endif
  echo $nextH_s > $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/last_processed
  set nextH = `$TIME_CONVERT s=$nextH_s zone=TAI`
  
  # make sure mask exists
  set a = `$SHOW_INFO -q hmi.Marmask_720s_nrt\["$nextH"] -c`
  if ( $a == 0 ) then
    echo "no Mask data for $nextH"
    @ nextH_s = $nextH_s + 720 
  else
    set Htimes = ($Htimes $nextH)
    echo "touch $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING" >> $CMD
    echo "$MHarp -n /tmp28/jsocprod/HARPS/nrt hmi.Marmask_720s_nrt\[$nextH] hmi.Mharp_720s_nrt hmi.Mharp_log_720s_nrt" >> $CMD
    echo 'set MHarpstatus = $?' >> $CMD
    echo 'if ($MHarpstatus) goto DONE' >>&$CMD
    echo "/home/jsoc/cvs/Development/JSOC/proj/workflow/scripts/harp_nrt_movies.csh" >> $CMD
    @ nextH_s = $nextH_s + 720
  endif
end
echo 'DONE:' >>$CMD
echo 'echo $MHarpstatus >retstatus' >> $CMD
#echo HOLD > $WORKFLOW_DATA/gates/repeat_harp_nrt/gatestatus
#echo "/home/jsoc/pipeline/scripts/harp_nrt_movies.csh" >> $CMD
#echo "/home/jsoc/cvs/Development/JSOC/proj/workflow/scripts/harp_nrt_movies.csh" >> $CMD
echo 'echo $MHarpstatus >retstatus' >>$CMD
echo "rm $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING" >> $CMD

# execute qsub script


touch $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING
set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $CMD

# submit next harp and VFISV tickets

sleep 15
if (-e $HERE/retstatus) set retstatus = `cat $HERE/retstatus`
@ num_harps = `$SHOW_INFO hmi.mharp_720s_nrt'[]['$WANTLOW'-'$WANTHIGH']' -qc`
echo "number of harps:  $num_harps" >> $TEMPLOG
echo $num_harps > $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/numHarps
echo "TIME:$WANTLOW   HARPS:$num_harps" > /web/jsoc/htdocs/data/hmi/HARPs_images/latest_HARP_info

if ( ($retstatus == 0) && ($num_harps > 0) ) then
  @ i = 1
  while ( $i <= $#Htimes )
    set WANT = $Htimes[$i]
    if ( $num_harps > 0 ) then
      set ME_TICKET = `$WFCODE/maketicket.csh gate=hmi.ME_720s_fd10_nrt wantlow=$WANT wanthigh=$WANT action=5`
    endif
    @ i++
  end
endif

set min = `echo $WANTLOW | awk -F\: '{print $2}'`
echo "Minute is $min" >> $TEMPLOG
if ( $min == "00" ) then
  set HARPIMG_TICKET = `$WFCODE/maketicket.csh gate=hmi.harpImages_nrt wantlow=$WANTLOW wanthigh=$WANTLOW action=5`
endif


if ($retstatus == 0) then
  set nextlow = `$TIME_CONVERT s=$nextH_s zone=TAI`
  set nextTicket = `$WFCODE/maketicket.csh gate=repeat_harp_nrt wantlow=$nextlow wanthigh=$nextlow action=5`
endif

