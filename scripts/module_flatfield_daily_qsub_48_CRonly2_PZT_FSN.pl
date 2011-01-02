# modified from module_flatfield_daily_qsub_48_CRonly2_PZT_FSN.pl

#This version uses cosmic_rays=1 flatfield=0 per Richard's
#mail: Re: missing cosmic rays 11/15/2010 11:09
#
$QDIR = $cwd ; #dir for qsub scripts

$date = `date -u +%Y.%m.%d_%H:%M:%S`;

cat > $QSUBCMD <<END
#
# 45s, camera=2
set FIDLIST_1 = (10058 10059 10078 10079 10098 10099 10118 10119 10138 10139 10158 10159)
# 135, camera=1
set FIDLIST_2 = (10054 10055 10056 10057 10058 10059 10074 10075 10076 10077 10078 10079 \
                 10094 10095 10096 10097 10098 10099 10114 10115 10116 10117 10118 10119 \
                 10134 10135 10136 10137 10138 10139 10154 10155 10156 10157 10158 10159) 

set ID = \$SGE_TASK_ID
if (\$ID <= 12) then
   set ID1 = \$ID
   set cadence = "45s"
   set camera = 2
   set fid = FIDLIST_1\[\$ID]
else
   @ ID2 = \$ID - 12
   set cadence = "45s"
   set camera = 2
   set fid = FIDLIST_2\[\$ID]
endif

$module_flatfield input_series=hmi.lev1 cadence=\$cadence cosmic_rays=1 flatfield=0 fid=\$fid camera=\$camera fsn_first=$firstfsn fsn_last=$lastfsn datum"'"=$datum"'" >>& $LOG.\$ID
END

qsub -q j.q,0.q -o $LOG -e $LOG -t 48 -sync yes $QSUBCMD

