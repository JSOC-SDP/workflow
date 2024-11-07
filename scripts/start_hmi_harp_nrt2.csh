#! /bin/csh -f

set echo

set noglob
setenv PGOPTIONS '--client-min-messages=warning'

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set HERE = $cwd
set TEMPLOG = $HERE/runlog
set CMD = $HERE/MHarp_nrt

touch $HERE/info

set QSUBFLAGS = "-v JSOC_r10"
set QUE = a.q
set QSUB = "/SGE2/bin/lx-amd64/qsub $QSUBFLAGS"
set tmpdir = "/tmp28/jsocprod"

set HARP_NRT_MOVIES = "${DRMS_SCRS_INSTALL_DIR}"/harp_nrt_movies.csh
set MAKE_TICKET = ${DRMS_SRC_INSTALL_DIR}/workflow//maketicket.csh
set SHOW_INFO = "${DRMS_BINS_INSTALL_DIR}"/show_info 
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set TRACK_AND_INGEST_MHARP = "${DRMS_SCRS_INSTALL_DIR}"/track_and_ingest_mharp.sh

# make sure a job isn't already running

while ( -e $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING )
  sleep 10
end

sleep 20

if ( `ls -1 $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/active | grep -v root | wc -l` > 1 ) then
  echo HOLD > $WORKFLOW_DATA/gates/repeat_harp_nrt/gatestatus
  set bad_ticket = `ls -1 $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/active | grep -v root | tail -1`
  echo "Removing last job ($bad_ticket).  Check to make sure the gate is still running." > /tmp/harps.mail
  ls -1 $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/active | grep -v root >> /tmp/harps.mail
  cat /tmp/harps.mail
  mv $bad_ticket WORKFLOW_DATA/tasks/update_hmi.harp_nrt/done
  sleep 90
  echo ACTIVE > $WORKFLOW_DATA/gates/repeat_harp_nrt/gatestatus
  /usr/bin/Mail -s "Multiple HARPS jobs running" jeneen@stanford.edu < /tmp/harps.email
endif

# if there's bad data, wait:

set T_lastGoodM = `$SHOW_INFO hmi.marmask_720s_nrt'[$][? quality >= 0 ?]' -q key=t_rec`

while ( `$SHOW_INFO hmi.marmask_720s_nrt'[$][? quality < 0 ?]' -qc` == 1 )
  echo -n "Bad mags:  " > $HERE/NO_GOOD_DATA
  $SHOW_INFO hmi.M_720s_nrt'['$T_lastGoodM'/10d]' -qi key=quality >> $HERE/NO_GOOD_DATA
  cat $HERE/NO_GOOD_DATA
  sleep 120
end

rm -f $HERE/NO_GOOD_DATA

# if there's no new data, wait:

set T_lastHarp = `$SHOW_INFO hmi.mharp_720s_nrt'[][$]' -q key=t_rec n=1`
@ T_lastHarp_s =  `$TIME_CONVERT time=$T_lastHarp zone=TAI`
set T_lastGoodM = `$SHOW_INFO hmi.marmask_720s_nrt'[$][? quality >= 0 ?]' -q key=t_rec`
@ T_lastGoodM_s = `$TIME_CONVERT time=$T_lastGoodM zone=TAI`

while ( $T_lastGoodM_s == $T_lastHarp_s )
  touch $HERE/WAITING_MAG_LAG
  sleep 60
  set T_lastHarp = `$SHOW_INFO hmi.mharp_720s_nrt'[][$]' -q key=t_rec n=1`
  @ T_lastHarp_s =  `$TIME_CONVERT time=$T_lastHarp zone=TAI`
  set T_lastGoodM = `$SHOW_INFO hmi.marmask_720s_nrt'[$][? quality >= 0 ?]' -q key=t_rec`
  @ T_lastGoodM_s = `$TIME_CONVERT time=$T_lastGoodM zone=TAI`
end

rm -f $HERE/WAITING_MAG_LAG

# if there's been down time process records for the last hour, else make the next record:

if ( $T_lastGoodM_s > $T_lastHarp_s ) then
  @ diff = $T_lastGoodM_s - $T_lastHarp_s
  if ( $diff == 720 ) then
    @ T_nextHarp_s = $T_lastGoodM_s
  else if ( $diff > 720 && $diff <= 3600 ) then
    @ T_nextHarp_s = $T_lastHarp_s + 720
  else if ( $diff > 3600 ) then
    @ T_nextHarp_s = $T_lastGoodM_s - 3600
  else
    echo "$T_lastGoodM_s - $T_lastHarp_s = $diff"
  endif

  set T_nextHarp = `$TIME_CONVERT s=$T_nextHarp_s zone=TAI`
  
  echo "last harp: $T_lastHarp  last good M: $T_lastGoodM   diff:  $diff" > $HERE/info

  # make command script
 
  echo "#! /bin/csh -f " >$CMD
  echo "cd $HERE" >>$CMD
  echo "touch $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING" >> $CMD
  echo "hostname >>&$TEMPLOG" >>$CMD
  echo "set echo" >>$CMD
  echo "setenv TMPDIR $tmpdir/HARPS/nrt/" >>$CMD
  echo "set MHarpstatus = 0" >>&$CMD

  foreach t_rec ( `$SHOW_INFO hmi.Marmask_720s_nrt'['$T_nextHarp'-'$T_lastGoodM'][? quality >= 0 ?]' -q key=T_REC` )
    echo "$TRACK_AND_INGEST_MHARP -n -m $tmpdir/HARPS/nrt hmi.Marmask_720s_nrt\[$t_rec] hmi.Mharp_720s_nrt hmi.Mharp_log_720s_nrt" >> $CMD
    set min = `echo $WANTLOW | awk -F\: '{print $2}'`
    if ( $min == "00" ) then
      set HARPIMG_TICKET = `$MAKE_TICKET gate=hmi.harpImages_nrt wantlow=$WANTLOW wanthigh=$WANTLOW action=5`
    endif
    set ME_TICKET = `$MAKE_TICKET gate=hmi.ME_720s_fd10_nrt wantlow=$t_rec wanthigh=$t_rec action=5`
  end
  echo 'set MHarpstatus = $?' >> $CMD
  echo 'if ($MHarpstatus) goto DONE' >>&$CMD
  echo $HARP_NRT_MOVIES >> $CMD
  echo 'DONE:' >>$CMD
  echo 'echo $MHarpstatus >retstatus' >> $CMD
  echo 'echo $MHarpstatus >retstatus' >>$CMD
  echo "rm $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/QSUB_RUNNING" >> $CMD

  # execute command and submit next ticket

  set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
  if ( `ls -1 $WORKFLOW_DATA/tasks/update_hmi.harp_nrt/active | grep -v root | wc -l` == 1 ) then
    $QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $CMD
    sleep 20
    set T_lastHarp = `$SHOW_INFO hmi.mharp_720s_nrt'[][$]' -q key=t_rec n=1`
    @ T_lastHarp_s =  `$TIME_CONVERT time=$T_lastHarp zone=TAI`
    @ newT_s = $T_lastHarp_s + 720
    set newT = `$TIME_CONVERT s=$newT_s zone=TAI`
    set nextTicket = `$MAKE_TICKET gate=repeat_harp_nrt wantlow=$newT wanthigh=$newT action=5`
  endif
endif 

