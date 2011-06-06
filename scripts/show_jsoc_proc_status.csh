#! /bin/csh -f

# set echo

set TARG = /web/jsoc/htdocs/data
set TMP = $TARG/.jsoc_proc_status.tmp

set noglob
unsetenv QUERY_STRING

set SHOW_INFO = /home/phil/jsoc/bin/linux_x86_64/show_info
set SHOW_SERIES = /home/phil/jsoc/bin/linux_x86_64/show_series
set TIME_CONVERT = /home/phil/jsoc/bin/linux_x86_64/time_convert
set ARITH = /home/phil/bin/_linux4/arith
set USERDB=hmidb

@ fourdays = 4 * 1440
@ fivedays = 5 * 1440
@ sixdays = 6 * 1440
@ oneweek = 7 * 1440

# HMI products
set hproduct = ( hmi.lev0a hmi.lev1_nrt hmi.V_45s_nrt hmi.V_720s_nrt hmi_images hmi.lev1 hmi.cosmic_rays hmi.V_45s hmi.V_720s)
set hgreen =  ( 2  5  30  60 40 $fivedays $fivedays $sixdays $sixdays)
set hyellow = ( 4  10  60  80 60 $fivedays $fivedays $sixdays $sixdays)
set hred =    ( 8  20 120 150 150 $sixdays  $sixdays  $oneweek $oneweek) 

# AIA products
set aproduct = ( aia.lev0 aia.lev1_nrt2 aia_test.lev1p5 aia.lev1 )
set agreen = ( 2  5 15 $fivedays )
set ayellow = ( 4  10 20 $fivedays )
set ared    = (8  20 40 $sixdays )

set product = ( $hproduct $aproduct )
set green = ($hgreen $agreen)
set yellow = ($hyellow $ayellow)
set red = ($hred $ared)

@ r = 0
@ y = 0
@ g = 0

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set now_t = `$TIME_CONVERT time=$now`

#echo "Content-type: text/html" >$TMP
#echo "" >>$TMP
#echo '<HTML><HEAD><TITLE>JSOC Processing Status</TITLE><META HTTP-EQUIV="Refresh" CONTENT="60"></HEAD><BODY>' >>$TMP
echo '<HTML><HEAD><TITLE>JSOC Processing Status</TITLE><META HTTP-EQUIV="Refresh" CONTENT="60"></HEAD><BODY>' >$TMP
echo -n "Last Update "$now"_UTC -- " >>$TMP
date >>$TMP

echo '<P><TABLE>' >>$TMP
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
  else
    set times = `$SHOW_INFO -q key=T_OBS $prod'[$]'`
    if ( $times[1] == '-4712.01.01_11:59:28_TAI' ) then        # added by Jeneen 3/23/11 
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
  if ($lags <= $green[$iprod]) then
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
  @ iprod = $iprod + 1
end

echo '</TABLE>' >>$TMP
echo '<P>' >>$TMP
echo 'Times given are lag between observation time and the current time' >>$TMP
echo '<BR>' >>$TMP
echo 'Colors indicate: green -> as expected; yellow -> late; red -> very late' >>$TMP
echo '<P>' >>$TMP

if ($r == 1) then
  set favicon = red_sq.gif
else if ($y == 1) then
  set favicon = yellow_sq.gif
else
  set favicon = green_sq.gif 
endif
echo '</BODY>' >>$TMP
#echo '<HEAD><link rel="stat icon" href="http://jsoc.stanford.edu/data/tmp/favicon.ico"></HEAD>' >>$TMP
echo '<HEAD><link rel="stat icon" href="http://jsoc.stanford.edu/data/tmp/'$favicon'"></HEAD>' >>$TMP
echo '</HTML>' >>$TMP

mv $TMP $TARG/jsoc_proc_status.html
