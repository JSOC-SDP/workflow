# /bin/csh -f

set WFCODE = $WORKFLOW_ROOT

# get the current wanthigh
set HIGH = `cat wanthigh`
set HIGH_t = `time_convert time=$HIGH`
# add 5 seconds for next wanthigh
@ WANT_t = $HIGH_t + 5
set WANT = `time_convert s=$WANT_t`
# issue ticket for the next run
$WFCODE/maketicket.csh gate=xclock_gate wantlow=$HIGH wanthigh=$WANT action=5
# do this time
(xclock &; sleep 2; kill %1)
exit 0
