#! /bin/csh -f

set DAY = $1

# get 0 TAI time for given day
set DAY_t = `time_convert time=$DAY`
@ DAY_t = $DAY_t / 86400
@ DAY_t = $DAY_t * 86400

# get offset start time of e.g. 3m30s = 210 secs TAI
@ GO_t = $DAY_t - 210
set GO = `time_convert s=$GO_t zone=TAI`

# get starting FSN assuming the begin of day is complete
set FFSN = `show_info key=FSN -q hmi.lev1'['$GO'/2s]'`

# get count in day by both time and FSN
set COUNT_FSN = `show_info -cq hmi.lev1'[]['$FFSN'/46080]'`
set COUNT_TIME = `show_info -cq hmi.lev1'['$GO'/1d]'`

# report results and return OK or not OK
echo -n "Day = $1, "
echo -n "Count by FSN = "$COUNT_FSN","
echo "Count by Time= " $COUNT_TIME

if ($COUNT_FSN == 46080 && $COUNT_TIME == 46080) then
  echo "OK to proceed with $1"
  exit 0
else
  echo "STOP, need to fix something for $1"
  exit 1
endif
