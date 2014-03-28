#! /bin/csh -f

 set echo

set TARG = /web/jsoc/htdocs/data
set TMP = $TARG/.jsoc_proc_status.tmp

set noglob
unsetenv QUERY_STRING

set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/show_info
set SHOW_SERIES = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/show_series
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert
set ARITH = /home/phil/bin/_linux4/arith
set SHOW_COVERAGE = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/show_coverage
set USERDB=hmidb
set USERDB2=hmidb2

@ fourdays = 4 * 1440
@ fivedays = 5 * 1440
@ sixdays = 6 * 1440
@ oneweek = 7 * 1440

# HMI products
set hproduct = ( hmi.lev0a hmi.lev1_nrt hmi.V_45s_nrt hmi.V_720s_nrt hmi_images hmi.MHarp_720s_nrt hmi.lev1 hmi.cosmic_rays hmi.V_45s hmi.V_720s)
set hgreen =  ( 2  7  30  73 51 90 $fivedays $fivedays $sixdays $sixdays)
set hyellow = ( 4  10  60  85 60 120 $fivedays $fivedays $sixdays $sixdays)
set hred =    ( 8  20 120 150 150 150 $sixdays  $sixdays  $oneweek $oneweek) 

# AIA products
set aproduct = ( aia.lev0 aia.lev1_nrt2 aia_test.lev1p5 aia.lev1 )
set agreen = ( 3  6 15 $fivedays )
set ayellow = ( 4  10 20 $fivedays )
set ared    = (8  20 40 $sixdays )

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
@ r = 0
@ y = 0
@ g = 0

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set now_t = `$TIME_CONVERT time=$now`

#echo "Content-type: text/html" >$TMP
echo '<\!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/loose.dtd">' >$TMP
echo '<HTML><HEAD><TITLE>JSOC Processing Status</TITLE><META HTTP-EQUIV="Refresh" CONTENT="60"></HEAD><BODY LINK=black>' >>$TMP
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />' >> $TMP
echo -n "Last Update "$now"_UTC -- " >>$TMP
date >>$TMP

echo '<P><TABLE WIDTH=750>' >>$TMP
echo '<TR><TD>Product</TD><TD>Lag</TD><TD>Note</TD></TR>' >>$TMP

set nprod = $#product
set iprod = 1
set project = hmi
while ($iprod <= $nprod)
  set prod = $product[$iprod]
  if ($prod == hmi.lev0a)  then
    set times = `$SHOW_INFO key=T_OBS -q hmi.lev0a'[? FSN < 200000000 ?]' n=-1`
  else if ($prod == aia.lev0)  then
    set times = `$SHOW_INFO key=T_OBS -q aia.lev0'[? FSN < 200000000 ?]' n=-1`
  else if ($prod == hmi_images) then
    set times = ` head -1 /web/jsoc/htdocs/data/hmi/images/image_times`
    set times = `echo $times[2] | awk --  'BEGIN {FIELDWIDTHS = "4 2 2 1 2 2 2"} {printf("%s.%s.%s_%s:%s:%s_TAI",$1,$2,$3,$5,$6,$7)}'`
  else if ($prod == hmi.MHarp_720s_nrt ) then
    set times = `$SHOW_INFO -q key=T_OBS $prod'[][$]' n=-1`
    if ( $times[1] == '-4712.01.01_11:59:28_TAI' ) then        
      set times = `$SHOW_INFO -q key=T_REC $prod'[][$]' n=-1`
    endif
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
    endif
  else if ( $prod == iris.lev1_nrt ) then 
    set times = `$SHOW_INFO -q key=t_obs iris.lev1_nrt'[$]' | sed s/-/./g | sed s/T/_/ | cut -c1-19` 
    set iris1_proc_time = `$SHOW_INFO -q iris.lev1_nrt'[$]' key=date` 
    set iris1_proc_time_utc = `$TIME_CONVERT time=$iris1_proc_time zone=UTC o=cal | awk -F\_ '{print $1"_"$2}'`_UTC 
    @ iris1_proc_time_s = `$TIME_CONVERT time=$iris1_proc_time_utc` 
    @ iris1_diff = $now_t - $iris1_proc_time_s 
    if ($iris1_diff < 660) then 
      set iris1_lag = "$iris1_diff seconds" 
    else if ($iris1_diff < 4200) then 
      set iris1_min = `$ARITH $iris1_diff / 60 | awk -F\. '{print $1}'` 
      set iris1_lag = "$iris1_min minutes" 
    else if ( $iris1_diff < 87000) then 
      set iris1_hr = `$ARITH $iris1_diff / 3600` 
      set iris1_lag = "$iris1_hr hours" 
    else 
      set iris1_days = `$ARITH $iris1_diff / 86400` 
      set iris1_lag = "$iris1_days days" 
    endif 
    if ( $iris1_diff <= 900 ) then 
      set iris1_stat = GREEN 
      @ g = 1 
    else if ( $iris1_diff <= 1800 ) then 
      set iris1_stat = YELLOW 
      @ y = 1 
    else 
      set iris1_stat = RED 
      @ r = 1 
    endif 
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
  if ( $lags <= $green[$iprod]) then
    set stat = GREEN
    @ g = 1
  else if ($lags <= $yellow[$iprod]) then
    set stat = YELLOW
    @ y = 1
  else 
    set stat = RED
    @ r = 1
  endif
  if ($lags < 60) then
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
  else
    set note = `$SHOW_SERIES -p '^'$prod'$' | grep "Note:" | sed -e 's/"/'"'/"`
    shift note
  endif
  if (!($prod =~ "$project"*)) then
    echo '<TR><TD>&nbsp;<TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>' >>$TMP
    set project = $prod:r
  endif
  echo -n '<TR><TD>'$prod'</TD><TD' >>$TMP
  if ($stat == GREEN) then
    echo -n ' BGCOLOR="#66FF66">' >>$TMP
  else if ($stat == YELLOW) then
    echo -n ' BGCOLOR="yellow">' >>$TMP
  else
    echo -n ' BGCOLOR="#FF6666">' >>$TMP
  endif
  echo "$lag"'</TD><TD>'"$note"'</TD></TR>' >>$TMP
  if ( $prod == 'iris.lev0' ) then
    echo -n '<TR><TD>iris processing time</TD><TD' >>$TMP
    if ($iris_stat == GREEN) then
      echo -n ' BGCOLOR="#66FF66">' >>$TMP
    else if ($iris_stat == YELLOW) then
      echo -n ' BGCOLOR="yellow">' >>$TMP
    else
      echo -n ' BGCOLOR="#FF6666">' >>$TMP
    endif
    echo "$iris_lag"'</TD><TD>'"$iris_proc_time_utc"'</TD></TR>' >>$TMP
  endif

  if ( $prod == 'iris.lev1_nrt' ) then
    echo -n '<TR><TD>iris lev1_nrt proc lag</TD><TD' >>$TMP
    if ($iris1_stat == GREEN) then
      echo -n ' BGCOLOR="#66FF66">' >>$TMP
    else if ($iris1_stat == YELLOW) then
      echo -n ' BGCOLOR="yellow">' >>$TMP
    else
      echo -n ' BGCOLOR="#FF6666">' >>$TMP
    endif
    echo "$iris1_lag"'</TD><TD>'"$iris1_proc_time_utc"'</TD></TR>' >>$TMP
  endif

  @ iprod = $iprod + 1
end

# get lookdata and exportdata responsiveness
set webinfo = `tail -30 /home/jsoc/exports/logs/fetch_log | awk 'BEGIN { min=100000; max=0} {for (i=1; i<NF; i++) if ($i ~ /lag=.*/) {sub(/lag=/,"",$i); lag=$i}} {sum += lag; n++; } lag<min{min=lag} lag>max{max=lag} END { avg = sum/n; print  sprintf("%0.3f",avg) " min=" min " max=" max }'`
echo '<TR><TD>&nbsp;<TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>' >>$TMP
echo -n '<TR><TD>web response</TD><TD' >>$TMP
set lag=$webinfo[1]

set mslag = `echo $lag | sed -e "s/\.//" -e "s/^0*//"`
if ($mslag < 5000) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else if ($mslag < 20000) then
  echo -n ' BGCOLOR="yellow">' >>$TMP
else
  echo -n ' BGCOLOR="#FF6666">' >>$TMP
endif
echo "$lag"'s</TD><TD>'$webinfo[2]'s, '$webinfo[3]'s, lookdata, exportdata response</TD></TR>' >>$TMP

### Added 9/7/12 for monitoring lag between hmidb and hmidb2

set last_hmidb2 = `$SHOW_INFO aia.lev1'[$]' -q key=T_REC JSOC_DBHOST=hmidb2 JSOC_DBUSER=production`
set last_hmidb2_s = `$TIME_CONVERT time=$last_hmidb2`
set last_hmidb = `$SHOW_INFO aia.lev1'[$]' -q key=T_REC JSOC_DBHOST=hmidb JSOC_DBUSER=production`
set last_hmidb_s = `$TIME_CONVERT time=$last_hmidb`
@ db_diff = $last_hmidb_s - $last_hmidb2_s
echo -n '<TR><TD>DB Lag </TD><TD ' >> $TMP
if ($db_diff < 300 ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else if ( ($db_diff >= 300) && ($db_diff < 900) ) then
  echo -n ' BGCOLOR="yellow">'  >>$TMP
else
  echo -n ' BGCOLOR="#FF6666">' >>$TMP
  set stat = RED
endif
echo "$db_diff"'s </TD><TD>Lag between hmidb and hmidb2</TD></TR>' >>$TMP

### Added 12/5/11 for monitoring exports ###

set count1 = `wget -O - -q 'http://jsoc2.stanford.edu/cgi-bin/ajax/show_info?c=1&q=1&ds=jsoc.export_new[?status=2?]'` 
#echo -n $count1
set count2 = `wget -O - -q 'http://jsoc.stanford.edu/cgi-bin/ajax/show_info?c=1&q=1&ds=jsoc.export_new[?status=2?]'` 

echo -n '<TR><TD>Exports Pending </TD><TD' >> $TMP

  if ($count1 < 2) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else if ( ($count1 >= 2) && ($count1 < 6) ) then
  echo -n ' BGCOLOR="yellow">'  >>$TMP
else
  echo -n ' BGCOLOR="#FF6666">' >>$TMP
endif
echo "$count1"' </TD><TD>' $USERDB'</TD></TR>' >>$TMP


echo -n '<TR><TD>Exports Pending </TD><TD' >> $TMP

if ($count2 < 2) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else if ( ($count2 >= 2) && ($count2 < 6) ) then
  echo -n ' BGCOLOR="yellow">'  >>$TMP
else
  echo -n ' BGCOLOR="#FF6666">' >>$TMP
endif
echo "$count2"' </TD><TD>' $USERDB2'</TD></TR>' >>$TMP

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

echo '<TR><TD>&nbsp;<TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>' >>$TMP
echo -n '<TR><TD>Missing HMI Obs </TD><TD' >> $TMP

if ($missingDefinitive == 0 ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else
#  echo -n ' BGCOLOR="#FF6666">' >>$TMP
   echo -n ' BGCOLOR="yellow">' >>$TMP
endif
if ( $missingDefinitive == 0 ) then
  echo "$missingDefinitive"' </TD><TD> Missing HMI Observables Records (10 days)</TD></TR>' >>$TMP
else
  echo "<A HREF=http://jsoc.stanford.edu/data/.showCov> $missingDefinitive </A>"' </TD><TD> Missing HMI Observables Records (10 days)</TD></TR>' >>$TMP
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

echo -n '<TR><TD>Missing HMI NRT </TD><TD' >> $TMP

if ($missingNRT == 0 ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else
#  echo -n ' BGCOLOR="#FF6666">' >>$TMP
   echo -n ' BGCOLOR="yellow">' >>$TMP
endif
if ( $missingNRT == 0 ) then
  echo "$missingNRT"' </TD><TD> Missing HMI NRT Records (3 days)</TD></TR>' >>$TMP
else
  echo "<A HREF=http://jsoc.stanford.edu/data/.showCovNRT> $missingNRT </A>"' </TD><TD> Missing HMI NRT Records (3 days)</TD></TR>' >>$TMP
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


echo '<TR><TD>&nbsp;<TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>' >>$TMP
echo -n '<TR><TD>Missing AIA Lev1 </TD><TD' >> $TMP

if ($missingDefAIA <= 0 ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else
#  echo -n ' BGCOLOR="#FF6666">' >>$TMP
  echo -n ' BGCOLOR="yellow">' >>$TMP
endif
if ( $missingDefAIA <= 0 ) then
  echo "0"' </TD><TD> Missing AIA Lev1 Records (10 days)</TD></TR>' >>$TMP
else if ( $missingDefAIA > 0 ) then
  echo "<A HREF=http://jsoc.stanford.edu/data/.showCovAIA> $missingDefAIA </A>"' </TD><TD> Missing AIA Lev1 Records (10 days)</TD></TR>' >>$TMP
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

echo -n '<TR><TD>Missing AIA NRT </TD><TD' >> $TMP

if ( $missingAIANRT < 1200  ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
else
#  echo -n ' BGCOLOR="#FF6666">' >>$TMP
  echo -n ' BGCOLOR="yellow">' >>$TMP
endif
if ( $missingAIANRT == 0 ) then
  echo "$missingAIANRT"' </TD><TD> Missing AIA NRT Records (3 days)</TD></TR>' >>$TMP
else
  echo "<A HREF=http://jsoc.stanford.edu/data/.showCovAIANRT> $missingAIANRT </A>"' </TD><TD> Missing AIA NRT Records (3 days)</TD></TR>' >>$TMP
endif

echo '<TR><TD>&nbsp;<TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>' >>$TMP

if ( -e /tmp/camera_anomaly ) then
  rm /tmp/camera_anomaly
endif

### Look for Bit Flip Anomaly in AIA

#@ fsn0 = `$SHOW_INFO -q key=fsn aia.lev0 n=-2 | head -1` - 3999
#@ BF1 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=1?]'` 
#@ BF2 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=2?]'`  
#@ BF3 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=3?]'`
#@ BF4 = `$SHOW_INFO -cq 'aia.lev0['$fsn0'/4000][?datamin=0?][?camera=4?]'`

@ then_t = $now_t - 600
@ BF1 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=1?]"`
@ BF2 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=2?]"`
@ BF3 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=3?]"`
@ BF4 = `$SHOW_INFO -cq "aia.lev0[? t_obs > $then_t ?][?datamin=0?][?camera=4?]"`

@ totalBF = $BF1 + $BF2 + $BF3 + $BF4

echo -n '<TR><TD>Datamin = 0</TD><TD' >> $TMP
if ( $totalBF < 100 ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
  echo "$totalBF"' </TD><TD> ' >>$TMP 
  echo "No AIA Camera Anomalies (last 600s)"'</TD></TR>' >> $TMP
else
  @ b = 1
  echo -n ' BGCOLOR="#FF6666">' >>$TMP
  echo "$totalBF"' </TD><TD> ' >>$TMP 
  if ( $BF1 > 0 ) then
    echo "AIA Camera 1: $BF1    ">>$TMP
    echo "Camera Anomaly for AIA Camera 1" >> /tmp/camera_anomaly
  endif
  if ( $BF2 > 0 ) then
    echo "AIA Camera 2: $BF2    " >>$TMP
    echo "Camera Anomaly for AIA Camera 2" >> /tmp/camera_anomaly
  endif
  if ( $BF3 > 0 ) then
    echo "AIA Camera 3: $BF3    " >>$TMP
    echo "Camera Anomaly for AIA Camera 3" >> /tmp/camera_anomaly
  endif
  if ( $BF4 > 0 ) then
    echo "AIA Camera 4: $BF4    " >>$TMP
    echo "Camera Anomaly for AIA Camera 4" >> /tmp/camera_anomaly
  endif
  echo "</TD></TR>" >>$TMP
endif

### Look for Bit Flip Anomaly in HMI

#@ fsn0 = `$SHOW_INFO -q key=fsn hmi.lev0a n=-2 | head -1` - 3999
#@ BF1 = `$SHOW_INFO -cq 'hmi.lev0a['$fsn0'/4000][?datamin=0?][?camera=1?]'`
#@ BF2 = `$SHOW_INFO -cq 'hmi.lev0a['$fsn0'/4000][?datamin=0?][?camera=2?]'`
@ BF1 = `$SHOW_INFO -cq "hmi.lev0a[? t_obs > $then_t ?][?datamin=0?][?camera=1?]"`
@ BF2 = `$SHOW_INFO -cq "hmi.lev0a[? t_obs > $then_t ?][?datamin=0?][?camera=2?]"`

@ totalBF = $BF1 + $BF2 

echo -n '<TR><TD>Datamin = 0</TD><TD' >> $TMP
if ( $totalBF < 100 ) then
  echo -n ' BGCOLOR="#66FF66">' >>$TMP
  echo "$totalBF"' </TD><TD> ' >>$TMP
  echo "No HMI Camera Anomalies (last 600s)"'</TD></TR>' >> $TMP
else
  @ b = 1
  echo -n ' BGCOLOR="blue">' >>$TMP
  echo "$totalBF"' </TD><TD> ' >>$TMP
  if ( $BF1 > 0 ) then
    echo "HMI Camera 1: $BF1    ">>$TMP
    echo "Camera Anomaly for HMI Camera 1" >> /tmp/camera_anomaly
  endif
  if ( $BF2 > 0 ) then
    echo "HMI Camera 2: $BF2    " >>$TMP
    echo "Camera Anomaly for HMI Camera 2" >> /tmp/camera_anomaly
  endif
  echo "</TD></TR>" >>$TMP
endif


echo '</TABLE>' >>$TMP
echo '<P>' >>$TMP


echo 'Data times given are lag between observation time and the current time.<BR>' >>$TMP
echo 'Web times given are sample of most recent 30 requests, avg, min, max.<BR>' >>$TMP
echo 'Colors indicate: green -> as expected; yellow -> late; red -> very late; blue -> camera anomaly' >>$TMP
echo '<P>' >>$TMP

if ($b == 1) then
  set favicon = blue_sq.gif 
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh blue
  if ( ! -e /home/jeneen/CAMERA_ANOMALY.lock ) then
    /usr/bin/Mail -s 'Important:  Camera Anomaly' jsoc_ops < /tmp/camera_anomaly
    touch /home/jeneen/CAMERA_ANOMALY.lock
  endif
else if ($r == 1) then
  set favicon = red_sq.gif
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh red
else if ($y == 1) then
  set favicon = yellow_sq.gif
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh yellow
else
  set favicon = green_sq.gif 
  /home/jeneen/campaigns/scripts/hmi/update_proc_status.csh green
endif
echo '</BODY>' >>$TMP
echo '<HEAD><link rel="stat icon" href="http://jsoc.stanford.edu/data/tmp/'$favicon'"></HEAD>' >>$TMP
echo '</HTML>' >>$TMP

mv $TMP $TARG/jsoc_proc_status.html
