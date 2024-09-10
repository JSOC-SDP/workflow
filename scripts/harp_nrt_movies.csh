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
set hourly_dir = /tmp28/jsocprod/HARPS/nrt/images
set last_hourly = `ls -1 $hourly_dir/harp.2* | tail -1 | cut -c39-42,44-45,47-48`

set days = ()
foreach check_D ( `ls -1 $hourly_dir/harp.2* | cut -c39-42,44-45,47-48 | sort -u` )
  set file = $daily_dir/QL_HARPs_`echo $check_D | sed 's/./&\./4' | sed 's/./&./7'`.mp4
  if ( ! -e $file ) then
    set days = ( $days $check_D )
  endif
end
set days = ( $days $last_hourly )

foreach D ( $days )
  set day = `echo $D | sed 's/./&\./4' | sed 's/./&./7'`
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
end 
  
