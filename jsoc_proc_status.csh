#! /bin/csh -f

# set echo

@ fourdays = 4 * 1440
@ fivedays = 5 * 1440
@ sixdays = 6 * 1440
@ oneweek = 7 * 1440

set hproduct = (lev1_nrt V_45s_nrt V_720s_nrt lev1 cosmic_rays V_45s V_720s)
set product = (lev0 $hproduct)
set green =  ( 2  5  30  48 $fourdays $fourdays $fivedays $fivedays)
set yellow = ( 4 10  60  80 $fivedays $fivedays $sixdays $sixdays)
set red =    ( 8 20 120 150 $sixdays  $sixdays  $oneweek $oneweek) 

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set now_t = `time_convert time=$now`

set nprod = $#product
set iprod = 1
while ($iprod <= $nprod)
  set prod = $product[$iprod]
  if ($prod == lev0)  then
    set times = `show_info key=T_OBS -q hmi.lev0a'[? FSN < 200000000 ?]' n=-1`
  else
    set times = `show_info -q key=T_OBS hmi.$prod'[$]'`
  endif
  set times_t = `time_convert time=$times`
  @  lags = ( $now_t - $times_t ) / 60
  if ($lags <= $green[$iprod]) then
    set stat = GREEN
  else if ($lags <= $yellow[$iprod]) then
    set stat = YELLOW
  else
    set stat = RED
  endif
  if ($lags < 60) then
    set lag = $lags" minutes"
  else if ($lags < 1440) then
    set hours = `arith $lags / 60`
    set lag = $hours" hours"
  else
    set days = `arith $lags / 1440`
    set lag = $days" days"
  endif
  echo "`printf %-12s $prod`" "`printf %7s $stat`" '  ' $lag
  @ iprod = $iprod + 1
end


