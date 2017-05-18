#! /bin/csh -f
# create limb darkening removed Ic record and create image set for Ic_noLD and M for range of time
# specified by first two arguments.

# set echo
# modified to only make new movie if NRT data.

set wantlow = $1
set wanthigh = $2

echo Make images for $wantlow to $wanthigh

# from here make script that can make _nrt images in standard place

set CADENCE = 3

set WF = /home/jsoc/cvs/Development/JSOC/proj/workflow
setenv RGBDEF $WF/scripts/rgb.txt
set RENDER_IMAGE = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/render_image
set HMI_LIMBDARK = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/hmi_limbdark
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info

set obslist = (Ic) 
#set minlist = (20000)
#set maxlist = (75000)
set minlist = (10000)
set maxlist = (62000)
set scalinglist = (minmaxgiven)
#set colorlist = (/home/phil/apps/heat.sao)
set colorlist = ($WF/apps/heat.sao)
set namelist = (Continuum)
set flaglist = ("")

set finalimagetime = NONE

set isNRT = 1

set end_movie_t = 0

set wantlow_t = `$TIME_CONVERT time=$wantlow`
set wanthigh_t = `$TIME_CONVERT time=$wanthigh`

@ daylow = $wantlow_t / 86400
@ dayhigh = $wanthigh_t / 86400

set day = $daylow
while ($day <= $dayhigh)
  @ day_t = 86400 * $day
  @ nextday_t = $day_t + 86400
  @ last_t = $nextday_t - 45
  if ($last_t > $wanthigh_t) set last_t = $wanthigh_t
  set first_t = $day_t
  if ($first_t < $wantlow_t) set first_t = $wantlow_t
  @ cadence = $CADENCE * 60
  @ first_mod_t = $first_t - 45
  @ imglow_t = $first_mod_t / $cadence
  @ imglow_t = $imglow_t + 1
  @ first_t = $imglow_t * $cadence
  set first = `$TIME_CONVERT s=$first_t zone=TAI`
  @ last_mod_t = $last_t + $cadence
  @ imghigh_t = $last_mod_t / $cadence
  @ n_images = $imghigh_t - $imglow_t
  if ($n_images < 0) set n_images = 0
  if ($n_images == 0) then
    @ day = $day + 1
    continue
  endif
  set end_movie_t = $last_t
  @ n_minutes = $n_images * $CADENCE
  set QRY = '['$first'/'$n_minutes'm@'$CADENCE'm]'
  set yyyymmdd = `echo $first | sed -e 's/_.*//' -e 's/\./Q/' -e 's/\./X/'`
  set YEAR = `echo $yyyymmdd | sed -e 's/Q.*//'`
  set MON = `echo $yyyymmdd | sed -e 's/^.*Q//' -e 's/X.*//'`
  set DAY = `echo $yyyymmdd | sed -e 's/^.*X//'`

  set IMGROOT = /home/jsoc/hmi/hicadImages
  set IMGPATH = $IMGROOT/$YEAR/$MON/$DAY
  mkdir -p $IMGPATH
  cd $IMGPATH

  set img = 1
  while ($img <= $#obslist)
    set obs = $obslist[$img]
    set in_final = hmi.$obs'_45s'
    set in_nrt = hmi.$obs'_45s_nrt'
    set n_final = `$SHOW_INFO -cq $in_final"$QRY"`
    set n_nrt = `$SHOW_INFO -cq $in_nrt"$QRY"`
    set inseries = $in_nrt
    if ($n_final >= $n_nrt) then
      set inseries = $in_final
      set msg = ""
      set isNRT = 0
    else
      set inseries = $in_nrt
      set msg = "Quick-Look "
    endif
    echo Use $inseries for "$QRY"

set echo
    $RENDER_IMAGE n=0 $flaglist[$img] in=$inseries"$QRY" \
    pallette=$colorlist[$img] \
    min=$minlist[$img] \
    max=$maxlist[$img] \
    scaling=$scalinglist[$img] \
    scale=4 \
    outid=time \
    type=jpg \
    outname=$obs \
    out='| ppmlabel -color white -size {%0.75:5} -x 15 -y {%98} -text "SDO/HMI '"$msg$namelist[$img]"': {ID}" | pnmtojpeg -quality=95'
    set finalimagetime = `$SHOW_INFO -q $inseries"$QRY" n=-1 key=T_REC`
unset echo
    @ img = $img + 1
  end

  @ day = $day + 1
end

set exitstatus = 0

set echo
if ($finalimagetime != NONE) then
  set hhmmss = `echo $finalimagetime | sed -e 's/_TAI//' -e 's/.*_//' -e 's/://g'`
  set yyyymmdd = `echo $finalimagetime | sed -e 's/_.*//' -e 's/\./Q/' -e 's/\./X/'`
  set YEAR = `echo $yyyymmdd | sed -e 's/Q.*//'`
  set MON = `echo $yyyymmdd | sed -e 's/^.*Q//' -e 's/X.*//'`
  set DAY = `echo $yyyymmdd | sed -e 's/^.*X//'`
  set yyyymmdd = $YEAR$MON$DAY
  set LATESTLIST = $IMGROOT/hicadImage_times
  set prevd = 0
  set prevt = 0
  if (-e $LATESTLIST) then
    set prev = `grep Time $LATESTLIST`
    set prevdt = $prev[2]
    set prevd = `echo $prevdt | sed -e 's/_.*//'`
    set prevt = `echo $prevdt | sed -e 's/.*_//' | sed -e 's/^0//'`
  endif
  set hhmmss_test = `echo $hhmmss | sed -e 's/^0//'`
  if ( ($yyyymmdd > $prevd || ( $yyyymmdd == $prevd && $hhmmss_test > $prevt)) && (-e /home/jsoc/hmi/hicadImages/$YEAR/$MON/$DAY) ) then
      set imagepath = http://jsoc.stanford.edu/data/hmi/hicadImages/$YEAR/$MON/$DAY
      set latest = `ls -1t $IMGROOT/$YEAR/$MON/$DAY/*'_'1k.jpg | head -1 | awk -F\/ '{print $9}' | awk -F\_ '{print $1"_"$2}'`
#     set latest = $yyyymmdd'_'$hhmmss
      echo "Time    " $latest >  $LATESTLIST
      echo '{"first":"20100501_000000","last":"'$latest'"}' > $IMGROOT/hicadImage_times.json
      set img = 1
      while ($img <= $#obslist)
        set obs = $obslist[$img]
        set latest = `ls -1t $IMGROOT/$YEAR/$MON/$DAY/*$obs'_'1k.jpg | head -1 | awk -F\/ '{print $9}' | awk -F\_ '{print $1"_"$2}'`
        echo "$obs " $imagepath/$latest"_"$obs >> $LATESTLIST
        @ img = $img + 1
      end
  endif
endif

unset echo

#if ($end_movie_t > 0 && $isNRT ) then
#  set end_movie = `$TIME_CONVERT s=$end_movie_t zone=TAI`
#  /home/jsoc/cvs/Development/JSOC/proj/workflow/scripts/makeIcmovie $end_movie
#  set exitstatus = $?
#endif

exit $exitstatus
