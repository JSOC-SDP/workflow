#! /bin/csh -f

#set echo
set noglob
set HERE = $cwd
set TEMPLOG = $HERE/runlog
echo 6 > $HERE/retstatus

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/show_info
set CUTOUT = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/m2meharp
set DISAMBIG = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/disambig_v3
set SHARP = /home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/sharp


foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

#set GATE = hmi.sharp
#set WANTLOW = 2012.12.01_TAI
#set WANTHIGH = 2012.12.02_TAI

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set timestr = `echo $WANTLOW | cut -c9-10,12-13`
set timename = SHP
set CMD = $HERE/SHP_$timestr
set qsubname = $timename$timestr

# Look for sharps to be processed

set times
set harps
set pix
@ num = `$SHOW_INFO -q hmi.Mharp_720s'[]['$WANTLOW'-'$WANTHIGH']' -c`
foreach i ( `$SHOW_INFO -q hmi.Mharp_720s'[]['$WANTLOW'-'$WANTHIGH']' key=t_rec` )
  set times = ($times $i)
end
foreach j ( `$SHOW_INFO -q hmi.Mharp_720s'[]['$WANTLOW'-'$WANTHIGH']' key=harpnum` )
  set harps = ($harps $j)
end
foreach k ( `$SHOW_INFO -q hmi.Mharp_720s'[]['$WANTLOW'-'$WANTHIGH']' key=npix` )
  set pix = ($pix $k)
end

@ goodData = 0
@ n = 1
while ( $n <= $num )
  if ( ($pix[$n] >= 2000) && ($pix[$n] <= 400000) ) then
    set trec = $times[$n]
    set harp = $harps[$n]
    @ sharpCount = `$SHOW_INFO -q hmi.sharp_720s'['$harp']['$trec']' -c`
    if ( $sharpCount == 0 ) then
      @ goodData = 1
    endif
  endif
  @ n++
end
 
# make qsub script if there's good data

if ( $goodData == 1 ) then

  echo "#! /bin/csh -f " >$CMD
  echo "cd $HERE" >>$CMD
  echo "hostname >>&$TEMPLOG" >>$CMD
  echo "set echo" >>$CMD

  echo "set M2Mstatus = 0" >>&$CMD
  echo "set DISstatus = 0" >>&$CMD
  echo "set SHPstatus = 0" >>&$CMD

  @ n = 1
  while ( $n <= $num )
    if ( ($pix[$n] >= 2000) && ($pix[$n] <= 400000) ) then
      set trec = $times[$n]
      set harp = $harps[$n]
      @ sharpCount = `$SHOW_INFO -q hmi.sharp_720s'['$harp']['$trec']' -c`
      if ( $sharpCount == 0 ) then
        echo "$CUTOUT mharp=hmi.Mharp_720s'['$harps[$n]']['$times[$n]']' me=hmi.ME_720s_fd10 meharp=hmi.MEHarp_720s" >> $CMD
        echo 'set M2Mstatus = $?' >>$CMD
        echo 'if ($M2Mstatus) goto DONE' >>&$CMD
        echo "date" >>$CMD
#        echo "$DISAMBIG in=hmi.MEHarp_720s'['$harps[$n]']['$times[$n]']' out=hmi.Bharp_720s AMBGMTRY=1 AMBNEQ=20 AMBTFCTR=0.99 OFFSET=20" >>$CMD
        echo "$DISAMBIG in=hmi.MEHarp_720s'['$harps[$n]']['$times[$n]']' out=hmi.Bharp_720s AMBGMTRY=0 AMBNEQ=100 AMBTFCTR=0.98 OFFSET=20 AMBNPAD=500" >>$CMD
        echo "date" >>$CMD
        echo 'set DISstatus = $?' >>$CMD
        echo 'if ($DISstatus) goto DONE' >>&$CMD
        echo "$SHARP mharp=hmi.Mharp_720s'['$harps[$n]']['$times[$n]']' bharp=hmi.Bharp_720s'['$harps[$n]']['$times[$n]']' \\
         dop=hmi.V_720s'['$times[$n]']' cont=hmi.Ic_720s'['$times[$n]']' \\
         sharp_cea=hmi.sharp_cea_720s sharp_cut=hmi.sharp_720s" >>$CMD
        echo 'set SHPstatus = $?' >>$CMD
        echo 'if ($SHPstatus) goto DONE' >>&$CMD
    
      else
        echo "sharp exists:  $harp $trec" >>&$TEMPLOG
      endif
    else
      echo "hmi.Mharp_720s'['$harps[$n]']['$times[$n] not processed because npix = $pix[$n]" >>&$TEMPLOG
    endif
    @ n++
  end
  echo 'DONE:' >>$CMD
  echo 'echo $M2Mstatus >M2Mstatus' >>&$CMD
  echo 'echo $DISstatus >DISstatus' >>&$CMD
  echo 'echo $SHPstatus >SHPstatus' >>&$CMD
  echo '@ retstatus = $M2Mstatus + $DISstatus + $SHPstatus' >>$CMD
  echo 'echo $retstatus >retstatus' >>$CMD
  echo "rm -f $HERE/qsub_running" >>$CMD


# execute qsub script

  set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
  qsub -sync yes -l h_rt=900:00:00 -e $TEMPLOG -o $TEMPLOG -q j.q $CMD >> runlog
#  /SGE/bin/lx24-amd64/qsub2 -sync yes -l h_rt=900:00:00 -e $TEMPLOG -o $TEMPLOG -q a.q $CMD >> runlog
else
  touch $HERE/NoGoodData
  exit 0
endif

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus

