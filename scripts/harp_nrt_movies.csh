#! /bin/csh -f

setenv TMPDIR /tmp28/jsocprod/HARPS/nrt

rm -f /tmp28/jsocprod/HARPS/nrt/tmp/*

foreach i ( `ls -1 /tmp28/jsocprod/HARPS/nrt/Tracks/movie/ | tail -120` )
   cp /tmp28/jsocprod/HARPS/nrt/Tracks/movie/$i /tmp28/jsocprod/HARPS/nrt/tmp/ 
end  

if ( $JSOC_MACHINE == "linux_avx" ) then
  /home/turmon/cat_movie.sh -n 120 -F "-r 24 -c mpeg4 -qscale 5" -o /tmp28/jsocprod/hmi/HARPs_movies/nrt/latest.mp4 /tmp28/jsocprod/HARPS/nrt/tmp/*.mp4
else
  /home/turmon/cat_movie.sh -n 120 -F "-r 24 -qscale 5" -o /tmp28/jsocprod/hmi/HARPs_movies/nrt/latest.mp4 /tmp28/jsocprod/HARPS/nrt/tmp/*.mp4
endif

unsetenv TMPDIR
