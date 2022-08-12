#! /bin/csh -f

#set echo
source /home/jsoc/.setJSOCenv
source /SGE2/default/common/settings.csh
set TARG = /web/jsoc/htdocs/data
set TMP = $TARG/.jsoc_proc_status.tmp

set noglob
unsetenv QUERY_STRING
umask 2

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set SHOW_SERIES = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_series
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set ARITH = /home/phil/bin/_linux4/arith
set SHOW_COVERAGE = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_coverage
set USERDB=hmidb
set USERDB2=hmidb2

@ fourdays = 4 * 1440
@ fivedays = 5 * 1440
@ sixdays = 6 * 1440
@ oneweek = 7 * 1440
@ eightdays = 8 * 1440
@ ninedays = 9 * 1440
@ tendays = 10 * 1440
@ twentydays = 20 * 1440 
# HMI products
set hproduct = ( hmi.lev0a hmi.lev1_nrt hmi.V_45s_nrt hmi.V_720s_nrt hmi_images hmi.MHarp_720s_nrt hmi.lev1 hmi.cosmic_rays hmi.V_45s hmi.V_720s hmi.B_720s)
set hgreen =  ( 2  7  30  73 51 90 $fivedays $fivedays $sixdays $sixdays $oneweek)
set hyellow = ( 4  10  60  85 60 120 $fivedays $fivedays $sixdays $sixdays $oneweek)
set hred =    ( 8  20 120 150 150 150 $sixdays  $sixdays  $oneweek $oneweek $eightdays)

# AIA products
set aproduct = ( aia.lev0 aia.lev1_nrt2 aia_test.lev1p5 aia.lev1 aia_synoptic_nrt_images aia_synoptic_images)
set agreen = ( 3 6 15 $fivedays 60 $eightdays)
#set ayellow = ( 4 10 20 $fivedays 90 $ninedays)
set ayellow = ( 4 10 20 $fivedays 90 $twentydays)
#set ared    = (8 20 40 $sixdays 120 $tendays)
set ared    = (8 20 40 $sixdays 120 $twentydays)


# IRIS products
set iproduct = ( iris.lev0 iris.lev1_nrt)
set igreen = ( 1920 7200 )
set iyellow = ( 2880 10800 )
set ired = ( 4320 14400)

set product = ( $hproduct $aproduct $iproduct )
set green = ($hgreen $agreen $igreen )
set yellow = ($hyellow $ayellow $iyellow )
set red = ($hred $ared $ired )

@ b = 0
@ o = 0
@ r = 0
@ y = 0
@ g = 0
@ g2 = 0

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set now_t = `$TIME_CONVERT time=$now`
set now_pacific = `date +%Y.%m.%d_%H:%M:%S`
set now_pacific_s = `$TIME_CONVERT time=$now_pacific`
set last_update = `ls -l --time-style="+%Y.%m.%d_%H:%M" /web/jsoc/htdocs/data/jsoc_proc_status.html | awk '{print $6}'`
@ last_update_s = `$TIME_CONVERT time=$last_update`
@ update_lag = $now_pacific_s - $last_update_s
if ( $update_lag > 600 ) then
  set mail_list = jeneen,phil,kehcheng,thailand
  echo "/web/jsoc/htdocs/data/jsoc_proc_status.html is $update_lag seconds old" > /tmp/update_lag
  echo "Run /home/jsoc/cvs/Development/JSOC/proj/workflow/scripts/show_jsoc_proc_status.csh to find error" >> /tmp/update_lag
  @ min = $update_lag / 60
  /usr/bin/Mail -s "Status Page Not Updated for $min minutes" $mail_list < /tmp/update_lag
endif
#echo "Content-type: text/html" >$TMP
echo '<\!doctype html public "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/loose.dtd">' >$TMP
echo '<html><head><title>JSOC Processing Status</title><meta http-equiv="refresh" content="60" url="http://jsoc.stanford.edu/data/jsoc_proc_status.html"></head><body link=black>' >>$TMP
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />' >> $TMP
echo -n "Last Update "$now"_UTC -- " >>$TMP
date >>$TMP
cat /web/jsoc/htdocs/ajax/URGENT_MOTD.html >>$TMP
echo '<p><table width=800>' >>$TMP
echo '<tr><td>Product</td><td>Lag</td><td>Note</td></tr>' >>$TMP

set lastAccess = `stat -c "%z" /home/jsoc/pipeline/tasks/update_hmi.harp_nrt/numHarps`
@ numHarps = `cat /home/jsoc/pipeline/tasks/update_hmi.harp_nrt/numHarps`
set Htime = $lastAccess[1]"_"$lastAccess[2]
@ Htime_s = `$TIME_CONVERT time=$Htime`
@ Htime_diff = $now_pacific_s - $Htime_s

set nprod = $#product
set iprod = 1
set project = hmi
while ($iprod <= $nprod)
  set prod = $product[$iprod]
  if ($prod == hmi.lev0a)  then
    set times = `$SHOW_INFO key=T_OBS -q hmi.lev0a'[? T_OBS > 0 ?]' n=-1`
  else if ($prod == aia.lev0)  then
    set times = `$SHOW_INFO key=T_OBS -q aia.lev0'[? T_OBS > 0 ?]' n=-1`
  else if ($prod == hmi_images) then
    set times = ` head -1 /web/jsoc/htdocs/data/hmi/images/image_times`
    if ( $#times != 2 ) then
      cp /web/jsoc/htdocs/data/hmi/images/image_times.BACKUP /web/jsoc/htdocs/data/hmi/images/image_times
      set times = ` head -1 /web/jsoc/htdocs/data/hmi/images/image_times`
    endif
    set times = `echo $times[2] | awk --  'BEGIN {FIELDWIDTHS = "4 2 2 1 2 2 2"} {printf("%s.%s.%s_%s:%s:%s_TAI",$1,$2,$3,$5,$6,$7)}'`
  else if ($prod == aia_synoptic_nrt_images) then
# #  set file = /web/jsoc/htdocs/data/aia/synoptic/mostrecent/AIAsynoptic0131.fits
# #  set times = `listhead $file | grep T_OBS | grep -v CRLT | awk '{print $3}' | sed s/\'//g`
# #  set times = `echo $times | awk -- 'BEGIN {FIELDWIDTHS = "4 1 2 1 2 1 2 1 2 1 2 1 2 "} {printf("%s.%s.%s_%s:%s:%s:%sZ",$1,$3,$5,$7,$9,$11,$13)}'`
  #  set times = `$SHOW_INFO lm_jps.synoptic3'[$][131]' -q key=t_obs | awk -- 'BEGIN {FIELDWIDTHS = "4 1 2 1 2 1 2 1 2 1 2 1 2 "} {printf("%s.%s.%s_%s:%s:%s:%sZ",$1,$3,$5,$7,$9,$11,$13)}'`
     set times = `head -1 /home/jsoc/aia/synoptic/mostrecent/image_times | awk '{print $2}' | awk -- 'BEGIN {FIELDWIDTHS = "4 2 2 1 2 2 2"} {printf("%s.%s.%s_%s:%s:%sZ",$1,$2,$3,$5,$6,$7)}'`
  else if ($prod == aia_synoptic_images) then
    set times = `grep synoptic /web/jsoc/htdocs/data/aia/synoptic/image_times | awk '{print $2}' | awk -F\/ '{print $11}'`
    set times = `echo $times | awk -- 'BEGIN {FIELDWIDTHS = "3 4 2 2 1 2 2 2"} {printf("%s.%s.%s_%s:%s:%sZ",$2,$3,$4,$6,$7,$8,$9)}'`
  else if ($prod == hmi.MHarp_720s_nrt ) then
    set Z = `$SHOW_INFO -q key=T_OBS $prod'[][$][? T_OBS > 0 ?]' -c`
    if ( $Z == 1 ) then
      set times = `$SHOW_INFO -q key=T_OBS $prod'[][$][? T_OBS > 0 ?]'`
    else
      set times = `$SHOW_INFO -q key=T_OBS $prod'[][$][? T_OBS > 0 ?]' n=-1`
    endif
    if ( $times[1] == '-4712.01.01_11:59:28_TAI' ) then        
      set times = `$SHOW_INFO -q key=T_REC $prod'[][$][? T_OBS > 0 ?]' n=-1`
    endif
 set echo
  else if ( $prod == iris.lev0 ) then
    set times = `$SHOW_INFO -q key=t_obs iris.lev0'[? FSN != 8421504 ?][? t_obs > 0 ?]' n=-1 | sed s/-/./g | sed s/T/_/ | cut -c1-19`
    set iris_proc_time = `$SHOW_INFO -q iris.lev0'[:#$]' key=date`
    set iris_proc_time_utc = `$TIME_CONVERT time=$iris_proc_time zone=UTC o=cal | awk -F\_ '{print $1"_"$2}'`_UTC
    @ iris_proc_time_s = `$TIME_CONVERT time=$iris_proc_time_utc`
    @ iris_diff = $now_t - $iris_proc_time_s 
    if ($iris_diff < 60) then
      set iris_lag = "$iris_diff seconds"
    else if ($iris_diff < 3600) then
      set iris_min = `$ARITH $iris_diff / 60 | awk -F\. '{print $1}'`
      set iris_lag = "$iris_min minutes"
    else if ( $iris_diff < 86400) then
      set iris_hr = `$ARITH $iris_diff / 3600`
      set iris_lag = "$iris_hr hours"
    else
      set iris_days = `$ARITH $iris_diff / 86400`
      set iris_lag = "$iris_days days"
    endif
    if ( $iris_diff <= 43200 ) then
      set iris_stat = GREEN
      @ g = 1
    else if ( $iris_diff <= 54000 ) then
      set iris_stat = YELLOW
      @ y = 1
    else
      set iris_stat = RED
      @ r = 1                 
      echo "$now IRIS lev0 is $iris_diff behind" >> /web/jsoc/htdocs/data/red.log
    endif
  else if ( $prod == iris.lev1_nrt ) then 
    set times = `$SHOW_INFO -q key=t_obs iris.lev1_nrt'[$]' | sed s/-/./g | sed s/T/_/ | cut -c1-19` 
    set iris1_proc_time = `$SHOW_INFO -q iris.lev1_nrt'[$]' key=date` 
    set iris1_proc_time_utc = `$TIME_CONVERT time=$iris1_proc_time zone=UTC o=cal | awk -F\_ '{print $1"_"$2}'`_UTC 
    @ iris1_proc_time_s = `$TIME_CONVERT time=$iris1_proc_time_utc` 
    @ iris1_diff = $now_t - $iris1_proc_time_s 
    if ($iris1_diff < 60) then 
      set iris1_lag = "$iris1_diff seconds" 
    else if ($iris1_diff < 3600) then 
      set iris1_min = `$ARITH $iris1_diff / 60 | awk -F\. '{print $1}'` 
      set iris1_lag = "$iris1_min minutes" 
    else if ( $iris1_diff < 86400) then 
      set iris1_hr = `$ARITH $iris1_diff / 3600` 
      set iris1_lag = "$iris1_hr hours" 
    else 
      set iris1_days = `$ARITH $iris1_diff / 86400` 
      set iris1_lag = "$iris1_days days" 
    endif 
    if ( $iris1_diff <= 43200 ) then 
      set iris1_stat = GREEN 
      @ g = 1 
    else if ( $iris1_diff <= 54000 ) then 
      set iris1_stat = YELLOW 
      @ y = 1 
    else 
      set iris1_stat = RED 
      @ r = 1                
      echo "$now IRIS lev1 is $iris1_diff behind" >> /web/jsoc/htdocs/data/red.log
    endif 
  unset echo
  else
    set times = `$SHOW_INFO -q key=T_OBS $prod'[$]'`
    if ( $times[1] == '-4712.01.01_11:59:28_TAI' ) then       
      set times = `$SHOW_INFO -q key=T_REC $prod'[$]'`  
    endif
    if ($prod == hmi.V_45s) then
      echo $times[1] > $TARG/hmi_45s_latest.txt
    else if ($prod == hmi.V_720s) then
      echo $times[1] > $TARG/hmi_720s_latest.txt
    endif
  endif
  set times_t = `$TIME_CONVERT time=$times[1]`
  @  lags = ( $now_t - $times_t ) / 60
  if ( $product[$iprod] == hmi.MHarp_720s_nrt ) then
    if ( ($numHarps == 0) && ($Htime_diff < 3600) ) then
      set stat = GREEN
      @ g = 1
    else if ( $lags <= $green[$iprod]) then
      set stat = GREEN
      @ g = 1
    else if ($lags <= $yellow[$iprod]) then
      set stat = YELLOW
      @ y = 1
    else
      set stat = RED
      @ r = 1
      echo "$now $prod is behind by $lags" >> /web/jsoc/htdocs/data/red.log
    endif
  else
    if ( $lags <= $green[$iprod]) then
      set stat = GREEN
      @ g = 1
    else if ($lags <= $yellow[$iprod]) then
      set stat = YELLOW
      @ y = 1
    else 
      set stat = RED
      @ r = 1
      echo "$now $prod is behind by $lags" >> /web/jsoc/htdocs/data/red.log
    endif
  endif
  if ( ($prod == "hmi.MHarp_720s_nrt") && ($numHarps == 0) && ($Htime_diff < 3600) ) then
    set lag = "0 HARPs"
  else if ($lags < 60) then
    set lag = "$lags minutes"
  else if ($lags < 1440) then
    set hours = `$ARITH $lags / 60`
    set lag = "$hours hours"
  else
    set days = `$ARITH $lags / 1440`
    set lag = "$days days"
  endif
  if ($prod == hmi_images) then
    set note = "HMI nrt web images"
  else if ($prod == hmi.B_720s) then
    set note = "Full-disk Milne-Eddington inversion"
  else if ($prod ==  aia_synoptic_nrt_images) then
    set note = "AIA nrt synoptic images"
  else if ($prod == aia_synoptic_images) then
    set note = "AIA synoptic images"
  else
    set note = `$SHOW_SERIES -p '^'$prod'$' | grep "Note:" | head -1 | sed -e 's/"/'"'/"`
    shift note
  endif
  if (!($prod =~ "$project"*)) then
    echo '<tr><td>&nbsp;<td><td>&nbsp;</td><td>&nbsp;</td></tr>' >>$TMP
    set project = $prod:r
  endif
  echo -n '<tr><td>'$prod'</td><td' >>$TMP
  if ($stat == GREEN) then
    echo -n ' bgcolor="#66FF66">' >>$TMP
  else if ($stat == YELLOW) then
    echo -n ' bgcolor="yellow">' >>$TMP
  else
    echo -n ' bgcolor="#FF6666">' >>$TMP
  endif
  echo "$lag"'</td><td>'"$note"'</td></tr>' >>$TMP
  if ( $prod == 'iris.lev0' ) then
    echo -n '<tr><td>iris processing time</td><td' >>$TMP
    if ($iris_stat == GREEN) then
      echo -n ' bgcolor="#66FF66">' >>$TMP
    else if ($iris_stat == YELLOW) then
      echo -n ' bgcolor="yellow">' >>$TMP
    else
      echo -n ' bgcolor="#FF6666">' >>$TMP
    endif
    echo "$iris_lag"'</td><td>'"$iris_proc_time_utc"'</td></tr>' >>$TMP
  endif

  if ( $prod == 'iris.lev1_nrt' ) then
    echo -n '<tr><td>iris lev1_nrt proc lag</td><td' >>$TMP
    if ($iris1_stat == GREEN) then
      echo -n ' bgcolor="#66FF66">' >>$TMP
    else if ($iris1_stat == YELLOW) then
      echo -n ' bgcolor="yellow">' >>$TMP
    else
      echo -n ' bgcolor="#FF6666">' >>$TMP
    endif
    echo "$iris1_lag"'</td><td>'"$iris1_proc_time_utc"'</td></tr>' >>$TMP
  endif

  @ iprod = $iprod + 1
end

# get lookdata and exportdata responsiveness
set webinfo = `tail -30 /home/jsoc/exports/logs/fetch_log | awk 'BEGIN { min=100000; max=0} {for (i=1; i<NF; i++) if ($i ~ /lag=.*/) {sub(/lag=/,"",$i); lag=$i}} {sum += lag; n++; } lag<min{min=lag} lag>max{max=lag} END { avg = sum/n; print  sprintf("%0.3f",avg) " min=" min " max=" max }'`
echo '<tr><td>&nbsp;<td><td>&nbsp;</td><td>&nbsp;</td></tr>' >>$TMP
echo -n '<tr><td>web response</td><td' >>$TMP
set lag=$webinfo[1]

set mslag = `echo $lag | sed -e "s/\.//" -e "s/^0*//"`
set lastReqId = `grep JSOC /home/jsoc/exports/RequestID`
echo $lastReqId
if ($mslag < 5000) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else if ($mslag < 20000) then
  echo -n ' bgcolor="yellow">' >>$TMP
else
  echo -n ' bgcolor="#FF6666">' >>$TMP
endif
#echo "$lag"'s</td><td>'$webinfo[2]'s, '$webinfo[3]'s, lookdata, exportdata response</td></tr>' >>$TMP
echo "$lag"'s</td><td>'$webinfo[2]'s, '$webinfo[3]'s, last ReqID: '$lastReqId' </td></tr>' >>$TMP

### Added 9/7/12 for monitoring lag between hmidb and hmidb2

set last_hmidb2 = `$SHOW_INFO aia.lev1'[$]' -q key=T_REC JSOC_DBHOST=hmidb2 JSOC_DBUSER=production`
set last_hmidb2_s = `$TIME_CONVERT time=$last_hmidb2`
set last_hmidb = `$SHOW_INFO aia.lev1'[$]' -q key=T_REC JSOC_DBHOST=hmidb JSOC_DBUSER=production`
set last_hmidb_s = `$TIME_CONVERT time=$last_hmidb`
@ db_diff = $last_hmidb_s - $last_hmidb2_s
echo -n '<tr><td>DB Lag </td><td ' >> $TMP
if ($db_diff < 300 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else if ( ($db_diff >= 300) && ($db_diff < 900) ) then
  echo -n ' bgcolor="yellow">'  >>$TMP
else
  echo -n ' bgcolor="#FF6666">' >>$TMP
  set stat = RED
endif
echo "$db_diff"'s </td><td>Lag between hmidb and hmidb2</td></tr>' >>$TMP

### Added 12/5/11 for monitoring exports ###

set count1 = `wget -O - -q 'http://jsoc2.stanford.edu/cgi-bin/ajax/show_info?c=1&q=1&ds=jsoc.export_new[?status=2?]'` 
#echo -n $count1
set count2 = `wget -O - -q 'http://jsoc.stanford.edu/cgi-bin/ajax/show_info?c=1&q=1&ds=jsoc.export_new[?status=2?]'` 
#set count3 = `/SGE/bin/lx24-amd64/qstat | grep JSOC_ | grep jsoc | grep -v qw | wc -l`
set count3 = `qstat | grep JSOC_ | grep jsoc | grep -v qw | wc -l`
 
echo -n '<tr><td>Exports Pending </td><td' >> $TMP

if ($count1 < 2) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else if ( ($count1 >= 2) && ($count1 < 6) ) then
  echo -n ' bgcolor="yellow">'  >>$TMP
else
  echo -n ' bgcolor="#FF6666">' >>$TMP
  set stat = RED
  @ r = 1
endif
echo "$count1"' </td><td>' $USERDB'</td></tr>' >>$TMP


echo -n '<tr><td>Exports Pending </td><td' >> $TMP

if ($count2 < 2) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else if ( ($count2 >= 2) && ($count2 < 6) ) then
  echo -n ' bgcolor="yellow">'  >>$TMP
else
  echo -n ' bgcolor="#FF6666">' >>$TMP
  set stat = RED
  @ r = 1
endif
echo "$count2"' </td><td>' $USERDB2'</td></tr>' >>$TMP

echo -n '<tr><td>Exports in Queue </td><td' >> $TMP

if ($count3 < 7) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
  echo "$count3"' </td><td>' $USERDB + $USERDB2'</td></tr>' >>$TMP
else if ( ($count3 >= 7) && ($count3 < 10) ) then
  echo -n ' bgcolor="yellow">'  >>$TMP
  echo "$count3"' </td><td>' $USERDB + $USERDB2'</td></tr>' >>$TMP
else
  echo -n ' bgcolor="#FF6666">' >>$TMP
  set stat = green2
  @ g2 = 1
  set ex1 = `qstat | grep JSOC | head -1`
  set ext1 = `echo $ex1[6] | awk -F\/ '{print $3"."$1"."$2"_"}'`$ex1[7]
  @ extLag1 = $now_t - `$TIME_CONVERT time=$ext1`
  if ( $extLag1 < 3600 ) then
    @ exp1Lag = $extLag1 / 60
    set exp1T = mins
  else if ( $extLag1 < 86400 ) then
    @ exp1Lag = $extLag1 / 3600
    set exp1T = hours
  else
    @ exp1Lag = $extLag1 / 86400
    set exp1T = days
  endif
  set ex2 = `qstat | grep JSOC | head -6 | tail -1`
  set ext2 = `echo $ex2[6] | awk -F\/ '{print $3"."$1"."$2"_"}'`$ex2[7]
  @ extLag2 = $now_t - `$TIME_CONVERT time=$ext2`
  if ( $extLag2 < 3600 ) then
    @ exp2Lag = $extLag2 / 60
    set exp2T = mins
  else if ( $extLag2 < 86400 ) then
    @ exp2Lag = $extLag2 / 3600
    set exp2T = hours
  else
    @ exp1Lag = $extLag1 / 86400
    set exp1T = days
  endif
  echo "$count3"' </td><td>' Tmax=$exp1Lag $exp1T, Tmin=$exp2Lag $exp2T'</td></tr>' >>$TMP
endif

### End of export monitoring ###


### Look for missing HMI observables ###

# these showCov files are generated every 30m by a cronjob
# on n04 as jeneen: /home/jsoc/cvs/Development/JSOC/proj/workflow/scripts/status_show_cov.csh

set showCov = "/web/jsoc/htdocs/data/.showCov"
set showCovNRT = "/web/jsoc/htdocs/data/.showCovNRT" 

if ( -z $showCov ) then
  @ n = 0
else
  @ n = `wc -l $showCov | awk '{print $1}'`
endif

@ missingDefinitive = 0

if ( $n > 1 ) then
  @ N = $n - 1
  foreach i ( `awk '{print $3}' $showCov | head -$N` )
    @ missingDefinitive = $missingDefinitive + $i
  end
endif

echo '<tr><td>&nbsp;<td><td>&nbsp;</td><td>&nbsp;</td></tr>' >>$TMP
echo -n '<tr><td>Missing HMI Obs </td><td' >> $TMP

if ($missingDefinitive == 0 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else
#  echo -n ' bgcolor="#FF6666">' >>$TMP
   echo -n ' bgcolor="yellow">' >>$TMP
endif
if ( $missingDefinitive == 0 ) then
  echo "$missingDefinitive"' </td><td> Missing HMI Observables Records (10 days)</td></tr>' >>$TMP
else
  echo "<a href=http://jsoc.stanford.edu/data/.showCov> $missingDefinitive </a>"' </td><td> Missing HMI Observables Records (10 days)</td></tr>' >>$TMP
endif


if ( -z $showCovNRT ) then
  @ n = 0
else
  @ n = `wc -l $showCovNRT | awk '{print $1}'`
endif

@ missingNRT = 0

if ( $n > 1 ) then
  @ N = $n - 1
  foreach i ( `awk '{print $3}' $showCovNRT | head -$N` )
    @ missingNRT = $missingNRT + $i
  end
endif

echo -n '<tr><td>Missing HMI NRT </td><td' >> $TMP

if ($missingNRT == 0 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else
#  echo -n ' bgcolor="#FF6666">' >>$TMP
   echo -n ' bgcolor="yellow">' >>$TMP
endif
if ( $missingNRT == 0 ) then
  echo "$missingNRT"' </td><td> Missing HMI NRT Records (3 days)</td></tr>' >>$TMP
else
  echo "<a href=http://jsoc.stanford.edu/data/.showCovNRT> $missingNRT </a>"' </td><td> Missing HMI NRT Records (3 days)</td></tr>' >>$TMP
endif


### Look for missing AIA lev1

set showCovAIA = "/web/jsoc/htdocs/data/.showCovAIA"
set showCovAIANRT = "/web/jsoc/htdocs/data/.showCovAIANRT"

if ( -z $showCovAIA ) then
#  @ n = 0
  @ missingDefAIA = 0
else
  #@ n = `wc -l $showCovAIA | awk '{print $1}'`
  @ missingDefAIA = `awk '{print $3}' $showCovAIA | head -1`
endif

#@ missingDefAIA = 0

#if ( $n > 0 ) then
#  @ N = $n - 1
#  foreach i ( `awk '{print $3}' $showCovAIA | head -$N` )
#    @ missingDefAIA = $missingDefAIA + $i
#  end
#endif


echo '<tr><td>&nbsp;<td><td>&nbsp;</td><td>&nbsp;</td></tr>' >>$TMP
echo -n '<tr><td>Missing AIA Lev1 </td><td' >> $TMP

if ($missingDefAIA <= 0 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else
#  echo -n ' bgcolor="#FF6666">' >>$TMP
  echo -n ' bgcolor="yellow">' >>$TMP
endif
if ( $missingDefAIA <= 0 ) then
  echo "0"' </td><td> Missing AIA Lev1 Records (10 days)</td></tr>' >>$TMP
else if ( $missingDefAIA > 0 ) then
  echo "<a href=http://jsoc.stanford.edu/data/.showCovAIA> $missingDefAIA </a>"' </td><td> Missing AIA Lev1 Records (10 days)</td></tr>' >>$TMP
endif

if ( -z $showCovAIANRT ) then
  @ n = 0
else
  @ n = `wc -l $showCovAIANRT | awk '{print $1}'`
endif

### Look for missing AIA NRT

@ missingAIANRT = 0

if ( $n > 0 ) then
  foreach i ( `grep UNK $showCovAIANRT | awk '{print $3}'` )
    @ missingAIANRT = $missingAIANRT + $i
  end
endif

echo -n '<tr><td>Missing AIA NRT </td><td' >> $TMP

if ( $missingAIANRT < 1200  ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
else
#  echo -n ' bgcolor="#FF6666">' >>$TMP
  echo -n ' bgcolor="yellow">' >>$TMP
endif
if ( $missingAIANRT == 0 ) then
  echo "$missingAIANRT"' </td><td> Missing AIA NRT Records (3 days)</td></tr>' >>$TMP
else
  echo "<a href=http://jsoc.stanford.edu/data/.showCovAIANRT> $missingAIANRT </a>"' </td><td> Missing AIA NRT Records (3 days)</td></tr>' >>$TMP
endif

echo '<tr><td>&nbsp;<td><td>&nbsp;</td><td>&nbsp;</td></tr>' >>$TMP

if ( -e /tmp/camera_anomaly ) then
  rm /tmp/camera_anomaly
endif

### Look for Bit Flip Anomaly in AIA

#@ fsn0 = `$SHOW_INFO -q key=fsn aia.lev0 n=-2 | head -1` - 3999
#@ BF1 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=1?]'` 
#@ BF2 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=2?]'`  
#@ BF3 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=3?]'`
#@ BF4 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=4?]'`

@ then_t = $now_t - 1200
@ BF1 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=1?]"`
@ BF2 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=2?]"`
@ BF3 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=3?]"`
@ BF4 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=4?]"`

@ totalBF = $BF1 + $BF2 + $BF3 + $BF4

echo -n '<tr><td>Datamin = 0</td><td' >> $TMP
if ( $totalBF < 100 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
  echo "$totalBF"' </td><td> ' >>$TMP 
  echo "No AIA Camera Anomalies (last 20m)"'</td></tr>' >> $TMP
else
  @ b = 1
  echo -n ' bgcolor="#FF6666">' >>$TMP
  echo "$totalBF"' </td><td> ' >>$TMP 
  if ( $BF1 > 0 ) then
    echo "AIA Camera 1: $BF1    ">>$TMP
    echo "Bit Flip Camera Anomaly for AIA Camera 1" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  if ( $BF2 > 0 ) then
    echo "AIA Camera 2: $BF2    " >>$TMP
    echo "Bit Flip Camera Anomaly for AIA Camera 2" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  if ( $BF3 > 0 ) then
    echo "AIA Camera 3: $BF3    " >>$TMP
    echo "Bit Flip Camera Anomaly for AIA Camera 3" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  if ( $BF4 > 0 ) then
    echo "AIA Camera 4: $BF4    " >>$TMP
    echo "Bit Flip Camera Anomaly for AIA Camera 4" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  echo "</td></tr>" >>$TMP
endif

### Look for Bit Flip Anomaly in HMI

#@ fsn0 = `$SHOW_INFO -q key=fsn hmi.lev0a n=-2 | head -1` - 3999
#@ BF1 = `$SHOW_INFO -cq 'hmi.lev0a['$fsn0'/4000][?datamin=0?][?camera=1?]'`
#@ BF2 = `$SHOW_INFO -cq 'hmi.lev0a['$fsn0'/4000][?datamin=0?][?camera=2?]'`
@ BF1 = `$SHOW_INFO -cq "hmi.lev0a[? t_obs > $then_t ?][?datamin=0?][?camera=1?]"`
@ BF2 = `$SHOW_INFO -cq "hmi.lev0a[? t_obs > $then_t ?][?datamin=0?][?camera=2?]"`
@ bad_t = $now_t - 300
@ BAD1 = `$SHOW_INFO -cq "hmi.lev0a[? t_obs > $bad_t ?][?datamin<0?][?camera=1?]"`
@ BAD2 = `$SHOW_INFO -cq "hmi.lev0a[? t_obs > $bad_t ?][?datamin<0?][?camera=2?]"`

@ totalBF = $BF1 + $BF2 
@ totalBAD = $BAD1 + $BAD2

echo -n '<tr><td>Datamin = 0</td><td' >> $TMP
if ( $totalBF < 100 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
  echo "$totalBF"' </td><td> ' >>$TMP
  echo "No HMI Camera Anomalies (last 20m)"'</td></tr>' >> $TMP
else
  @ b = 1
  echo -n ' bgcolor="blue">' >>$TMP
  echo "$totalBF"' </td><td> ' >>$TMP
  if ( $BF1 > 0 ) then
    echo "HMI Camera 1: $BF1    ">>$TMP
    echo "Bit Flip Camera Anomaly for HMI Camera 1" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  if ( $BF2 > 0 ) then
    echo "HMI Camera 2: $BF2    " >>$TMP
    echo "Bit Flip Camera Anomaly for HMI Camera 2" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  echo "</td></tr>" >>$TMP
endif

if ( $totalBAD > 0 ) then
  rm /tmp/camera_bad
  @ o = 1
  echo -n ' bgcolor="#FF6600">' >>$TMP
  echo "$totalBAD"' </td><td> ' >>$TMP
  if ( $BAD1 > 0 || $BAD2 > 0 ) then
    $SHOW_INFO -i "hmi.lev0a[? t_obs > $then_t ?][?datamin<0?]" key=datamin  > /tmp/camera_bad
  endif
  echo "</td></tr>" >>$TMP
endif


### Look for Bit Flip Anomaly in IRIS

set t2 = `$SHOW_INFO -q iris.lev0'[$]' key=fsn`
@ t1 = $t2 - 600
#@ s_last = `$TIME_CONVERT time=$t_last`
#@ s_first = $s_last - 600
#set t1 = `$TIME_CONVERT s=$s_first | awk -F\_ '{print $1"_"$2}'`
#set t2 = `$TIME_CONVERT s=$s_last | awk -F\_ '{print $1"_"$2}'`

@ BF1 = `$SHOW_INFO -cq iris.lev0'['$t1'-'$t2'][?datamin=0?][?camera=1?]'`
@ BF2 = `$SHOW_INFO -cq iris.lev0'['$t1'-'$t2'][?datamin=0?][?camera=2?]'`

@ totalBF = $BF1 + $BF2

echo -n '<tr><td>Datamin = 0</td><td' >> $TMP
if ( $totalBF < 100 ) then
  echo -n ' bgcolor="#66FF66">' >>$TMP
  echo "$totalBF"' </td><td> ' >>$TMP
  echo "No IRIS Camera Anomalies (last 600 FSNs)"'</td></tr>' >> $TMP
else
  @ b = 1
  echo -n ' bgcolor="blue">' >>$TMP
  echo "$totalBF"' </td><td> ' >>$TMP
  if ( $BF1 > 0 ) then
    echo "IRIS Camera 1: $BF1    ">>$TMP
    echo "Bit Flip Camera Anomaly for IRIS Camera 1" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder
  endif
  if ( $BF2 > 0 ) then
    echo "IRIS Camera 2: $BF2    " >>$TMP
    echo "Bit Flip Camera Anomaly for IRIS Camera 2" >> /tmp/camera_anomaly
    echo "Be sure to remove tmp files in ~jeneen when problem is fixed." > /tmp/camera_anomaly_reminder`
  endif
  echo "</td></tr>" >>$TMP
endif


echo '</table>' >>$TMP
echo '<p>' >>$TMP


echo 'Data times given are lag between observation time and the current time.<br>' >>$TMP
echo 'Web times given are sample of most recent 30 requests, avg, min, max.<br>' >>$TMP
echo 'Colors indicate: green -> as expected; yellow -> late; red -> very late; blue -> camera anomaly' >>$TMP
echo 'orange -> datamin < 0 (Ground station issues, likely)' >>$TMP
echo '<p>' >>$TMP

set echo
if ($b == 1) then
  set favicon = blue_sq.gif 
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh blue
  if ( ! -e /home/jeneen/CAMERA_ANOMALY.lock ) then
    /usr/bin/Mail -s 'Important:  Camera Anomaly' jsoc_ops@lmsal.com < /tmp/camera_anomaly
    /usr/bin/Mail -s 'Remove cameral anomaly temp files' jsoc_ops@lmsal.com < /tmp/camera_anomaly_reminder
    touch /home/jeneen/CAMERA_ANOMALY.lock
  endif
else if ($o == 1 ) then
  set favicon = orange_sq.gif
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh orange
  /usr/bin/Mail -s 'HMI images with datamin < 0 found' jeneen,baldner,thomas.j.cruz@lmco.com < /tmp/camera_bad
else if ($r == 1) then
  set favicon = red_sq.gif
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh red
else if ( $g2 == 1 ) then
  set favicon = green2_sq.gif
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh green2
else if ($y == 1) then
  set favicon = yellow_sq.gif
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh yellow
else
  set favicon = green_sq.gif 
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh green
endif
echo '</body>' >>$TMP
echo '<head><link rel="stat icon" href="http://jsoc.stanford.edu/data/tmp/'$favicon'"></head>' >>$TMP
echo '</html>' >>$TMP

mv $TMP $TARG/jsoc_proc_status.html
