#! /bin/csh -f

set echo
set noglob
set HERE = $cwd
set TEMPLOG = $HERE/runlog
set CMD = $HERE/SHP_nrt
echo 6 > $HERE/retstatus

if ( $JSOC_MACHINE == "linux_x86_64" ) then
  set QUE = p.q,j.q
  set QSUB = qsub
else if ( $JSOC_MACHINE == "linux_avx" ) then
  set QUE = a.q,b.q
  set QSUB = qsub2
endif

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT
set SHOW_INFO = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_info
set CUTOUT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/m2meharp
#set DISAMBIG = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/disambig
set DISAMBIG = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/disambig_v3
set SHARP = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/sharp


foreach ATTR (WANTLOW WANTHIGH GATE)
   set ATTRTXT = `grep $ATTR ticket`
   set $ATTRTXT
end

set product = `cat $WFDIR/gates/$GATE/product`
set key = `cat $WFDIR/gates/$GATE/key`

set timestr = `echo $WANTLOW  | sed -e 's/[.:]//g' -e 's/^......//' -e 's/.._TAI//'`
set timename = SHP_nrt
set qsubname = $timename$timestr

# Look for harps to be processed

set times
set harps
set pix
set num = `$SHOW_INFO -q hmi.Mharp_720s_nrt'[]['$WANTLOW'-'$WANTHIGH']' -c`
foreach i ( `$SHOW_INFO -q hmi.Mharp_720s_nrt'[]['$WANTLOW'-'$WANTHIGH']' key=t_rec` )
  set times = ($times $i)
end
foreach j ( `$SHOW_INFO -q hmi.Mharp_720s_nrt'[]['$WANTLOW'-'$WANTHIGH']' key=harpnum` )
  set harps = ($harps $j)
end
foreach k ( `$SHOW_INFO -q hmi.Mharp_720s_nrt'[]['$WANTLOW'-'$WANTHIGH']' key=npix` )
  set pix = ($pix $k)
end

# make qsub script

echo "#! /bin/csh -f " >$CMD
echo "cd $HERE" >>$CMD
echo "hostname >>&$TEMPLOG" >>$CMD
echo "set echo" >>$CMD

echo "set M2Mstatus = 0" >>&$CMD
echo "set DISstatus = 0" >>&$CMD
echo "set SHPstatus = 0" >>&$CMD

set n = 1
while ( $n <= $num )
#  if ( ($pix[$n] >= 2000) && ($pix[$n] <= 400000) ) then    ### Removed high pixel restriction on 2013.09.04
  if ( $pix[$n] >= 2000 ) then
    echo "$CUTOUT mharp=hmi.Mharp_720s_nrt'['$harps[$n]']['$times[$n]']' me=hmi.ME_720s_fd10_nrt meharp=hmi.MEharp_720s_nrt" >> $CMD
    echo 'set M2Mstatus = $?' >>$CMD
    echo 'if ($M2Mstatus) goto DONE' >>&$CMD
#    echo "$DISAMBIG in=hmi.MEharp_720s_nrt'['$harps[$n]']['$times[$n]']' out=hmi.Bharp_720s_nrt AMBGMTRY=1 AMBNEQ=20 -l" >>$CMD
    echo "$DISAMBIG in=hmi.MEharp_720s_nrt'['$harps[$n]']['$times[$n]']' out=hmi.Bharp_720s_nrt AMBGMTRY=1 AMBNEQ=20 AMBTFCTR=0.99 OFFSET=20" AMBNPAD=50 >>$CMD
    echo 'set DISstatus = $?' >>$CMD
    echo 'if ($DISstatus) goto DONE' >>&$CMD
    echo "$SHARP mharp=hmi.Mharp_720s_nrt'['$harps[$n]']['$times[$n]']' bharp=hmi.Bharp_720s_nrt'['$harps[$n]']['$times[$n]']' \\
     dop=hmi.V_720s_nrt'['$times[$n]']' cont=hmi.Ic_720s_nrt'['$times[$n]']' \\
     sharp_cea=hmi.sharp_cea_720s_nrt sharp_cut=hmi.sharp_720s_nrt" >>$CMD
    echo 'set SHPstatus = $?' >>$CMD
    echo 'if ($SHPstatus) goto DONE' >>&$CMD
    
    echo 'DONE:' >>$CMD
    echo 'echo $M2Mstatus >M2Mstatus' >>&$CMD
    echo 'echo $DISstatus >DISstatus' >>&$CMD
    echo 'echo $SHPstatus >SHPstatus' >>&$CMD
    echo '@ retstatus = $M2Mstatus + $DISstatus + $SHPstatus' >>$CMD
   echo '@ retstatus = $M2Mstatus + $DISstatus' >>$CMD
    echo 'echo $retstatus >retstatus' >>$CMD
  else
    echo "hmi.Mharp_720s'['$harps[$n]']['$times[$n] not processed because npix = $pix[$n]"
  endif
  @ n++
end
#echo 'echo $retstatus >retstatus' >>$CMD
#echo "rm -f $HERE/qsub_running" >>$CMD


# execute qsub script

set TEMPLOG = `echo $TEMPLOG | sed "s/^\/auto//"`
$QSUB -sync yes -e $TEMPLOG -o $TEMPLOG -q $QUE $CMD >> runlog

if (-e retstatus) set retstatus = `cat $HERE/retstatus`
exit $retstatus

