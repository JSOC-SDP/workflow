#! /bin/csh -f

# Generate HMI daily products for all days from wantlow to wanthigh,
# one day at a time from standard TAI offsets.
# make a ticket for the first day after wanthigh to be run next.

set WFDIR = $WORKFLOW_DATA
set WFCODE = $WORKFLOW_ROOT

# Note that start/stop minute are hour 23 minute 54 for LOS and 24 for vector.
@ LOS_offset = 6 * 60
@ Vector_offset = 36 * 60
@ lev1_offset = 180

set WANTLOW = `cat wantlow`
set WANTHIGH = `cat wanthigh`

set WANTLOW_t = `time_convert time=$WANTLOW`
set WANTHIGH_t = `time_convert time=$WANTHIGH`

@ WANTLOW_DAY_D = $WANTLOW_t / 86400
# now WANTLOW_D is TAI of day  containing WANTLOW

@ WANTHIGH_DAY_D = $WANTHIGH_t / 86400
# now WANTHIGH_D is TAI of day  containing WANTHIGH


@ WANTNEXTLOW_D = $WANTHIGH_D + 1
@ WANTNEXTLOW_T = $WANTNEXTLOW_D * 86400
@ WANTNEXTHIGH_T = $WANTNEXTLOW_T + 86400
@ WANTNEXTHIGH_T = $WANTNEXTHIGH_T - $LOS_offset
@ WANTNEXTHIGH_T = $WANTNEXTHIGH_T + $lev1_offset
set WANTNEXTLOW = `time_convert zone=TAI s=$WANTNEXTLOW_T`  # 0 TAI of next day
set WANTNEXTHIGH = `time_convert zone=TAI s=$WANTNEXTHIGH_T` # just before end of next day

# This ticket will wait for this gate precondition of lev1 and cosmic_rays done at least to the bounding times
$WFCODE/maketicket.csh gate=repeat_hmi_daily wantlow=$WANTNEXTLOW wanthigh=$WANTNEXTHIGH action=5

# First get taskid of the current instance, it is the name of the current directory
set TASKID = $cwd:t

set WORKDAY_D = $WANTLOW_DAY_D
while ($WORKDAY_D <= $WANTHIGH_D)
  @ WORKDAY_T = $WORKDAY_D * 86400
  set WORKDAY = `time_convert zone=TAI s=$WORKDAY_T`
  echo Start day $WORKDAY

  # base high
  @ LOSLOW_T = $WORKDAY_T - $LOS_offset
  @ LOSHIGH_T = $LOSLOW_T + 86400
  @ IMGHIGH_T = $LOSHIGH_T - 45
  @ VECLOW_T = $WORKDAY_T - $VEC_offset
  @ VECHIGH_T = $VECLOW_T + 86400
  
  set LOWLOW = `time_convert zone=TAI s=$LOSLOW_T`
  set LOWHIGH = `time_convert zone=TAI s=$LOSHIGH_T`
  set IMGHIGH = `time_convert zone=TAI s=$IMGHIGH_T`
  set VECLOW = `time_convert zone=TAI s=$VECLOW_T`
  set VECHIGH = `time_convert zone=TAI s=$VECHIGH_T`

  # now make tickets to compute the desired products for this day
  set LOSARGS = "gate=hmi.LOS       taskid=$TASKID wantlow=$LOSLOW wanthigh=$LOWHIGH action=5"
  set IMGARGS = "gate=hmi.webImages taskid=$TASKID wantlow=$LOSLOW wanthigh=$IMGWIGH action=5"
  set VECARGS = "gate=hmi.Vector    taskid=$TASKID wantlow=$VECLOW wanthigh=$VECHIGH action=5"

  set LOS_TICKET = `$WFCODE/maketicket.csh $LOSARGS `
  set VEC_TICKET = `$WFCODE/maketicket.csh $VECARGS `
  set IMG_TICKET = `$WFCODE/maketicket.csh $IMGARGS `

  cd pending_tickets
  while ((-e $LOS_TICKET || -e $IMG_TICKET || -e $LOS_TICKET))
     echo -n '.'
     sleep 3600
  end

@ WORKDAY_D = $WORKDAY_D + 1
end

exit 0
