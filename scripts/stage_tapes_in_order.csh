#! /bin/csh -f
set echo

echo "Usage:  stage_tapes_in_order.csh <retention day number> '<dataseries>'" 

if ($?TMPDIR) then
  set WORKDIR = $TMPDIR/stagedata.$$
else
  set WORKDIR = /tmp/stagedata.$$
endif

set HERE = $cwd

mkdir $WORKDIR
cd $WORKDIR

#  The following section is copied from
#  /home/thailand/bin/make_show_info_retrieve.csh 
#  XXXXXXXXXXXXXXXXXXXXXXxxx
#! /bin/tcsh -f

if ( $#argv != 2 ) then
  echo "" 
  echo "Usage:  /home/thailand/bin/make_show_info_retrieve.csh <retention day number> '<dataseries>'" 
  echo "Example 1:  /home/thailand/bin/make_show_info_retrieve.csh 30 'dsds.mdi__lev1_8__fd_V_01h[105192-131136]'" 
  echo "Example 2:  /home/thailand/bin/make_show_info_retrieve.csh 60 'hmi.lev1[][12718378-12810537]'" 
  echo "" 
  cd $HERE; rm -rf $WORKDIR
  exit 1
endif

set RETENTION = "$argv[1]"
set DS = "$argv[2]"

set RETENTION_CHK = `echo "$RETENTION" | egrep -c "[a-zA-Z]"`

if ($RETENTION_CHK != 0) then
  echo "First field is retention time. Number only." 
  cd $HERE; rm -rf $WORKDIR
  exit 1
endif

set TMP = $WORKDIR/WORK
mkdir $TMP

set MAX_SUNUM = 64
set RETENTION = "DRMS_RETENTION=$RETENTION"
set DATE_STAMP = `date +%Y.%m.%d_%H_%M_%S`
set SERIES = `echo "$DS" | cut -f1 -d\[`

echo "Running show_info query on $DS to retrieve sunum, online status, tape_num, and filenum" 
echo "show_info -PTSroq $RETENTION "'"'"$DS"'"'" > $TMP/$SERIES.out.$DATE_STAMP" 
show_info -PTSroq $RETENTION "$DS" > $TMP/$SERIES.out.$DATE_STAMP

echo 

#grep'ing not for "Y" due to "N/A" in tape_id column for non-archived data
set NOT_ONLINE_CNT = `grep -c -v Y $TMP/$SERIES.out.$DATE_STAMP`
if ($NOT_ONLINE_CNT == 0) then
  echo "All files are on-line. Exiting" 
  cd $HERE; rm -rf $WORKDIR
  exit 0
else
  echo "$NOT_ONLINE_CNT segments to be retrieved" 
  echo  
endif

echo "Grep'ing for data not-online and sorting by tape_num, file_num, and sunum" 
echo "grep -v Y $TMP/$SERIES.out.$DATE_STAMP | sort -nk4 -nk5 -nk2  > $TMP/$SERIES.out.$DATE_STAMP.sorted" 
grep -v Y $TMP/$SERIES.out.$DATE_STAMP | sort -nk4 -nk5 -nk2 > $TMP/$SERIES.out.$DATE_STAMP.sorted

echo 

echo "Finding all unique tape numbers and generating uniqe list of sunums for each tape" 
foreach TAPE ( `awk '{print $4}' < $TMP/$SERIES.out.$DATE_STAMP.sorted | sort | uniq` )
  echo "Tape $TAPE" 
  echo "grep $TAPE $TMP/$SERIES.out.$DATE_STAMP.sorted | awk '{print "'$2'"}' | uniq > $TMP/$SERIES.$TAPE.$DATE_STAMP" 
  grep $TAPE $TMP/$SERIES.out.$DATE_STAMP.sorted | awk '{print $2}' | uniq > $TMP/$SERIES.$TAPE.$DATE_STAMP
  echo 
end

echo "Making show_info query script for sunum list of each tape" 
echo  

###Start of foreach subprocess loop to make show_info query script for each tape
foreach FILE ($TMP/$SERIES.*L4.$DATE_STAMP)
  set FILE = `basename $FILE`
  echo "Making do.$FILE.csh script" 


  @ i = 1
  @ j = 1

  set LENGTH = `wc -l $TMP/$FILE | awk '{print $1}'`

  echo "#! /bin/tcsh -f\n" > do.$FILE.csh 

  while ( $i <= $LENGTH )
    @ j = 1
    echo -n "show_info -p $RETENTION '""$SERIES"'[? SUNUM in (' > $TMP/tmpfile.$DATE_STAMP 

    while ( $j <= $MAX_SUNUM && $i <= $LENGTH)
      echo -n `sed -n "$i,$i p" $TMP/$FILE`"," >> $TMP/tmpfile.$DATE_STAMP
      @ i++
      @ j++
    end
    cat $TMP/tmpfile.$DATE_STAMP | sed 's/,$//' > $TMP/tmpfile2.$DATE_STAMP
    echo ") ?]'" >> $TMP/tmpfile2.$DATE_STAMP
  
    echo "date" >> do.$FILE.csh
    echo 'echo '$FILE >> do.$FILE.csh
    echo 'echo "'`cat $TMP/tmpfile2.$DATE_STAMP`'"' >> do.$FILE.csh
    cat $TMP/tmpfile2.$DATE_STAMP >> do.$FILE.csh
    echo "echo " >> do.$FILE.csh
  end
  echo "date" >> do.$FILE.csh
  chmod 777 do.$FILE.csh
  
  /bin/rm $TMP/tmpfile.$DATE_STAMP $TMP/tmpfile2.$DATE_STAMP
  
  echo "Finished making do.$FILE.csh script" 
  echo 
  
  ###End of foreach loop
end

# XXXXXXXXXXXXXXXXXXXXXXxxx

set ntapes = `/bin/ls | wc -l`
if ($ntapes == 0) then
  cd $HERE; rm -rf $WORKDIR
  exit 0
endif

foreach tapescript ( * )
  echo starting $tapescript
  csh $tapescript
  if ($?) then
    cd $HERE
    echo FAILED scripts at $WORKDIR
    exit 1
  endif
end

echo Done.

cd $HERE; rm -rf $WORKDIR
exit 0 
