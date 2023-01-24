#! /bin/csh -f

set dir = /tmp28/jsocprod/HARPS/nrt/images
rm -f $dir/tmp/*png $dir/tmp/*jpg

@ i = 1
foreach f ( `ls -1 $dir/harp*png | tail -120` )
  if ( $i < 10 ) then
    set n = 00$i
  else if ( $i < 100 ) then
    set n = 0$i
  else
    set n = $i
  endif
  cp $f $dir/tmp/$n.png
  @ i++
end
cd $dir/tmp
foreach p ( *png )
  mogrify -format jpg $p
end
ffmpeg -y -i $dir/tmp/%03d.jpg -b:v 35000k /tmp28/jsocprod/hmi/HARPs_movies/nrt/latest.mp4

set daily_dir = /tmp28/jsocprod/hmi/HARPs_movies/nrt
@ last_daily = `ls -1 $daily_dir/QL_HARPs* | tail -1 | cut -c47-50,52-53,55-56`
set hourly_dir = /tmp28/jsocprod/HARPS/nrt/images
@ last_hourly = `ls -1 $hourly_dir/harp.2* | tail -1 | cut -c39-42,44-45,47-48`
if ( $last_hourly - $last_daily == 2) then
  @ day = $last_hourly - 1 
  set day = `echo $day | sed 's/./&\./4' | sed 's/./&./7'`
  rm -f $dir/tmp2/*png $dir/tmp2/*jpg
  @ n = 1
  foreach d ( `ls -1 $dir/*$day*png` )
    if ( $n < 10 ) then
      set m = 0$n
    else
      set m = $n
    endif
    cp $d $dir/tmp2/$m.png
    @ n++
  end
  cd $dir/tmp2/
  foreach d2 ( *png )
    mogrify -format jpg $d2
  end
  ffmpeg -y -i $dir/tmp2/%02d.jpg -b:v 35000k /tmp28/jsocprod/hmi/HARPs_movies/nrt/QL_HARPs_$day.mp4
endif
  
  
