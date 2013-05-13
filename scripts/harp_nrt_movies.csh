#! /bin/csh -f

setenv TMPDIR /surge40/jsocprod/HARPS/nrt

rm -f /surge40/jsocprod/HARPS/nrt/tmp/*

foreach i ( `ls -1 /surge40/jsocprod/HARPS/nrt/Tracks/movie/ | tail -120` )
   cp /surge40/jsocprod/HARPS/nrt/Tracks/movie/$i /surge40/jsocprod/HARPS/nrt/tmp/ 
end  


/home/turmon/cat_movie.sh -n 120 -F "-r 24 -qscale 5" -o /scr21/jsoc/hmi/HARPs_movies/nrt/latest.mp4 /surge40/jsocprod/HARPS/nrt/tmp/*.mp4

unsetenv TMPDIR
